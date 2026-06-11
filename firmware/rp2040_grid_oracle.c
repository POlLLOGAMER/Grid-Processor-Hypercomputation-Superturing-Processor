/*
 * =============================================================================
 * Grid Processor Oracle - RP2040 Firmware
 *
 * Implements:
 *   1. LOAD -> TRIGGER -> WAIT -> READ -> IRQ protocol
 *   2. Statistical thermal noise filtering (EMA + averaging)
 *   3. Shannon entropy analysis for result validation
 *   4. I2C SSD1306 OLED display output
 *   5. User interface (buttons + LEDs)
 * =============================================================================
 */

#include <stdio.h>
#include <string.h>
#include <math.h>
#include "pico/stdlib.h"
#include "hardware/spi.h"
#include "hardware/i2c.h"
#include "hardware/gpio.h"
#include "hardware/clocks.h"

/* ================================================================
 * PIN ASSIGNMENTS
 * ================================================================ */

/* SPI to Grid Processor (via level shifters) */
#define PIN_SPI_CLK    2   /* SCK  - grid clock */
#define PIN_SPI_TX     4   /* MOSI - data TO grid   */
#define PIN_SPI_RX     5   /* MISO - data FROM grid */
#define PIN_SPI_CS     6   /* CSn  - chip select    */

/* Control lines */
#define PIN_TRIGGER    7   /* Assert to start computation */
#define PIN_IRQ        8   /* Grid interrupt request      */
#define PIN_READY      9   /* Grid ready / converged      */
#define PIN_SELECT     10  /* Page select for result mux  */
#define PIN_RST_N      3   /* Active-low reset to grid    */

/* User interface */
#define BTN_TRIGGER    20
#define BTN_RESET      21
#define LED_COMPUTE    22
#define LED_READY      23
#define LED_IRQ        24
#define LED_ERROR      25

/* I2C OLED */
#define OLED_SDA       16
#define OLED_SCL       17
#define OLED_ADDR      0x3C

/* ================================================================
 * Constants (mirror config.yaml)
 * ================================================================ */
#define GRID_CELLS      64
#define AVG_WINDOW      16
#define MAX_ITERATIONS  4096
#define CONVERGE_THRESH 3
#define SHANNON_BINS    16
#define ENTROPY_MIN     2.0f
#define EMA_ALPHA_NUM   1
#define EMA_ALPHA_DEN   8
#define TIMEOUT_MS      5000

/* ================================================================
 * Data types
 * ================================================================ */
typedef struct {
    uint8_t projection[8];   /* 64-bit collapsed result */
    uint32_t grid_state;
    uint8_t  convergence;
    uint32_t iterations;
    uint8_t  status;
} grid_result_t;

typedef enum {
    ST_IDLE, ST_LOADING, ST_TRIGGERED, ST_WAITING,
    ST_READING, ST_PROCESSING, ST_DONE, ST_ERROR
} proc_state_t;

static volatile proc_state_t g_state = ST_IDLE;

/* ================================================================
 * OLED helper functions (SSD1306, I2C)
 * ================================================================ */
static void oled_cmd(uint8_t cmd) {
    uint8_t buf[2] = {0x00, cmd};
    i2c_write_blocking(i2c0, OLED_ADDR, buf, 2, false);
}

static void oled_data(const uint8_t *d, size_t n) {
    uint8_t hdr = 0x40;
    i2c_write_blocking(i2c0, OLED_ADDR, &hdr, 1, true);
    i2c_write_blocking(i2c0, OLED_ADDR, (uint8_t *)d, n, false);
}

static void oled_init(void) {
    uint8_t cmds[] = {
        0xAE, 0xD5, 0x80, 0xA8, 0x3F, 0xD3, 0x00, 0x40,
        0x8D, 0x14, 0x20, 0x00, 0xA1, 0xC8, 0xDA, 0x12,
        0x81, 0xCF, 0xD9, 0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF
    };
    for (size_t i = 0; i < sizeof(cmds); i++) oled_cmd(cmds[i]);
}

static void oled_clear(void) {
    oled_cmd(0x21); oled_cmd(0x00); oled_cmd(0x7F);
    oled_cmd(0x22); oled_cmd(0x00); oled_cmd(0x07);
    uint8_t blank[128] = {0};
    for (int p = 0; p < 8; p++) oled_data(blank, 128);
}

static void oled_text(const char *s, int line) {
    oled_cmd(0x21); oled_cmd(0x00); oled_cmd(0x7F);
    oled_cmd(0x22); oled_cmd(line); oled_cmd(line);
    /* Simplified: each char = 5 columns of 0xFF */
    uint8_t buf[128]; memset(buf, 0, sizeof(buf));
    int x = 0;
    while (*s && x < 128) {
        for (int i = 0; i < 5 && x < 128; i++) buf[x++] = 0xFF;
        if (x < 128) buf[x++] = 0x00;
        s++;
    }
    oled_data(buf, 128);
}

/* ================================================================
 * SPI communication with grid
 * ================================================================ */
static void spi_cs(int level) { gpio_put(PIN_SPI_CS, level); }

static uint8_t spi_xfer(uint8_t b) {
    uint8_t rx;
    spi_write_read_blocking(spi0, &b, &rx, 1);
    return rx;
}

/* ================================================================
 * Protocol: Load -> Trigger -> Wait -> Read
 * ================================================================ */
static void grid_load(const uint8_t seed[8]) {
    g_state = ST_LOADING;
    gpio_put(LED_COMPUTE, 1);
    spi_cs(0);
    for (int i = 0; i < 8; i++) spi_xfer(seed[i]);
    spi_cs(1);
    busy_wait_us(100);
}

static void grid_trigger(void) {
    g_state = ST_TRIGGERED;
    gpio_put(PIN_TRIGGER, 1);
    busy_wait_us(10);
    gpio_put(PIN_TRIGGER, 0);
}

static bool grid_wait_ready(uint32_t ms) {
    g_state = ST_WAITING;
    gpio_put(LED_COMPUTE, 1);
    absolute_time_t t0 = get_absolute_time();
    while (!time_reached_us(t0, ms * 1000)) {
        if (gpio_get(PIN_READY)) {
            gpio_put(LED_READY, 1);
            g_state = ST_READING;
            return true;
        }
        busy_wait_us(50);
    }
    g_state = ST_ERROR;
    gpio_put(LED_ERROR, 1);
    return false;
}

static void grid_read(grid_result_t *r) {
    gpio_put(PIN_SELECT, 0);
    busy_wait_us(10);
    spi_cs(0);
    for (int i = 0; i < 8; i++) r->projection[i] = spi_xfer(0xFF);
    spi_cs(1);

    gpio_put(PIN_SELECT, 1);
    busy_wait_us(10);
    spi_cs(0);
    spi_xfer(0xFF);  /* dummy */
    r->grid_state  = (uint32_t)spi_xfer(0xFF) << 24;
    r->grid_state |= (uint32_t)spi_xfer(0xFF) << 16;
    r->grid_state |= (uint32_t)spi_xfer(0xFF) <<  8;
    r->grid_state |= (uint32_t)spi_xfer(0xFF);
    r->convergence = spi_xfer(0xFF);
    r->status      = spi_xfer(0xFF);
    spi_cs(1);
    g_state = ST_PROCESSING;
}

/* ================================================================
 * Thermal noise filtering
 * ================================================================ */
static uint8_t ema_filter(uint8_t sample, uint8_t prev) {
    return (EMA_ALPHA_NUM * sample + (EMA_ALPHA_DEN - EMA_ALPHA_NUM) * prev) / EMA_ALPHA_DEN;
}

static uint8_t moving_avg(const uint8_t *buf, int n) {
    uint32_t s = 0;
    for (int i = 0; i < n; i++) s += buf[i];
    return (s + n/2) / n;
}

/* ================================================================
 * Shannon entropy analysis
 * ================================================================ */
static float shannon_entropy(const uint8_t *data, size_t len) {
    uint16_t hist[SHANNON_BINS]; memset(hist, 0, sizeof(hist));
    size_t total = 0;
    for (size_t i = 0; i < len; i++) {
        hist[data[i] & 0x0F]++;
        hist[(data[i] >> 4) & 0x0F]++;
        total += 2;
    }
    float H = 0;
    for (int i = 0; i < SHANNON_BINS; i++) {
        if (hist[i] > 0) {
            float p = (float)hist[i] / total;
            H -= p * log2f(p);
        }
    }
    return H;
}

/* ================================================================
 * IRQ handler
 * ================================================================ */
void __isr irq_handler(uint gpio, uint32_t events) {
    if (gpio == PIN_IRQ && (events & GPIO_IRQ_EDGE_RISE)) {
        gpio_put(LED_IRQ, 1);
        busy_wait_us(1);
        gpio_put(LED_IRQ, 0);
    }
}

/* ================================================================
 * Button handler
 * ================================================================ */
void __isr btn_handler(uint gpio, uint32_t events) {
    if (gpio == BTN_TRIGGER && (events & GPIO_IRQ_EDGE_FALL)) {
        if (g_state == ST_IDLE) grid_trigger();
    } else if (gpio == BTN_RESET && (events & GPIO_IRQ_EDGE_FALL)) {
        g_state = ST_IDLE;
        gpio_put(LED_COMPUTE, 0);
        gpio_put(LED_READY, 0);
        gpio_put(LED_IRQ, 0);
        gpio_put(LED_ERROR, 0);
        oled_clear();
    }
}

/* ================================================================
 * Main
 * ================================================================ */
int main(void) {
    stdio_init_all();
    set_sys_clock_khz(125000, true);

    /* GPIO setup */
    gpio_init(PIN_RST_N); gpio_set_dir(PIN_RST_N, GPIO_OUT); gpio_put(PIN_RST_N, 0);
    gpio_init(PIN_TRIGGER); gpio_set_dir(PIN_TRIGGER, GPIO_OUT); gpio_put(PIN_TRIGGER, 0);
    gpio_init(PIN_SELECT); gpio_set_dir(PIN_SELECT, GPIO_OUT); gpio_put(PIN_SELECT, 0);
    gpio_init(PIN_IRQ); gpio_set_dir(PIN_IRQ, GPIO_IN); gpio_pull_down(PIN_IRQ);
    gpio_init(PIN_READY); gpio_set_dir(PIN_READY, GPIO_IN); gpio_pull_down(PIN_READY);
    gpio_init(BTN_TRIGGER); gpio_set_dir(BTN_TRIGGER, GPIO_IN); gpio_pull_up(BTN_TRIGGER);
    gpio_init(BTN_RESET); gpio_set_dir(BTN_RESET, GPIO_IN); gpio_pull_up(BTN_RESET);
    for (int p = LED_COMPUTE; p <= LED_ERROR; p++) { gpio_init(p); gpio_set_dir(p, GPIO_OUT); gpio_put(p, 0); }

    /* Interrupts */
    gpio_set_irq_enabled_with_callback(BTN_TRIGGER, GPIO_IRQ_EDGE_FALL, true, btn_handler);
    gpio_set_irq_enabled(PIN_IRQ, GPIO_IRQ_EDGE_RISE, true);
    irq_set_exclusive_handler(GPIO_IRQ_SIO, irq_handler);
    irq_set_enabled(GPIO_IRQ_SIO, true);

    /* I2C + OLED */
    i2c_init(i2c0, 400000);
    gpio_set_function(OLED_SDA, GPIO_FUNC_I2C);
    gpio_set_function(OLED_SCL, GPIO_FUNC_I2C);
    gpio_pull_up(OLED_SDA); gpio_pull_up(OLED_SCL);
    oled_init(); oled_clear();
    oled_text("GRID ORACLE v1.0", 0);
    oled_text("Init...", 2);

    /* SPI */
    spi_init(spi0, 1000000);
    gpio_set_function(PIN_SPI_CLK, GPIO_FUNC_SPI);
    gpio_set_function(PIN_SPI_TX,  GPIO_FUNC_SPI);
    gpio_set_function(PIN_SPI_RX,  GPIO_FUNC_SPI);
    gpio_init(PIN_SPI_CS); gpio_set_dir(PIN_SPI_CS, GPIO_OUT); gpio_put(PIN_SPI_CS, 1);

    /* Release grid from reset */
    gpio_put(PIN_RST_N, 1);
    sleep_ms(100);
    oled_text("System Ready", 2);

    /* Run loop */
    grid_result_t result;
    uint8_t seed[8];

    while (1) {
        switch (g_state) {
        case ST_IDLE:
            if (!gpio_get(BTN_TRIGGER)) {
                for (int i = 0; i < 8; i++) seed[i] = (uint8_t)rand();
                grid_load(seed);
            }
            break;
        case ST_LOADING:
            grid_trigger();
            break;
        case ST_TRIGGERED:
            if (!grid_wait_ready(TIMEOUT_MS)) {
                oled_text("TIMEOUT", 4);
            }
            break;
        case ST_WAITING:
            /* handled in grid_wait_ready() */
            break;
        case ST_READING:
            grid_read(&result);
            break;
        case ST_PROCESSING: {
            uint8_t samples[AVG_WINDOW];
            for (int i = 0; i < AVG_WINDOW; i++) {
                grid_read(&result);
                samples[i] = result.projection[0];
                busy_wait_us(50);
            }
            for (int i = 0; i < 8; i++)
                result.projection[i] = moving_avg(samples, AVG_WINDOW);

            float H = shannon_entropy(result.projection, 8);
            if (H >= ENTROPY_MIN) { g_state = ST_DONE; }
            else { oled_text("LOW ENTROPY", 4); g_state = ST_ERROR; }
            break;
        }
        case ST_DONE:
            oled_clear();
            oled_text("RESULT:", 0);
            char hex[33] = {0};
            for (int i = 0; i < 8; i++) sprintf(hex + i*2, "%02X", result.projection[i]);
            oled_text(hex, 2);
            char hbuf[16];
            snprintf(hbuf, sizeof(hbuf), "H=%.2f", shannon_entropy(result.projection, 8));
            oled_text(hbuf, 4);
            char ibuf[16];
            snprintf(ibuf, sizeof(ibuf), "iter=%lu", result.iterations);
            oled_text(ibuf, 6);
            gpio_put(LED_READY, 0);
            gpio_put(LED_COMPUTE, 0);
            g_state = ST_IDLE;
            break;
        case ST_ERROR:
            oled_text("ERROR", 4);
            gpio_put(LED_ERROR, 1);
            sleep_ms(2000);
            gpio_put(LED_ERROR, 0);
            g_state = ST_IDLE;
            break;
        }
        sleep_ms(1);
    }
    return 0;
}

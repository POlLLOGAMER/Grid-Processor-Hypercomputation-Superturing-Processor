cmake_minimum_required(VERSION 3.13)

include($ENV{PICO_SDK_PATH}/external/pico_sdk_import.cmake)

project(grid_oracle_firmware C CXX ASM)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

pico_sdk_init()

add_executable(grid_oracle_firmware
    rp2040_grid_oracle.c
)

target_link_libraries(grid_oracle_firmware
    pico_stdlib
    hardware_spi
    hardware_i2c
    hardware_gpio
    hardware_clocks
)

pico_enable_stdio_usb(grid_oracle_firmware 1)
pico_enable_stdio_uart(grid_oracle_firmware 0)

pico_add_extra_outputs(grid_oracle_firmware)

target_compile_definitions(grid_oracle_firmware PRIVATE
    PICO_DEFAULT_I2C=0
    PICO_DEFAULT_I2C_SDA_PIN=16
    PICO_DEFAULT_I2C_SCL_PIN=17
    PICO_DEFAULT_SPI=0
    PICO_DEFAULT_SPI_SCK_PIN=2
    PICO_DEFAULT_SPI_TX_PIN=4
    PICO_DEFAULT_SPI_RX_PIN=5
)

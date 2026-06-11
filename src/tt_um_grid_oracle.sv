// =============================================================================
// Grid Processor - Top Level Entity
// TinyTapeout 7 Standard Interface  (FIXED)
// SkyWater 130nm Technology
//
// Pin mapping:
//   ui_in[7:0]  -> Grid seed bits [7:0]
//   uo_out[7:0] -> Result page (LSB page or convergence page)
//   uio_in[0]   -> TRIGGER  (starts computation)
//   uio_in[1]   -> SELECT   (0=result_lsb, 1=convergence page)
//   uio_out[0]  -> IRQ      (pulse when result ready)
//   uio_out[1]  -> READY    (high when converged)
//   uio_oe      -> 8'b00000011 (uio[0] y uio[1] como salidas)
//   clk         -> system clock (TT standard)
//   rst_n       -> active-low reset (TT standard)
//   ena         -> design enable (TT standard, unused internally)
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module tt_um_grid_oracle (
    input  wire [7:0] ui_in,    // Dedicated inputs  : grid seed [7:0]
    output wire [7:0] uo_out,   // Dedicated outputs : result page [7:0]
    input  wire [7:0] uio_in,   // Bidirectional in  : [0]=TRIGGER [1]=SELECT
    output wire [7:0] uio_out,  // Bidirectional out : [0]=IRQ     [1]=READY
    output wire [7:0] uio_oe,   // Bidirectional OE  : 1=output 0=input
    input  wire       ena,      // Always 1 when powered (TT standard)
    input  wire       clk,      // System clock
    input  wire       rst_n     // Active-low reset
);

    // =========================================================================
    // Internal signals
    // =========================================================================
    wire        trigger;
    wire        select_page;
    wire        irq_out;
    wire        ready_out;
    wire [7:0]  result_lsb;
    wire [7:0]  result_msb;
    wire [3:0]  grid_convergence_flag;
    wire [31:0] iteration_counter;
    wire [63:0] projection_buffer;
    wire [31:0] grid_state;
    wire        grid_stable;
    wire        grid_overflow;
    wire        grid_clk;
    wire        projection_clk;
    wire        readout_clk;
    wire        rst_n_sync;

    // =========================================================================
    // UIO pin assignment
    // uio_oe: bit=1 means output, bit=0 means input
    // [0]=IRQ (output), [1]=READY (output), [7:2]=inputs
    // =========================================================================
    assign uio_oe  = 8'b00000011;
    assign uio_out = {6'b000000, ready_out, irq_out};

    assign trigger     = uio_in[0];
    assign select_page = uio_in[1];

    // =========================================================================
    // Reset synchronizer
    // =========================================================================
    reset_synchronizer u_rst_sync (
        .async_rst (~rst_n),
        .clk       (clk),
        .rst_n     (rst_n_sync)
    );

    // =========================================================================
    // Clock dividers
    // =========================================================================
    clock_divider #(.DIVIDER(4))  u_grid_clk_div (
        .clk_in  (clk),
        .rst_n   (rst_n_sync),
        .clk_out (grid_clk)
    );

    clock_divider #(.DIVIDER(16)) u_proj_clk_div (
        .clk_in  (clk),
        .rst_n   (rst_n_sync),
        .clk_out (projection_clk)
    );

    clock_divider #(.DIVIDER(64)) u_read_clk_div (
        .clk_in  (clk),
        .rst_n   (rst_n_sync),
        .clk_out (readout_clk)
    );

    // =========================================================================
    // Grid processor core (8x8 cellular automaton)
    // =========================================================================
    grid_processor_core u_grid_core (
        .clk            (grid_clk),
        .rst_n          (rst_n_sync),
        .trigger        (trigger),
        .seed_data      (ui_in),
        .projection_clk (projection_clk),
        .grid_state     (grid_state),
        .grid_stable    (grid_stable),
        .grid_overflow  (grid_overflow),
        .iteration_cnt  (iteration_counter),
        .projection_out (projection_buffer),
        .convergence    (grid_convergence_flag)
    );

    // =========================================================================
    // Bridge quantizer (WAIT/READY handshake FSM)
    // =========================================================================
    bridge_quantizer u_bridge (
        .clk               (grid_clk),
        .rst_n             (rst_n_sync),
        .trigger           (trigger),
        .grid_stable       (grid_stable),
        .grid_overflow     (grid_overflow),
        .convergence       (grid_convergence_flag),
        .projection_buffer (projection_buffer),
        .iteration_counter (iteration_counter),
        .ready             (ready_out),
        .irq               (irq_out)
    );

    // =========================================================================
    // ADC interfaces (EMA filter sobre projection buffer)
    // =========================================================================
    adc_interface u_adc_lsb (
        .clk           (projection_clk),
        .rst_n         (rst_n_sync),
        .analog_input  (projection_buffer[7:0]),
        .sample_enable (ready_out),
        .digital_out   (result_lsb)
    );

    adc_interface u_adc_msb (
        .clk           (projection_clk),
        .rst_n         (rst_n_sync),
        .analog_input  (projection_buffer[63:56]),
        .sample_enable (ready_out),
        .digital_out   (result_msb)
    );

    // =========================================================================
    // Output mux - page selector
    // SELECT=0 -> result_lsb (projection buffer EMA [7:0])
    // SELECT=1 -> convergence flags en bits [7:4]
    // =========================================================================
    output_mux u_out_mux (
        .select_page  (select_page),
        .result_lsb   (result_lsb),
        .result_msb   (result_msb),
        .grid_state   (grid_state[31:24]),
        .convergence  (grid_convergence_flag),
        .output_data  (uo_out)
    );

endmodule

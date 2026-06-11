// =============================================================================
// Grid Processor - Top Level Entity
// TinyTapeout 7 Standard Interface
// SkyWater 130nm Technology
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module tt_um_grid_oracle (
    input  wire        ui_clk,
    input  wire        ui_rstb,
    input  wire [7:0]  ui_in,
    output wire [7:0]  uo_out,
    input  wire        uio_in,
    output wire        uio_oe,
    output wire        uio_out,
    input  wire        sclk,
    input  wire        srstb,
    input  wire [7:0]  sf_rdata,
    output wire [7:0]  sf_wdata,
    output wire        sf_wr_en,
    input  wire        sf_rd_en
);

    wire        clk;
    wire        rst_n;
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

    // Clock dividers
    clock_divider #(4) u_grid_clk_div (.clk_in(ui_clk), .rst_n(rst_n), .clk_out(grid_clk));
    clock_divider #(16) u_proj_clk_div (.clk_in(ui_clk), .rst_n(rst_n), .clk_out(projection_clk));
    clock_divider #(64) u_read_clk_div (.clk_in(ui_clk), .rst_n(rst_n), .clk_out(readout_clk));

    reset_synchronizer u_rst_sync (.async_rst(~ui_rstb), .clk(ui_clk), .rst_n(rst_n));

    assign trigger     = uio_in & (~select_page);
    assign select_page = uio_in & select_page;

    grid_processor_core u_grid_core (
        .clk            (grid_clk),
        .rst_n          (rst_n),
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

    bridge_quantizer u_bridge (
        .clk                (grid_clk),
        .rst_n              (rst_n),
        .trigger            (trigger),
        .grid_stable        (grid_stable),
        .grid_overflow      (grid_overflow),
        .convergence        (grid_convergence_flag),
        .projection_buffer  (projection_buffer),
        .iteration_counter  (iteration_counter),
        .ready              (ready_out),
        .irq                (irq_out)
    );

    adc_interface u_adc (
        .clk            (projection_clk),
        .rst_n          (rst_n),
        .analog_input   (projection_buffer[7:0]),
        .sample_enable  (ready_out),
        .digital_out    (result_lsb)
    );

    adc_interface u_adc_msb (
        .clk            (projection_clk),
        .rst_n          (rst_n),
        .analog_input   (projection_buffer[63:56]),
        .sample_enable  (ready_out),
        .digital_out    (result_msb)
    );

    output_mux u_out_mux (
        .select_page    (select_page),
        .result_lsb     (result_lsb),
        .result_msb     (result_msb),
        .grid_state     (grid_state[31:24]),
        .convergence    (grid_convergence_flag[3:0]),
        .output_data    (uo_out)
    );

    assign uio_out = irq_out | (ready_out << 1);
    assign uio_oe  = 1'b1;

    sfr_interface u_sfr (
        .clk         (readout_clk),
        .rst_n       (rst_n),
        .sclk        (sclk),
        .srstb       (srstb),
        .rd_en       (sf_rd_en),
        .wr_en       (sf_wr_en),
        .projection  (projection_buffer),
        .grid_state  (grid_state),
        .convergence (grid_convergence_flag),
        .iterations  (iteration_counter),
        .status      ({irq_out, ready_out, grid_stable, grid_overflow}),
        .sf_wdata    (sf_wdata)
    );

    assign sf_rdata = 8'h00;

endmodule

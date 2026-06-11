// =============================================================================
// Output Multiplexer - Page-based result extraction for RP2040 readout
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module output_mux (
    input  wire        select_page,
    input  wire [7:0]  result_lsb,
    input  wire [7:0]  result_msb,
    input  wire [7:0]  grid_state,
    input  wire [3:0]  convergence,
    output wire [7:0]  output_data
);

    assign output_data = select_page ?
                         {convergence[3:0], 4'b0000} :
                         result_lsb;

endmodule

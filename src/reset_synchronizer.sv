// =============================================================================
// Reset Synchronizer - 2-stage synchronizer for clean reset
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module reset_synchronizer (
    input  wire async_rst,
    input  wire clk,
    output wire rst_n
);

    reg [1:0] sync_stages;

    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            sync_stages <= 2'b11;
        end else begin
            sync_stages <= {sync_stages[0], 1'b0};
        end
    end

    assign rst_n = ~sync_stages[1];

endmodule

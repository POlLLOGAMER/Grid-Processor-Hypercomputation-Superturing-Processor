// =============================================================================
// Clock Divider - Configurable frequency division
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module clock_divider #(
    parameter DIVIDER = 4
)(
    input  wire clk_in,
    input  wire rst_n,
    output wire clk_out
);

    reg [7:0] counter;
    reg       div_clk;

    wire [7:0] half_period = DIVIDER >> 1;

    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'b0;
            div_clk <= 1'b0;
        end else begin
            if (counter >= half_period - 1) begin
                counter <= 8'b0;
                div_clk <= ~div_clk;
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end

    assign clk_out = div_clk;

endmodule

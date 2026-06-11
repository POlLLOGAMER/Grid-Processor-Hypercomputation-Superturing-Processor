// =============================================================================
// Grid Cell - Elementary Computational Unit
// Moore neighborhood (8 neighbors) with 4-bit state
// Totalistic cellular automaton rule for universal computation
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module grid_cell (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire [3:0]  nw, n, ne,
    input  wire [3:0]  w,         e,
    input  wire [3:0]  sw, s, se,
    input  wire [3:0]  seed_in,
    output reg  [3:0]  state_out,
    output wire        is_stable
);

    reg  [3:0] next_state;
    reg  [3:0] current_state;
    reg  [3:0] prev_state;
    reg  [1:0] stable_counter;

    wire [3:0] neighbor_sum;
    assign neighbor_sum = nw + n + ne + w + e + sw + s + se;

    function [3:0] totalistic_rule;
        input [3:0] sum;
        input [3:0] current;
        begin
            case ({sum[2:0], current[0]})
                4'b0000: totalistic_rule = 4'b0001;
                4'b0001: totalistic_rule = 4'b0000;
                4'b0010: totalistic_rule = 4'b0001;
                4'b0011: totalistic_rule = 4'b0010;
                4'b0100: totalistic_rule = 4'b0001;
                4'b0101: totalistic_rule = 4'b0001;
                4'b0110: totalistic_rule = 4'b0011;
                4'b0111: totalistic_rule = 4'b0010;
                4'b1000: totalistic_rule = 4'b0011;
                4'b1001: totalistic_rule = 4'b0010;
                4'b1010: totalistic_rule = 4'b0001;
                4'b1011: totalistic_rule = 4'b0010;
                4'b1100: totalistic_rule = 4'b0000;
                4'b1101: totalistic_rule = 4'b0001;
                4'b1110: totalistic_rule = 4'b0001;
                4'b1111: totalistic_rule = 4'b0000;
                default: totalistic_rule = 4'b0000;
            endcase
        end
    endfunction

    assign is_stable = (current_state == prev_state) ? 1'b1 : 1'b0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state  <= 4'b0000;
            prev_state     <= 4'b0000;
            next_state     <= 4'b0000;
            stable_counter <= 2'b00;
            state_out      <= 4'b0000;
        end else if (enable) begin
            prev_state    <= current_state;
            current_state <= next_state;
            state_out     <= current_state;
            if (is_stable) begin
                if (stable_counter < 2'd3)
                    stable_counter <= stable_counter + 1'b1;
            end else begin
                stable_counter <= 2'b00;
            end
        end
    end

    always @(*) begin
        if (!enable)
            next_state = seed_in;
        else
            next_state = totalistic_rule(neighbor_sum[3:0], current_state);
    end

endmodule

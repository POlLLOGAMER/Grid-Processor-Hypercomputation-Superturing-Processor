// =============================================================================
// Bridge Quantizer - WAIT/READY Handshake and Projection Control
// =============================================================================

`default_nettype none
`timescale 1ns / 1ps

module bridge_quantizer (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger,
    input  wire        grid_stable,
    input  wire        grid_overflow,
    input  wire [3:0]  convergence,
    input  wire [63:0] projection_buffer,
    input  wire [31:0] iteration_counter,
    output wire        ready,
    output wire        irq
);

    localparam IDLE       = 2'b00;
    localparam COMPUTING  = 2'b01;
    localparam CONVERGING = 2'b10;
    localparam DONE       = 2'b11;

    reg [1:0] state;
    reg       ready_reg;
    reg       irq_reg;
    reg       wait_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= IDLE;
            ready_reg  <= 1'b0;
            irq_reg    <= 1'b0;
            wait_reg   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    ready_reg  <= 1'b1;
                    irq_reg    <= 1'b0;
                    wait_reg   <= 1'b0;
                    if (trigger) begin
                        state <= COMPUTING;
                        ready_reg <= 1'b0;
                    end
                end
                COMPUTING: begin
                    wait_reg <= 1'b1;
                    if (grid_stable) begin
                        state <= CONVERGING;
                    end else if (grid_overflow) begin
                        state     <= DONE;
                        irq_reg   <= 1'b1;
                    end
                end
                CONVERGING: begin
                    if (convergence >= 4'd3) begin
                        state     <= DONE;
                        ready_reg <= 1'b1;
                        irq_reg   <= 1'b1;
                        wait_reg  <= 1'b0;
                    end else if (grid_overflow) begin
                        state     <= DONE;
                        ready_reg <= 1'b1;
                        irq_reg   <= 1'b1;
                        wait_reg  <= 1'b0;
                    end
                end
                DONE: begin
                    wait_reg <= 1'b0;
                    if (!trigger) begin
                        irq_reg <= 1'b0;
                        state   <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    assign ready = ready_reg;
    assign irq   = irq_reg;

endmodule

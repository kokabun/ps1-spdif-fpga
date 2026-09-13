`timescale 1ns/1ps
// Portable, fixed-ratio test clock source. Not an audio clock generator.
// HALF_PERIOD=0 forwards clk directly (including during reset).
// HALF_PERIOD>=1 toggles after that many input rising edges.
module test_clock_divider #(
    parameter integer HALF_PERIOD = 5
) (
    input wire clk,
    input wire reset, // synchronous, active high; divided modes only
    output wire test_out
);
    generate
        if (HALF_PERIOD == 0) begin : g_direct
            assign test_out = clk;
        end else begin : g_divided
            localparam integer COUNT_WIDTH = (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);
            reg [COUNT_WIDTH-1:0] count;
            reg level;
            always @(posedge clk) begin
                if (reset) begin
                    count <= 0;
                    level <= 1'b0;
                end else if (count == HALF_PERIOD - 1) begin
                    count <= 0;
                    level <= ~level;
                end else begin
                    count <= count + 1'b1;
                end
            end
            assign test_out = level;
        end
    endgenerate
endmodule

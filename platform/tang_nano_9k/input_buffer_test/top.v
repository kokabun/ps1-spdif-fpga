`timescale 1ns/1ps
// STANDALONE TEST IMAGE: disconnect PS1, optical transmitter and other peripherals.
// Pin 29 is an OUTPUT here. Never connect it to another output.
module input_buffer_test_top #(
    parameter integer HALF_PERIOD = 5, // 0:27MHz, 1:13.5MHz, 5:2.7MHz, 306:~44.118kHz
    parameter integer STARTUP_BITS = 16
) (
    input wire clk_27m,
    output wire test_out
);
    // Gowin power-up initialization; platform-specific, unlike the divider.
    reg [STARTUP_BITS-1:0] startup = 0;
    wire reset = ~(&startup);
    always @(posedge clk_27m) begin
        if (reset)
            startup <= startup + 1'b1;
    end
    test_clock_divider #(.HALF_PERIOD(HALF_PERIOD)) source (
        .clk(clk_27m), .reset(reset), .test_out(test_out)
    );
endmodule

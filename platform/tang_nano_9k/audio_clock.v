// The PoC consumes CXD2925Q WCKO directly (expected 384*Fs).
// No PLL is required: spdif_tx divides this clock by three using a clock enable.
// This wrapper is the platform replacement point if measurement proves that a
// PLL or a different clock source is required.
module audio_clock(input wire clock_in, output wire clock_out);
    assign clock_out = clock_in;
endmodule

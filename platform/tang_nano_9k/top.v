module top (
    input  wire ps1_wcko,
    input  wire ps1_bcko,
    input  wire ps1_lrco,
    input  wire ps1_dato,
    output wire spdif_out,
    output wire overflow_led,
    output wire underflow_led
);
    wire audio_clk;
    reg [7:0] reset_count = 0;
    wire rst_n = &reset_count;
    wire overflow, underflow;

    audio_clock clock_adapter (.clock_in(ps1_wcko), .clock_out(audio_clk));
    always @(posedge audio_clk)
        if (!rst_n) reset_count <= reset_count + 1'b1;

    ps1_spdif_core #(
        .LRCK_LEFT(1'b0),          // MUST be verified on the console
        .SAMPLE_ON_NEGEDGE(1'b0)   // MUST be verified on the console
    ) core (
        .rst_n(rst_n), .bclk(ps1_bcko), .lrck(ps1_lrco),
        .sdata(ps1_dato), .clk_384fs(audio_clk), .spdif_out(spdif_out),
        .fifo_overflow(overflow), .fifo_underflow(underflow));

    // Nano 9K LEDs are active-low.
    assign overflow_led = ~overflow;
    assign underflow_led = ~underflow;
endmodule

// Common correctness fixes backported from integration 793d647.
// Direct PoC: 384Fs, one half-bit enable every three cycles.
module spdif_tx (
    input wire clk_384fs, rst_n,
    input wire [31:0] pcm_frame,
    input wire pcm_valid,
    output wire pcm_ready,
    output reg spdif_out
);
    localparam integer HALF_BIT_CYCLES = 3;
    localparam DIV_BITS = (HALF_BIT_CYCLES < 2) ? 1 : $clog2(HALF_BIT_CYCLES);
    reg [DIV_BITS-1:0] div_q;
    reg [5:0] half_idx;
    reg [8:0] subframe_idx;
    reg [31:0] frame_q, word_q;
    reg frame_valid_q, pre_polarity;
    wire tick = div_q == HALF_BIT_CYCLES-1;
    wire right = subframe_idx[0];
    // Combinational ready: FIFO pops at exactly the edge accepting this pair.
    assign pcm_ready = rst_n && tick && half_idx == 0 && !right;
    wire [15:0] sample_value = right ? frame_q[31:16] :
                                            (pcm_valid ? pcm_frame[15:0] : 16'b0);
    wire invalid = right ? !frame_valid_q : !pcm_valid;
    // 16-bit PCM is left aligned within audio slots 4..27, i.e. slots 12..27.
    wire [31:0] payload = {1'b0, 1'b0, 1'b0, invalid, sample_value, 12'b0};
    wire [31:0] with_parity = {^payload[30:4], payload[30:0]};
    wire [7:0] preamble = subframe_idx == 0 ? 8'b00010111 :
                         right ? 8'b00100111 : 8'b01000111;
    wire [5:0] bit_idx = ((half_idx - 8) >> 1) + 4;
    always @(posedge clk_384fs or negedge rst_n) begin
        if (!rst_n) begin
            div_q <= 0; half_idx <= 0; subframe_idx <= 0;
            frame_q <= 0; word_q <= 0; frame_valid_q <= 0;
            pre_polarity <= 0; spdif_out <= 0;
        end else begin
            div_q <= tick ? 0 : div_q + 1'b1;
            if (tick) begin
                if (half_idx == 0) begin
                    pre_polarity <= spdif_out;
                    spdif_out <= ~spdif_out;
                    word_q <= with_parity;
                    if (!right) begin
                        frame_q <= pcm_valid ? pcm_frame : 32'b0;
                        frame_valid_q <= pcm_valid;
                    end
                end else if (half_idx < 8)
                    spdif_out <= preamble[half_idx] ^ pre_polarity;
                else if (!half_idx[0] || word_q[bit_idx])
                    spdif_out <= ~spdif_out;
                if (half_idx == 63) begin
                    half_idx <= 0;
                    subframe_idx <= subframe_idx == 383 ? 0 : subframe_idx + 1'b1;
                end else half_idx <= half_idx + 1'b1;
            end
        end
    end
endmodule

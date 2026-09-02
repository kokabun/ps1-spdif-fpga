// IEC 60958 consumer PCM transmitter with integrated BMC encoder.
// Clock is 384*Fs; one BMC half-bit is emitted every three clock cycles.
module spdif_tx (
    input  wire        clk_384fs,
    input  wire        rst_n,
    input  wire [31:0] pcm_frame, // {right, left}
    input  wire        pcm_valid,
    output reg         pcm_ready,
    output reg         spdif_out
);
    reg [1:0] div3;
    reg [5:0] half_idx;
    reg [8:0] subframe_idx;
    reg [31:0] frame_q;
    reg [31:0] word_q;
    reg parity_q;

    wire half_tick = (div3 == 2'd2);
    wire channel_right = subframe_idx[0];
    wire [15:0] selected_sample = channel_right ? frame_q[31:16] : frame_q[15:0];
    // Channel-status is all zero: consumer, audio, no pre-emphasis; sampling
    // frequency code 0000 denotes 44.1 kHz in the consumer status block.
    wire channel_status = 1'b0;
    wire [31:0] next_word = {1'b0, channel_status, 1'b0, 1'b0,
                             selected_sample, 8'b0};

    function preamble_half;
        input [2:0] idx;
        input [1:0] kind; // 0=Z, 1=X, 2=Y
        reg [7:0] pattern;
        begin
            case (kind)
                // Indexed LSB-first below: Z=11101000, X=11100010, Y=11100100
                2'd0: pattern = 8'b00010111;
                2'd1: pattern = 8'b01000111;
                default: pattern = 8'b00100111;
            endcase
            preamble_half = pattern[idx];
        end
    endfunction

    wire [1:0] pre_kind = (subframe_idx == 0) ? 2'd0 :
                          (subframe_idx[0] ? 2'd2 : 2'd1);
    wire [5:0] data_bit_idx = ((half_idx - 8) >> 1) + 4;
    wire data_half_second = half_idx[0];

    always @(posedge clk_384fs or negedge rst_n) begin
        if (!rst_n) begin
            div3 <= 0; half_idx <= 0; subframe_idx <= 0;
            frame_q <= 0; word_q <= 0; parity_q <= 0;
            pcm_ready <= 0; spdif_out <= 0;
        end else begin
            pcm_ready <= 1'b0;
            div3 <= half_tick ? 0 : div3 + 1'b1;
            if (half_tick) begin
                if (half_idx < 8) begin
                    spdif_out <= preamble_half(half_idx[2:0], pre_kind);
                end else begin
                    // Transition at every bit boundary; data one adds a
                    // transition at the middle of the bit cell.
                    if (!data_half_second || word_q[data_bit_idx])
                        spdif_out <= ~spdif_out;
                end

                if (half_idx == 0) begin
                    word_q <= next_word;
                    // Even parity across bits 4..31; bits 4..27 are audio here.
                    parity_q <= ^next_word[30:4];
                    if (!channel_right) begin
                        pcm_ready <= 1'b1;
                        if (pcm_valid) frame_q <= pcm_frame;
                    end
                end
                if (half_idx == 61) word_q[31] <= parity_q;

                if (half_idx == 63) begin
                    half_idx <= 0;
                    subframe_idx <= (subframe_idx == 383) ? 0 : subframe_idx + 1'b1;
                end else begin
                    half_idx <= half_idx + 1'b1;
                end
            end
        end
    end
endmodule

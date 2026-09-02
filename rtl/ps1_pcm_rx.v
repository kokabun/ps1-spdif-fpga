// Capture the final 16 bits of each serial-audio slot (right-justified PCM).
// LRCK polarity and sampling edge are deliberately configurable because the
// CXD2925Q timing has not yet been verified from a primary timing diagram.
module ps1_pcm_rx #(
    parameter LRCK_LEFT = 1'b0,
    parameter SAMPLE_ON_NEGEDGE = 1'b0
) (
    input  wire        rst_n,
    input  wire        bclk,
    input  wire        lrck,
    input  wire        sdata,
    output reg  [31:0] frame,
    output reg         frame_valid
);
    reg [15:0] shift_q;
    reg [15:0] left_q;
    reg        lrck_q;
    reg        seen_edge_q;
    wire sample_clk = SAMPLE_ON_NEGEDGE ? ~bclk : bclk;

    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            frame <= 32'b0;
            frame_valid <= 1'b0;
            shift_q <= 16'b0;
            left_q <= 16'b0;
            lrck_q <= LRCK_LEFT;
            seen_edge_q <= 1'b0;
        end else begin
            frame_valid <= 1'b0;
            if (lrck != lrck_q) begin
                // shift_q belongs to the slot that just ended.
                if (lrck_q == LRCK_LEFT)
                    left_q <= shift_q;
                else if (seen_edge_q) begin
                    frame <= {shift_q, left_q};
                    frame_valid <= 1'b1;
                end
                seen_edge_q <= 1'b1;
                lrck_q <= lrck;
            end
            shift_q <= {shift_q[14:0], sdata};
        end
    end
endmodule

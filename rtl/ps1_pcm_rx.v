// Adapted from ps1-spdif-fpga (MIT). Right-justified, final 16 bits per slot.
// A full observed left slot is required before a right slot may form a pair.
module ps1_pcm_rx #(
    parameter LRCK_LEFT = 1'b0,
    parameter SAMPLE_ON_NEGEDGE = 1'b0
)(input wire rst_n, bclk, lrck, sdata,
  output reg [31:0] frame, output reg frame_valid);
    wire sample_clk = SAMPLE_ON_NEGEDGE ? ~bclk : bclk;
    reg [15:0] shift_q, left_q;
    reg lrck_q, boundary_seen, left_valid;
    reg [4:0] bits_q;
    always @(posedge sample_clk or negedge rst_n) begin
        if (!rst_n) begin
            frame <= 0; frame_valid <= 0; shift_q <= 0; left_q <= 0;
            lrck_q <= LRCK_LEFT; boundary_seen <= 0; left_valid <= 0; bits_q <= 0;
        end else begin
            frame_valid <= 0;
            if (lrck != lrck_q) begin
                if (lrck_q == LRCK_LEFT) begin
                    left_q <= shift_q;
                    left_valid <= boundary_seen && bits_q >= 16;
                end else begin
                    if (boundary_seen && bits_q >= 16 && left_valid) begin
                        frame <= {shift_q, left_q}; frame_valid <= 1;
                    end
                    left_valid <= 0;
                end
                boundary_seen <= 1; lrck_q <= lrck; bits_q <= 1;
            end else if (bits_q < 16) bits_q <= bits_q + 1'b1;
            shift_q <= {shift_q[14:0], sdata};
        end
    end
endmodule

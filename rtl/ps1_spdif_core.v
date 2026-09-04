module ps1_spdif_core #(
    parameter LRCK_LEFT = 1'b0,
    parameter SAMPLE_ON_NEGEDGE = 1'b0
) (
    input wire rst_n,
    input wire bclk,
    input wire lrck,
    input wire sdata,
    input wire clk_384fs,
    output wire spdif_out,
    output wire fifo_overflow,
    output wire fifo_underflow
);
    wire rx_clk = SAMPLE_ON_NEGEDGE ? ~bclk : bclk;
    wire rx_rst_n, tx_rst_n;
    reset_release rx_reset(.clk(rx_clk), .arst_n(rst_n), .rst_n(rx_rst_n));
    reset_release tx_reset(.clk(clk_384fs), .arst_n(rst_n), .rst_n(tx_rst_n));
    wire [31:0] rx_frame;
    wire rx_valid;
    wire fifo_full, fifo_empty;
    wire [31:0] fifo_data;
    wire sample_request;
    reg underflow_q, overflow_q, stream_started_q;

    ps1_pcm_rx #(.LRCK_LEFT(LRCK_LEFT), .SAMPLE_ON_NEGEDGE(SAMPLE_ON_NEGEDGE)) rx (
        .rst_n(rx_rst_n), .bclk(bclk), .lrck(lrck), .sdata(sdata),
        .frame(rx_frame), .frame_valid(rx_valid));

    async_fifo fifo (
        .wr_clk(rx_clk), .wr_rst_n(rx_rst_n), .wr_data(rx_frame),
        .wr_en(rx_valid), .wr_full(fifo_full),
        .rd_clk(clk_384fs), .rd_rst_n(tx_rst_n), .rd_data(fifo_data),
        .rd_en(sample_request && !fifo_empty), .rd_empty(fifo_empty));

    spdif_tx tx (.clk_384fs(clk_384fs), .rst_n(tx_rst_n),
        .pcm_frame(fifo_data), .pcm_valid(!fifo_empty),
        .pcm_ready(sample_request), .spdif_out(spdif_out));

    always @(posedge rx_clk or negedge rx_rst_n)
        if (!rx_rst_n) overflow_q <= 1'b0;
        else if (rx_valid && fifo_full) overflow_q <= 1'b1;

    always @(posedge clk_384fs or negedge tx_rst_n)
        if (!tx_rst_n) begin
            underflow_q <= 1'b0;
            stream_started_q <= 1'b0;
        end else begin
            if (!fifo_empty) stream_started_q <= 1'b1;
            if (stream_started_q && sample_request && fifo_empty)
                underflow_q <= 1'b1;
        end

    assign fifo_overflow = overflow_q;
    assign fifo_underflow = underflow_q;
endmodule

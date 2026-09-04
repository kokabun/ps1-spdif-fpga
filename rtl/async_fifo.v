// Small, portable dual-clock FIFO. DEPTH must be a power of two, ADDR_BITS >= 2.
module async_fifo #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 2
) (
    input  wire                 wr_clk,
    input  wire                 wr_rst_n,
    input  wire [WIDTH-1:0]     wr_data,
    input  wire                 wr_en,
    output reg                  wr_full,
    input  wire                 rd_clk,
    input  wire                 rd_rst_n,
    output wire [WIDTH-1:0]     rd_data,
    input  wire                 rd_en,
    output wire                 rd_empty
);
    localparam PTR_BITS = ADDR_BITS + 1;
    reg [WIDTH-1:0] mem [0:(1<<ADDR_BITS)-1];
    reg [PTR_BITS-1:0] wr_bin, wr_gray, rd_bin, rd_gray;
    reg [PTR_BITS-1:0] rd_gray_w1, rd_gray_w2;
    reg [PTR_BITS-1:0] wr_gray_r1, wr_gray_r2;

    wire [PTR_BITS-1:0] wr_bin_next = wr_bin + ((wr_en && !wr_full) ? 1'b1 : 1'b0);
    wire [PTR_BITS-1:0] rd_bin_next = rd_bin + ((rd_en && !rd_empty) ? 1'b1 : 1'b0);
    wire [PTR_BITS-1:0] wr_gray_next = (wr_bin_next >> 1) ^ wr_bin_next;
    wire [PTR_BITS-1:0] rd_gray_next = (rd_bin_next >> 1) ^ rd_bin_next;

    assign rd_empty = (rd_gray == wr_gray_r2);
    assign rd_data = mem[rd_bin[ADDR_BITS-1:0]];
    wire full_next = (wr_gray_next == {~rd_gray_w2[PTR_BITS-1:PTR_BITS-2],
                                        rd_gray_w2[PTR_BITS-3:0]});

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin <= 0; wr_gray <= 0; rd_gray_w1 <= 0; rd_gray_w2 <= 0; wr_full <= 0;
        end else begin
            rd_gray_w1 <= rd_gray; rd_gray_w2 <= rd_gray_w1;
            if (wr_en && !wr_full) mem[wr_bin[ADDR_BITS-1:0]] <= wr_data;
            wr_bin <= wr_bin_next; wr_gray <= wr_gray_next; wr_full <= full_next;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin <= 0; rd_gray <= 0; wr_gray_r1 <= 0; wr_gray_r2 <= 0;
        end else begin
            wr_gray_r1 <= wr_gray; wr_gray_r2 <= wr_gray_r1;
            rd_bin <= rd_bin_next; rd_gray <= rd_gray_next;
        end
    end
endmodule

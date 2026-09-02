`timescale 1ns/1ps
module spdif_tx_tb;
    reg clk = 0, rst_n = 0;
    wire ready, spdif;
    integer cycles = 0, requests = 0, edges = 0, previous_request = -1;
    integer half_count = 0;
    reg last_spdif;
    reg [7:0] expected_z = 8'b00010111;
    always #29.5215 clk = ~clk; // approximately 16.9344 MHz
    spdif_tx dut(.clk_384fs(clk), .rst_n(rst_n),
        .pcm_frame(32'h8001_7ffe), .pcm_valid(1'b1),
        .pcm_ready(ready), .spdif_out(spdif));
    always @(posedge clk) begin
        cycles <= cycles + 1;
        if (ready) begin
            if (previous_request >= 0 && cycles - previous_request != 384) begin
                $display("FAIL request interval=%0d", cycles - previous_request);
                $finish(1);
            end
            previous_request <= cycles;
            requests <= requests + 1;
        end
        if (spdif != last_spdif) edges <= edges + 1;
        last_spdif <= spdif;
        if (requests == 5) begin
            if (edges == 0) begin
                $display("FAIL no BMC transitions"); $finish(1);
            end
            $display("PASS spdif_tx_tb requests=%0d edges=%0d", requests, edges);
            $finish(0);
        end
    end
    // Verify the first Z preamble half-bit sequence after reset.
    always @(negedge clk) begin
        if (rst_n && half_count < 8 && dut.half_idx == half_count + 1) begin
            #1;
            if (spdif !== expected_z[half_count]) begin
                $display("FAIL Z preamble half=%0d value=%b", half_count, spdif);
                $finish(1);
            end
            half_count = half_count + 1;
        end
    end
    initial begin last_spdif = 0; #200 rst_n = 1; end
endmodule

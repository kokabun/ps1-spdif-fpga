`timescale 1ns/1ps
module ps1_pcm_rx_tb;
    reg rst_n = 0, bclk = 0, lrck = 0, sdata = 0;
    wire [31:0] frame;
    wire valid;
    reg [31:0] observed_frame;
    integer observed_valid = 0;
    integer errors = 0;
    always #50 bclk = ~bclk;

    ps1_pcm_rx dut(.rst_n(rst_n), .bclk(bclk), .lrck(lrck), .sdata(sdata),
                   .frame(frame), .frame_valid(valid));
    always @(negedge bclk) begin
        if (valid) begin observed_frame = frame; observed_valid = 1; end
    end

    task slot;
        input channel;
        input [31:0] payload;
        input integer bits;
        integer i;
        begin
            lrck = channel;
            for (i = bits-1; i >= 0; i = i-1) begin
                sdata = payload[i];
                @(posedge bclk); @(negedge bclk);
            end
        end
    endtask

    initial begin
        #125 rst_n = 1;
        // 32-bit slots with the 16-bit sample in the final 16 bit positions.
        slot(0, 32'hCAFE_1234, 32);
        slot(1, 32'hBEEF_ABCD, 32);
        slot(0, 32'h0000_5678, 32);
        #1;
        if (!observed_valid || observed_frame !== 32'hABCD_1234) begin
            $display("FAIL frame=%h valid=%0d", observed_frame, observed_valid); errors = errors + 1;
        end
        if (errors == 0) $display("PASS ps1_pcm_rx_tb");
        $finish(errors != 0);
    end
endmodule

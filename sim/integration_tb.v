`timescale 1ns/1ps
module integration_tb;
    localparam DIV = 3;
    parameter NEG = 0;
    parameter LEFT = 0;
    parameter SLOT = 32;
    localparam BHALF = 10*DIV*128/(2*SLOT)/2;
    reg clk = 0, bclk = 0, rst_n = 1, lrck = LEFT, data = 0;
    wire spdif, overflow, underflow;
    integer f, i, trace, n;
    reg [31:0] payload;
    always #5 clk = ~clk;
    always #(BHALF) bclk = ~bclk;
    ps1_spdif_core #(.SAMPLE_ON_NEGEDGE(NEG), .LRCK_LEFT(LEFT)) dut (
      .rst_n(rst_n), .bclk(bclk), .lrck(lrck), .sdata(data), .clk_384fs(clk),
      .spdif_out(spdif), .fifo_overflow(overflow), .fifo_underflow(underflow));
    task drive_edge;
      begin if (NEG) @(posedge bclk); else @(negedge bclk); end
    endtask
    task slot;
      input ch;
      input [15:0] value;
      begin
        payload = {16'hcafe,value};
        for (i=SLOT-1;i>=0;i=i-1) begin
          drive_edge(); lrck=ch; data=payload[i];
        end
      end
    endtask
    always @(negedge clk) if (rst_n) $fwrite(trace,"%b\n",spdif);
    initial begin
      trace=$fopen("trace.txt","w");
      #1 rst_n=0; #500 rst_n=1;
      // The first pair can be partial after reset; identifiable IDs follow it.
      for (f=0;f<420;f=f+1) begin
        slot(LEFT,16'h1000+f); slot(!LEFT,16'h8000+f);
      end
      // End the final right slot, then hold LRCK to stop producing frames.
      drive_edge(); lrck=LEFT; data=0;
      repeat (128*DIV*8) @(posedge clk);
      if (overflow !== 0 || underflow !== 1) $fatal(1,"FIFO status overflow=%b underflow=%b",overflow,underflow);
      rst_n=0; #25;
      if (overflow !== 0 || underflow !== 0) $fatal(1,"reset did not clear diagnostics");
      $fclose(trace); $display("PASS integration stimulus DIV=%0d NEG=%0d LEFT=%0d SLOT=%0d",DIV,NEG,LEFT,SLOT); $finish;
    end
    initial begin #10000000; $fatal(1,"timeout"); end
endmodule

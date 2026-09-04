`timescale 1ns/1ps
module fifo_tb;
 reg wclk=0,rclk=0,rst=0,we=0,re=0;
 reg [31:0] din=0;
 wire [31:0] dout;
 wire full,empty;
 integer i;
 always #5 wclk=~wclk;
 always #7 rclk=~rclk;
 async_fifo dut(wclk,rst,din,we,full,rclk,rst,dout,re,empty);
 task put;
 input [31:0] v;
 begin @(negedge wclk);din=v;we=1;@(negedge wclk);we=0;end
 endtask
 task get;
 input [31:0] v;
 begin
 @(negedge rclk);if(empty || dout !== v)$fatal(1,"FIFO order/full capacity %h expected %h",dout,v);
 re=1;@(negedge rclk);re=0;
 end
 endtask
 initial begin
 #2;rst=0;#20;rst=1;
 for(i=0;i<4;i=i+1)put(i+100);
 if(full !== 1)$fatal(1,"FIFO must hold exactly four entries");
 put(999); // Must not overwrite while full.
 repeat(4)@(negedge rclk);
 for(i=0;i<4;i=i+1)get(i+100);
 if(empty !== 1)$fatal(1,"FIFO empty");
 repeat(4)@(negedge wclk);
 if(full !== 0)$fatal(1,"FIFO full release");
 for(i=0;i<12;i=i+1)begin put(i);repeat(4)@(negedge rclk);get(i);repeat(4)@(negedge wclk);end
 put(123);rst=0;#20;rst=1;repeat(4)@(negedge rclk);
 if(empty !== 1 || full !== 0)$fatal(1,"FIFO reset");
 $display("PASS fifo capacity/order/wrap/full/reset");$finish;
 end
 initial begin #100000; $fatal(1,"timeout");end
endmodule

`timescale 1ns/1ps
module divider_check #(parameter integer HALF_PERIOD = 5)(output reg done = 0);
    reg clk = 0;
    reg reset = 1;
    wire test_out;
    integer pass, i, expected;
    localparam integer CYCLES = (HALF_PERIOD > 0) ? HALF_PERIOD * 6 + 5 : 25;
    always #18.518 clk = ~clk;
    test_clock_divider #(.HALF_PERIOD(HALF_PERIOD)) dut (.*);

    initial begin
        // Reapply reset after running, including with a partial count outstanding.
        for (pass = 0; pass < 2; pass = pass + 1) begin
            reset = 1;
            repeat (3) begin
                @(posedge clk); #1;
                if (test_out !== (HALF_PERIOD == 0))
                    $fatal(1, "reset/rising HP=%0d", HALF_PERIOD);
                @(negedge clk); #1;
                if (test_out !== 1'b0) $fatal(1, "reset/falling HP=%0d", HALF_PERIOD);
            end
            reset = 0;
            for (i = 0; i < CYCLES; i = i + 1) begin
                @(posedge clk); #1;
                if (HALF_PERIOD == 0) expected = 1;
                else expected = ((i + 1) / HALF_PERIOD) % 2;
                if (test_out !== expected[0])
                    $fatal(1, "period/duty/rising HP=%0d cycle=%0d", HALF_PERIOD, i);
                @(negedge clk); #1;
                if (HALF_PERIOD == 0) expected = 0;
                if (test_out !== expected[0])
                    $fatal(1, "period/duty/falling HP=%0d cycle=%0d", HALF_PERIOD, i);
            end
        end
        done = 1;
    end
endmodule

module test_clock_divider_tb;
    wire [4:0] done;
    divider_check #(.HALF_PERIOD(0)) c0(done[0]);
    divider_check #(.HALF_PERIOD(1)) c1(done[1]);
    divider_check #(.HALF_PERIOD(5)) c5(done[2]);
    divider_check #(.HALF_PERIOD(306)) c306(done[3]);
    // Also cover a non-default power-of-two divide count.
    divider_check #(.HALF_PERIOD(8)) c8(done[4]);
    reg clk_27m = 0;
    wire test_out;
    reg top_done = 0;
    integer i, expected;
    always #18.518 clk_27m = ~clk_27m;
    input_buffer_test_top #(.STARTUP_BITS(3)) top (.*);
    initial begin
        // Seven startup edges hold the divider reset. The eighth starts its count.
        for (i = 1; i <= 100; i = i + 1) begin
            @(posedge clk_27m); #1;
            expected = (i <= 7) ? 0 : ((i - 7) / 5) % 2;
            if (test_out !== expected[0]) $fatal(1, "platform startup cycle=%0d", i);
        end
        top_done = 1;
    end
    initial begin
        wait ((&done) && top_done);
        $display("PASS test_clock_divider: direct/divided clocks, duty, reset, platform startup");
        $finish;
    end
    initial begin
        #1000000;
        $fatal(1, "timeout");
    end
endmodule

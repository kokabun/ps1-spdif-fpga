// Asynchronous assertion, local-clock synchronous release.
module reset_release(input wire clk, arst_n, output wire rst_n);
    reg [1:0] release_q;
    always @(posedge clk or negedge arst_n)
        if (!arst_n) release_q <= 0;
        else release_q <= {release_q[0], 1'b1};
    assign rst_n = release_q[1];
endmodule

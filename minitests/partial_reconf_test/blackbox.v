//See README and tcl for more info

module blackbox(input wire clk,
        input wire din, output wire [3:0] dout);
    parameter DIN_N = 4;
    parameter DOUT_N = 4;

    test #(.DIN_N(DIN_N), .DOUT_N(DOUT_N)) test (
        .clk(clk),
        .din(din), .dout(dout));
endmodule


//See README and tcl for more info

`include "defines.v"

module top(input wire clk,
        input wire [DIN_N-1:0] sumin, output wire [DIN_N-1:0] sumout);
    parameter DIN_N = `DIN_N;
    parameter DOUT_N = `DOUT_N;

    roi #(.DIN_N(DIN_N), .DOUT_N(DOUT_N)) roi (
        .clk(clk),
        .sumin(sumin), .sumout(sumout));
endmodule


//See README and tcl for more info

`include "defines.v"

module roi(input clk,
        input [DIN_N-1:0] din, output [DOUT_N-1:0] dout, input [DIN_N-1:0] sumin, output reg [DIN_N-1:0] sumout);
    parameter DIN_N = `DIN_N;
    parameter DOUT_N = `DOUT_N;
    reg [DIN_N-1:0] result = 0;

    genvar i;
    generate
        //CLK
        (* KEEP, DONT_TOUCH *)
        reg clk_reg;
        always @(posedge clk) begin
            clk_reg <= clk_reg;
            result <= result + sumin;
            sumout <= result;
        end
    endgenerate
endmodule

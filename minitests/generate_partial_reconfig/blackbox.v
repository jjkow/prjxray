// Blackbox is an empty module with connected CLK and LUT6 for douts
// with no logic inside.

module test(input wire clk,
        output wire [2:0] dout);
    parameter DOUT_N = 3;

    genvar i;
    generate
        //CLK
        (* KEEP, DONT_TOUCH *)
        reg clk_reg;
        always @(posedge clk) begin
            clk_reg <= clk_reg;
        end

        //DOUT
        for (i = 0; i < DOUT_N; i = i+1) begin:outs
            (* KEEP, DONT_TOUCH *)
            LUT6 #(
                .INIT(64'b10)
            ) lut (
                .I0(1'b0),
                .I1(1'b0),
                .I2(1'b0),
                .I3(1'b0),
                .I4(1'b0),
                .I5(1'b0),
                .O(dout[i]));
        end
    endgenerate
endmodule


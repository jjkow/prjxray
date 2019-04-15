//See README and tcl for more info

module test(input clk,
    input din, output reg [3:0] dout);
    parameter DIN_N = 1;
    parameter DOUT_N = 4;
    reg [3:0] result = 0;
    reg [31:0] ticks = 0;

    generate
        //CLK
        (* KEEP, DONT_TOUCH *)
        always @(posedge clk) begin
            ticks <= ticks + 1;
            if(ticks > 10000000) begin
                ticks <= 0;
                if(din == 1) begin
                    if(result < 1) begin
                        result <= 15;
                    end
                    else begin
                        result <= result - 1;
                    end
                end
                else begin
                    if(result > 14) begin
                        result <= 0;
                    end
                    else begin
                        result <= result + 1;
                    end
                end
                dout <= result;
            end
        end
    endgenerate
endmodule

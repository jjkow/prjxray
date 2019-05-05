module roi(input wire clk,
        output reg blinky,
        output [2:0] dout);
    parameter DOUT_N = 3;
    //parameter DIN_N = 3;

    // STATIC LOGIC
    reg [31:0] ticks = 0;
    reg result = 0;
    always @(posedge clk) begin
        ticks <= ticks + 1;
        if(ticks > 10000000) begin
            ticks <= 0;
            result <= !result;
            blinky <= result;
        end
    end
    // STATIC LOGIC


    // DYNAMIC LOGIC
    test #(.DOUT_N(DOUT_N)) test (
        .clk(clk),
        .dout(dout));
    // DYNAMIC LOGIC
    //
endmodule


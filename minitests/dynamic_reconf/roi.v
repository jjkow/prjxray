module roi(input wire clk,
        output reg blinky,
        output [2:0] dout);
    parameter DOUT_N = 3;
    //parameter DIN_N = 3;

    // STATIC LOGIC
    reg [31:0] stticks = 0;
    reg stresult = 0;
    always @(posedge clk) begin
        stticks <= stticks + 1;
        if(stticks > 10000000) begin
            stticks <= 0;
            stresult <= !stresult;
            blinky <= stresult;
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


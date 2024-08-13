module linear_feedback_shifter #(
    parameter n=8
)
(
    input clk,
    input rst,
    input [n-1:0] in,
    output [n-1:0] out
);

    wire lsb;
    reg [n-1:0] in_reg;

    assign out = in_reg;
    assign lsb = in_reg[4] ^ in_reg[3] ^ in_reg[2] ^ in_reg[0];

    always @(clk) begin
        if(!rst)
            in_reg <= in;
        else if(in_reg == {n{1'b0}} ) begin
            in_reg <= {n{1'b0}} + 1'b1;
        end
        else begin
            in_reg <= {lsb, in_reg[n-1:1]};
        end
    end


endmodule

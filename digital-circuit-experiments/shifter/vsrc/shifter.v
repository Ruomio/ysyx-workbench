module shifter #(
    parameter n=8
)
(
    input clk,
    input rst,
    input [3:0] mode,
    input [n-1:0] in,
    input switch,
    output [n-1:0] out
);

    reg [n-1:0] in_reg;

    assign out = in_reg;

    always @(clk) begin
        if(!rst || mode == 4'b0)
            in_reg <= {n{1'b0}};
        else if(mode == 4'b0001) begin
            in_reg <= in;
        end
        else if(mode == 4'b0010) begin
            in_reg <= {1'b0, in_reg[7:1]};
        end
        else if(mode == 4'b0011) begin
            in_reg <= {in_reg[6:0], 1'b0};
        end
        else if(mode == 4'b0100) begin
            in_reg <= {in_reg[7], in_reg[7:1]};
        end 
        else if(mode == 4'b0101) begin
            in_reg <= {switch, in_reg[7:1]};
        end 
        else if(mode == 4'b0110) begin
            in_reg <= {in_reg[0], in_reg[7:1]};
        end 
        else if(mode == 4'b0111) begin
            in_reg <= {in_reg[6:0], in_reg[7]};
        end 
        else begin
            in_reg <= in_reg;
        end 
    end



endmodule

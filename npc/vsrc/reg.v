module ysyx_24080020_REG (
    input clk,
    input rst,
    input wen,
    input [4:0] idx,
    input [31:0] res,
    output reg [31:0] val
);
    //`include "./define.v"

    reg [`ysyx_24080020_WIDTH-1:0] regs[`ysyx_24080020_WIDTH-1:0];

    integer  i;

    always @(posedge clk) begin
        if(!clk) begin
            for(i = 0; i<6'd32; i = i+1 ) begin
                regs[i] <= 32'b0;
            end
        end
        else if(wen) begin
            regs[idx] <= res;
        end
        else begin
            val <= regs[idx];
        end
    end


endmodule
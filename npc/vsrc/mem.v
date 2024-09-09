`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] maddr,
    input [`ysyx_24080020_WIDTH-1:0] mdata,
    input wen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata

);

    reg [`ysyx_24080020_WIDTH-1:0] mem [1023:0];     // 4KB

    always @(posedge clk) begin
        if(!clk) begin
            mem[0] <= 32'hFFFFFEB7; //  lui   x23, 0xFFF;
            mem[1] <= 32'h00010073; //  ebreak;
        end
        else if(wen) begin
            mem[maddr - `ysyx_24080020_MBASE] <= mdata;
        end
        else begin
            mrdata <= mem[maddr - `ysyx_24080020_MBASE];
        end

    end

endmodule
`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] maddr,
    input [`ysyx_24080020_WIDTH-1:0] mdata,
    input wen,
    output [`ysyx_24080020_WIDTH-1:0] mrdata

);

    reg [`ysyx_24080020_WIDTH-1:0] mrdata_reg;

    reg [`ysyx_24080020_WIDTH-1:0] mem [32:0];     // 4KB

    always @(posedge clk) begin
        if(!clk) begin
            mem[0] <= 32'hFFFFFEB7; //  lui   x23, 0xFFF;
            mem[1] <= 32'h00010073; //  ebreak;
        end
        else if(wen) begin
            mem[maddr - `ysyx_24080020_MBASE] <= mdata;
        end
        else begin
            mrdata_reg <= mem[maddr - `ysyx_24080020_MBASE];
        end

    end

    assign mrdata = mrdata_reg;

endmodule
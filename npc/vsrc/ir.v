`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin

);
    import "DPI-C" function int read_memory(input int addr, input int len);

    always @(posedge clk or posedge rst) begin
        if(!rst) begin
            inst <= 32'b0;
        end
        else if(if_en) begin
            inst <= read_memory(addr, 32'b100);
            inst_fin <= 1'b1;
        end
        else begin
            inst <= inst;
            inst_fin <= 1'b0;
        end
    end

endmodule
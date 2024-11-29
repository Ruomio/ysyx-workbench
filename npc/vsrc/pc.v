`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    input [`ysyx_24080020_WIDTH-1:0] snpc,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);


    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
        end
        else if(is_dnpc) begin
            addr <= dnpc;
        end
        else begin
            addr <= snpc;
        end

    end



endmodule

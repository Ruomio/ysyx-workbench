`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input is_update_pc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    // input [`ysyx_24080020_WIDTH-1:0] snpc,
    output reg [`ysyx_24080020_WIDTH-1:0] addr
);


    always @(posedge clk) begin
        if(!rst) begin
            addr <= `ysyx_24080020_MBASE;
        end
        else if(is_update_pc) begin
            addr <= is_dnpc ? dnpc : addr + 32'd4;
        end
        else begin
            addr <= addr;
        end

    end



endmodule

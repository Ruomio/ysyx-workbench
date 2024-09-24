`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] snpc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [3:0] pc_len
);
    reg cnt;

    assign pc_len = 4'b100;

    always @(posedge clk) begin
        if(!rst) begin
            pc <= `ysyx_24080020_MBASE;
            cnt <= 1'b0;
        end
        else if(cnt == 1'b1) begin
            if(is_dnpc) pc <= dnpc;
            else pc <= snpc;

            cnt <= 1'b0;
        end
        else begin
            cnt <= cnt + 1'b1;
        end

    end


endmodule
`include "vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] snpc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    output [`ysyx_24080020_WIDTH-1:0] pc,
    output [`ysyx_24080020_WIDTH-1:0] maddr,
    output [3:0] mlen
);
    reg [`ysyx_24080020_WIDTH-1:0] tmp_pc;

    assign pc = tmp_pc;

    always @(posedge clk) begin
        if(!rst) begin
            tmp_pc <= `ysyx_24080020_MBASE;
        end
        else if(is_dnpc) begin
            tmp_pc <= dnpc; 
            maddr = dnpc;
            mlen = 4'b100;
        end
        else begin
            tmp_pc <= snpc;
            maddr = snpc;
            mlen = 4'b100;
        end

    end


endmodule
`include "vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] snpc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [3:0] pc_len
);
    // reg [`ysyx_24080020_WIDTH-1:0] tmp_pc;

    // assign pc = !rst ? `ysyx_24080020_WIDTH : (is_dnpc ? dnpc : snpc);
    assign pc_len = 4'b100;

    always @(posedge clk) begin
        if(!rst) begin
            pc <= `ysyx_24080020_MBASE;
        end
        else if(is_dnpc) begin
            pc <= dnpc; 
        end
        else begin
            pc <= snpc;
        end

    end


endmodule
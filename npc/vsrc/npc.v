`include "vsrc/define.v"
module ysyx_24080020_NPC(
    input clk,
    input rst,
    input [31:0] inst,
    output [31:0] pc
);

    reg [`ysyx_24080020_WIDTH-1:0] snpc;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc;

    
    ysyx_24080020_IFU ifu(.clk(clk), .rst(rst), .pc(pc), .len(`ysyx_24080020_LEN), .snpc(snpc));
    assign pc = snpc;




endmodule

module ysyx_24080020_NPC(
    input clk,
    input rst,
    input [31:0] inst,
    output [31:0] pc
);
    `include "define.v"
    //`include "ifu.v"

    reg [`ysyx_24080020_WIDTH-1:0] snpc;
    reg [`ysyx_24080020_WIDTH-1:0] dnpc;

    
    ysyx_24080020_IFU ifu(.clk(clk), .rst(rst), .pc(pc), .snpc(snpc));
    assign pc = snpc;




endmodule

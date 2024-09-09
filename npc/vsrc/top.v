module top(
    input clk,
    input rst,
    input [31:0] inst,
    output [31:0] pc
);

    ysyx_24080020_NPC u_npc(.clk(clk), .rst(rst), .inst(inst), .pc(pc));


endmodule
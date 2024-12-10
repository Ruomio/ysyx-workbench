module top(
    input clk,
    input rst,
    output [31:0] inst
);

    ysyx_24080020_NPC u_npc(.clk(clk), .rst(rst), .inst(inst));


endmodule
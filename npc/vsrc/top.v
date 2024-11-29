module top(
    input clk,
    input rst,
    output [31:0] pc
);

    ysyx_24080020_NPC u_npc(.clk(clk), .rst(rst));


endmodule
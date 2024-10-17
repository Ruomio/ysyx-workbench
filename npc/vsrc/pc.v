`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [3:0] pc_len
);

  assign pc_len = 4'b100;

  always @(posedge clk) begin
    if (!rst) begin
      pc <= `ysyx_24080020_MBASE;
    end else begin
      if (is_dnpc) pc <= dnpc;
      else pc <= pc + 32'b100;
    end
  end


endmodule

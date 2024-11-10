`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input reg_pc_valid,
    input ir_pc_ready,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [3:0] pc_len,
    output reg pc_ir_valid
);
  reg state; // 0: idle;  1: waite_ready;

  assign pc_len = 4'b100;

  always @(posedge clk) begin
    if (!rst) begin
      pc <= `ysyx_24080020_MBASE;
    end 
    else if (reg_pc_valid & ir_pc_ready) begin
      if (is_dnpc) pc <= dnpc;
      else pc <= pc + 32'b100;
      pc_ir_valid <= 1'b1;
    end 
    else pc_ir_valid <= 1'b0;
  end

  always @(posedge clk) begin
    if(!state) begin 
      if(pc_ir_valid) state <= 1'b1;
      else state <= 1'b0;
    end
    else begin
      
    end
  end

endmodule

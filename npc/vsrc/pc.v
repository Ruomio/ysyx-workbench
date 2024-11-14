`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_PC (
    input clk,
    input rst,
    input reg_pc_valid,
    input ir_pc_ready,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    // input [`ysyx_24080020_WIDTH-1:0] alu_out,
    // output reg [`ysyx_24080020_WIDTH-1:0] alu_src1,
    // output reg [`ysyx_24080020_WIDTH-1:0] alu_src2,
    // output reg [3:0] alu_op,
    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [3:0] pc_len,
    output reg pc_reg_ready,
    output reg pc_ir_valid
);
  reg state = 1'b0; // 0: idle;  1: waite_ready;

  assign pc_len = 4'b100;

  always @(posedge clk) begin
    if (!rst) begin
      pc <= `ysyx_24080020_MBASE;
      pc_ir_valid <= 1'b0;
    end 
    else if (reg_pc_valid) begin
      if(pc_ir_valid) pc_reg_ready <= 1'b0;
      else pc_reg_ready <= 1'b1;
    end 
    else if(ir_pc_ready) begin
      if (is_dnpc) pc <= dnpc;
      else begin
        // alu_op <= `ysyx_24080020_ALU_ADD;
        // alu_src1 <= pc;
        // alu_src2 <= 32'b100;
        // pc <= alu_out;
        pc <= pc + 32'b100;
      end
      pc_ir_valid <= 1'b0;
    end
    else begin
      pc_ir_valid <= 1'b1;
      pc_reg_ready <= 1'b0;
    end
  end

  always @(posedge clk) begin
    if(!state) begin 
      if(pc_ir_valid) state <= 1'b1;
      else state <= 1'b0;
    end
    else begin
      if(ir_pc_ready) state <= 1'b0;
      else state <= 1'b1;
    end
  end

endmodule

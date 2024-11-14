`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_ALU(
    input [3:0] alu_op,
    input [`ysyx_24080020_WIDTH-1:0] alu_src1,
    input [`ysyx_24080020_WIDTH-1:0] alu_src2,
    input [`ysyx_24080020_WIDTH-1:0] alu_pc,
    input [`ysyx_24080020_WIDTH-1:0] alu_shift,
    output [`ysyx_24080020_WIDTH-1:0] alu_out
);

    always @(*) begin
        case(alu_op)
            `ysyx_24080020_ALU_ADD: begin
                alu_out = alu_src1 + alu_src2;
            end
            `ysyx_24080020_ADD_SUB: begin
                alu_out = alu_src1 - alu_src2;
            end
            `ysyx_24080020_ALU_SLT: begin
                alu_out = $signed(alu_src1) < $signed(alu_src2) ? 32'b1 : 32'b0;
            end 
            `ysyx_24080020_ALU_SLTU: begin
                alu_out = alu_src1 < alu_src2 ? 32'b1 : 32'b0;
            end 
            `ysyx_24080020_ALU_OR : begin
                alu_out = alu_src1 | alu_src2;
            end 
            `ysyx_24080020_ALU_XOR: begin
                alu_out = alu_src1 ^ alu_src2;
            end 
            `ysyx_24080020_ALU_AND: begin
                alu_out = alu_src1 & alu_src2;
            end 
            `ysyx_24080020_ALU_SLL: begin
                alu_out = alu_src1 << alu_src2[4:0];
            end 
            `ysyx_24080020_ALU_SRL: begin
                alu_out = alu_src1 >> alu_src2[4:0];
            end 
            `ysyx_24080020_ALU_SRA: begin
                alu_out = alu_src1 >> alu_src2[4:0] | ({32{alu_src1[31]}} & ~(32'hffffffff >> alu_src2[4:0]));
            end 
            `ysyx_24080020_ALU_BEQ: begin
                alu_out = alu_src1 == alu_src2 ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
            `ysyx_24080020_ALU_BNE: begin
                alu_out = alu_src1 != alu_src2 ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
            `ysyx_24080020_ALU_BLT: begin
                alu_out = $signed(alu_src1) < $signed(alu_src2) ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
           `ysyx_24080020_ALU_BLTU: begin
                alu_out = alu_src1 < alu_src2 ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
            `ysyx_24080020_ALU_BGE: begin
                alu_out = $signed(alu_src1) >= $signed(alu_src2) ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
            `ysyx_24080020_ALU_BGEU: begin
                alu_out = alu_src1 >= alu_src2 ? alu_pc + alu_shift : alu_pc + 32'b100;
            end 
            
            default: begin
                alu_out = 32'b0;
            end
        endcase

    end


endmodule
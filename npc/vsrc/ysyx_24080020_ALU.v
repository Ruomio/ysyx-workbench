`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ALU(
    input [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op,
    input [`ysyx_24080020_WIDTH-1:0] alu_src1,
    input [`ysyx_24080020_WIDTH-1:0] alu_src2,
    output reg [`ysyx_24080020_WIDTH-1:0] alu_out,
    output alu_zero
);

    assign alu_zero = alu_out == 32'b0;

    always @(*) begin
        case(alu_op)
            `ysyx_24080020_ALU_ADD: begin
                alu_out = alu_src1 + alu_src2;
            end
            `ysyx_24080020_ALU_SUB: begin
                alu_out = alu_src1 - alu_src2;
            end
            `ysyx_24080020_ALU_SLT: begin
                alu_out = $signed(alu_src1) < $signed(alu_src2) ? 32'b1 : 32'b0;
                // alu_out = alu_src1 < alu_src2 ? 32'b1 : 32'b0;
            end
            `ysyx_24080020_ALU_SLTU: begin
                alu_out = alu_src1 < alu_src2 ? 32'b1 : 32'b0;
                // alu_out = $unsigned(alu_src1) < $unsigned(alu_src2) ? 32'b1 : 32'b0;
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

            default: begin
                alu_out = 32'hffffffff;
            end
        endcase

    end


endmodule

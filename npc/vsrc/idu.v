`include "define.v"
module ysyx_24080020_IDU #(
    parameter WIDTH = 32
)(
    input [WIDTH-1:0] inst,
    output reg [6:0] opcode,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [WIDTH-1:0] imm,
    output reg [6:0] funct7

);

    wire [9:0] control;

    assign opcode = inst[6:0];
    assign rd = inst[11:7];
    assign funct3 = inst[14:12];
    assign rs1 = inst[19:15];
    assign rs2 = inst[24:20];

    always @(opcode or funct3) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                imm = {{20{1'b0}}, inst[`ysyx_24080020_IMM_I]};
            end

            default: imm = {WIDTH{1'b0}};
        endcase


    end



endmodule
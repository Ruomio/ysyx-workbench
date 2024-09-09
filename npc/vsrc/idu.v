`include "vsrc/define.v"
module ysyx_24080020_IDU (
    input [WIDTH-1:0] inst,
    output reg [6:0] opcode,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [19:0] imm,
    output reg [6:0] funct7

);
    import "DPI-C" function int ebreak();

    assign opcode = inst[`ysyx_24080020_OPCODE];
    assign rd = inst[`ysyx_24080020_RD];
    assign funct3 = inst[`ysyx_24080020_FUNCT3];
    assign rs1 = inst[`ysyx_24080020_RS1];
    assign rs2 = inst[`ysyx_24080020_RS2];

    always @(opcode or funct3) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                imm = {{8{inst[31]}}, inst[`ysyx_24080020_IMM_I]};
            end

            `ysyx_24080020_EBREAK: begin
                ebreak();
            end
            default: imm = {`ysyx_24080020_WIDTH{1'b0}};
        endcase


    end



endmodule
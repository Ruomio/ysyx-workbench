module ysyx_24080020_EXU #(
    parameter WIDTH = 32
)
(
    input [6:0] opcode,
    input [2:0] funct3,
    input [WIDTH-1:0] src1,
    input [WIDTH-1:0] src2,
    input [WIDTH-1:0] imm,
    input [6:0] funct7,
    output reg [WIDTH-1:0] result
);
    `include "define.v"


    always @(opcode or funct3) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                result <= src1 + imm;
            end

            default: ;
        endcase



    end


endmodule
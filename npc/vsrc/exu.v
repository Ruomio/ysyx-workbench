module ysyx_24080020_EXU 
(
    input [6:0] opcode,
    input [4:0] rd,
    input [2:0] funct3,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    input [`ysyx_24080020_WIDTH-1:0] imm,
    input [6:0] funct7,

    // out reg
    output [4:0] waddr,
    output reg[`ysyx_24080020_WIDTH-1:0] wdata,
    output reg wen,

    // out pc
    output reg [`ysyx_24080020_WIDTH-1:0] pc

    // out mem
);


    always @(opcode or funct3) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                case(funct3)
                    `ysyx_24080020_ADDI: begin
                        wdata <= val_raddr1 + imm;
                    end

                endcase
            end

            default: wdata <= 32'b0;
        endcase



    end


endmodule
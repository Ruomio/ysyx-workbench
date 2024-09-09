module ysyx_24080020_EXU 
(
    input [6:0] opcode,
    input [2:0] funct3,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    input [4:0] rd,
    input [`ysyx_24080020_WIDTH-1:0] imm,

    // out reg
    output reg [4:0] waddr,
    output reg[`ysyx_24080020_WIDTH-1:0] wdata,
    output reg wen,

    // out pc
    output reg [`ysyx_24080020_WIDTH-1:0] pc

    // out mem
);


    always @(*) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                case(funct3)
                    `ysyx_24080020_ADDI: begin
                        wdata = val_raddr1 + imm;
                        wen = 1'b1;
                        waddr = rd;
                    end

                default: wdata <= 0;

                endcase
            end

            default: wdata <= 32'b0;
        endcase



    end


endmodule
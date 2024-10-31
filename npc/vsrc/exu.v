`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_EXU
(
    input [`ysyx_24080020_WIDTH-1:0] inst,
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,

    input [`ysyx_24080020_WIDTH-1:0] pc,
    // reg
    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    input [4:0] rd,
    input [`ysyx_24080020_WIDTH-1:0] imm,

    // mrdata
    input [`ysyx_24080020_WIDTH-1:0] mrdata,

    // out reg
    output reg [4:0] waddr,
    output reg[`ysyx_24080020_WIDTH-1:0] wdata,
    output reg wen,

    // out pc
    output reg is_dnpc,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc,

    // out mem
    output reg [`ysyx_24080020_WIDTH-1:0] mraddr,
    output reg [`ysyx_24080020_WIDTH-1:0] mwaddr,
    output reg [`ysyx_24080020_WIDTH-1:0] mwdata,
    output reg mwen,
    output reg [3:0] mrlen,
    output reg [3:0] mwlen
);
    import "DPI-C" function void ebreak();
    import "DPI-C" function void invalid_inst();
    import "DPI-C" function void halt();
    import "DPI-C" function void update_ftrace_dpi();

    always @(inst or mrdata) begin
        // initial
        is_dnpc = 1'b0;
        mwen = 1'b0;
        wen = 1'b0;
        mraddr = 32'b0;
        mwaddr = 32'b0;
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                wen = 1'b1;
                waddr = rd;
                case(funct3)
                    `ysyx_24080020_ADDI: begin
                        wdata = val_raddr1 + imm;
                    end
                    `ysyx_24080020_SLTI: begin
                        wdata = $signed(val_raddr1) < $signed(imm) ? 32'b1 : 32'b0;
                    end
                    `ysyx_24080020_SLTIU: begin
                        wdata = val_raddr1 < imm ? 32'b1 : 32'b0;
                    end
                    `ysyx_24080020_XORI: begin
                        wdata = val_raddr1 ^ imm;
                    end
                    `ysyx_24080020_ORI: begin
                        wdata = val_raddr1 | imm;
                    end
                    `ysyx_24080020_ANDI: begin
                        wdata = val_raddr1 & imm;
                    end
                    `ysyx_24080020_SLLI: begin
                        wdata = val_raddr1 << imm[4:0];
                    end
                    `ysyx_24080020_SRI: begin
                        wdata = imm[10] == 0 ? val_raddr1 >> imm[4:0] : val_raddr1 >> imm[4:0] | ({32{val_raddr1[31]}} & ~(32'hffffffff >> imm[4:0]));
                    end

                    default: begin
                        wen = 1'b0;
                    end

                endcase
            end
            `ysyx_24080020_I_TYPEI: begin
                mraddr = val_raddr1 + imm;
                wen = 1'b1;
                waddr = rd;
                case(funct3)
                    `ysyx_24080020_LB: begin
                        wdata = {{24{mrdata[7]}}, mrdata[7:0]};
                        mrlen = 4'b001;
                    end
                    `ysyx_24080020_LH: begin
                        wdata = {{16{mrdata[15]}}, mrdata[15:0]};
                        mrlen = 4'b010;
                    end
                    `ysyx_24080020_LW: begin
                        wdata = mrdata;
                        mrlen = 4'b100;
                    end
                    `ysyx_24080020_LBU: begin
                        wdata = {{24{1'b0}}, mrdata[7:0]};
                        mrlen = 4'b001;
                    end
                    `ysyx_24080020_LHU: begin
                        wdata = {{16{1'b0}}, mrdata[15:0]};
                        mrlen = 4'b010;
                    end

                    default: begin
                        wen = 1'b0;
                        mraddr = 32'b0;
                    end

                endcase
            end

            `ysyx_24080020_R_TYPE: begin
                waddr = rd;
                wen = 1'b1;
                case(funct3)
                    `ysyx_24080020_ADD_SUB: begin
                        wdata = funct7[5] ==  0 ? val_raddr1 + val_raddr2 : val_raddr1 - val_raddr2;
                    end
                    `ysyx_24080020_SLL: begin
                        wdata = val_raddr1 << val_raddr2;
                    end
                    `ysyx_24080020_SLT: begin
                        wdata = $signed(val_raddr1) < $signed(val_raddr2) ? 32'b1 : 32'b0;
                    end
                    `ysyx_24080020_SLTU: begin
                        wdata = val_raddr1 < val_raddr2 ? 32'b1 : 32'b0;
                    end
                    `ysyx_24080020_XOR: begin
                        wdata = val_raddr1 ^ val_raddr2;
                    end
                    `ysyx_24080020_SRLA: begin
                        wdata = funct7[5] == 0 ? val_raddr1 >> val_raddr2 : val_raddr1 >> val_raddr2 | ({32{val_raddr1[31]}} & ~(32'hffffffff >> val_raddr2));
                    end
                    `ysyx_24080020_OR: begin
                        wdata = val_raddr1 | val_raddr2;
                    end
                    `ysyx_24080020_AND: begin
                        wdata = val_raddr1 & val_raddr2;
                    end
                    default: begin
                        wen = 1'b0;
                    end
                endcase

            end

            `ysyx_24080020_S_TYPE: begin
                mwen = 1'b1;
                case(funct3)
                    `ysyx_24080020_SB: begin
                        mwaddr = val_raddr1 + imm;
                        mwdata = {{24{1'b0}}, val_raddr2[7:0]};
                        mwlen = 4'b001;
                    end
                    `ysyx_24080020_SH: begin
                        mwaddr = val_raddr1 + imm;
                        mwdata = {{16{1'b0}}, val_raddr2[15:0]};
                        mwlen = 4'b010;
                    end
                    `ysyx_24080020_SW: begin
                        mwaddr = val_raddr1 + imm;
                        mwdata = val_raddr2;
                        mwlen = 4'b100;
                    end

                    default: mwen = 1'b0;
                endcase
            end

            `ysyx_24080020_B_TYPE: begin
                is_dnpc = 1'b1;
                case(funct3)
                    `ysyx_24080020_BEQ: begin
                        dnpc = val_raddr1 == val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BNE: begin
                        dnpc = val_raddr1 != val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BLT: begin
                        dnpc = $signed(val_raddr1) < $signed(val_raddr2) ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BGE: begin
                        dnpc = $signed(val_raddr1) >= $signed(val_raddr2) ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BLTU: begin
                        dnpc = val_raddr1 < val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BGEU: begin
                        dnpc = val_raddr1 >= val_raddr2 ? pc + imm : pc + 4;
                    end

                    default: begin
                        is_dnpc = 1'b0;
                    end
                endcase
            end

            `ysyx_24080020_CSR_TYPE: begin
                case(funct3)
                    `ysyx_24080020_ECALL_EBREAK: begin
                        if(imm == 32'b1)  ebreak();
                        else begin

                        end
                    end


                endcase
            end

            `ysyx_24080020_AUIPC: begin
                wdata = pc + imm;
                wen = 1'b1;
                waddr = rd;
            end
            `ysyx_24080020_LUI: begin
                wdata = imm;
                wen = 1'b1;
                waddr = rd;
            end
            `ysyx_24080020_JAL: begin
                update_ftrace_dpi();
                if(imm == 32'b0) begin
                    halt();
                end
                else begin
                    wdata = pc + 4;
                    wen = 1'b1;
                    waddr = rd;
                    dnpc = pc + imm;
                    is_dnpc = 1'b1;
                end
            end
            `ysyx_24080020_JALR: begin
                update_ftrace_dpi();
                wdata = pc + 4;
                wen = 1'b1;
                waddr = rd;
                dnpc = (val_raddr1 + imm)&{{31{1'b1}},1'b0};
                is_dnpc = 1'b1;
            end

            default: begin
                invaild_inst();
                wdata = 32'b0;
                wen = 1'b0;
                mwen = 1'b0;
            end
        endcase
    end


endmodule

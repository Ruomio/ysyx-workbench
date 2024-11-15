`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_EXU
(
    input clk,
    input [`ysyx_24080020_WIDTH-1:0] inst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [6:0] opcode,
    input [2:0] funct3,
    input [6:0] funct7,

    // alu
    input [`ysyx_24080020_WIDTH-1:0] alu_out,
    // axi
    input idu_exu_valid,
    input mem_exu_ready,
    // reg
    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    input [4:0] rd,
    input [`ysyx_24080020_WIDTH-1:0] imm,

    // csrs
    input [`ysyx_24080020_WIDTH-1:0] rcsrdata,

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
    output reg [3:0] mwlen,

    // alu
    output [3:0] alu_op,
    output [`ysyx_24080020_WIDTH-1:0] alu_src1,
    output [`ysyx_24080020_WIDTH-1:0] alu_src2,
    output [`ysyx_24080020_WIDTH-1:0] alu_pc,
    output [`ysyx_24080020_WIDTH-1:0] alu_shift,
    //csrs
    output reg wcsren,
    output reg[`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr,
    output reg[`ysyx_24080020_WIDTH-1:0] wcsrdata,
    output reg wcsren2,
    output reg[`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2,
    output reg[`ysyx_24080020_WIDTH-1:0] wcsrdata2,
    output reg[`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr,

    output reg exu_idu_ready,
    output reg exu_mem_valid
);
    import "DPI-C" function void ebreak();
    import "DPI-C" function void invalid_inst();
    import "DPI-C" function void halt();
    import "DPI-C" function void update_ftrace_dpi();

    reg state = 1'b0;   // 0:idle;   1:wait_ready

    always @(inst or mrdata or rcsrdata or alu_out) begin
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
                alu_src1 = val_raddr1;
                alu_src2 = imm;
                wdata = alu_out;
                case(funct3)
                    `ysyx_24080020_ADDI: begin
                        alu_op = `ysyx_24080020_ALU_ADD;
                    end
                    `ysyx_24080020_SLTI: begin
                        alu_op = `ysyx_24080020_ALU_SLT;
                    end
                    `ysyx_24080020_SLTIU: begin
                        alu_op = `ysyx_24080020_ALU_SLTU;
                    end
                    `ysyx_24080020_XORI: begin
                        alu_op = `ysyx_24080020_ALU_XOR;
                    end
                    `ysyx_24080020_ORI: begin
                        alu_op = `ysyx_24080020_ALU_OR;
                    end
                    `ysyx_24080020_ANDI: begin
                        alu_op = `ysyx_24080020_ALU_AND;
                    end
                    `ysyx_24080020_SLLI: begin
                        alu_op = `ysyx_24080020_ALU_SLL;
                    end
                    `ysyx_24080020_SRI: begin
                        alu_op = imm[10] == 0 ? `ysyx_24080020_ALU_SRL : `ysyx_24080020_ALU_SRA;
                    end

                    default: begin
                        wen = 1'b0;
                    end

                endcase
            end
            `ysyx_24080020_I_TYPEI: begin
                alu_op = `ysyx_24080020_ALU_ADD;
                alu_src1 = val_raddr1;
                alu_src2 = imm;
                mraddr = alu_out;
                // mraddr = val_raddr1 + imm;
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
                alu_src1 = val_raddr1;
                alu_src2 = val_raddr2;
                wdata = alu_out;
                waddr = rd;
                wen = 1'b1;
                case(funct3)
                    `ysyx_24080020_ADD_SUB: begin
                        alu_op = funct7[5] ==  0 ? `ysyx_24080020_ALU_ADD : `ysyx_24080020_ALU_SUB;
                    end
                    `ysyx_24080020_SLL: begin
                        alu_op = `ysyx_24080020_ALU_SLL;
                    end
                    `ysyx_24080020_SLT: begin
                        alu_op = `ysyx_24080020_ALU_SLT;
                    end
                    `ysyx_24080020_SLTU: begin
                        alu_op = `ysyx_24080020_ALU_SLTU;
                    end
                    `ysyx_24080020_XOR: begin
                        alu_op = `ysyx_24080020_ALU_XOR;
                    end
                    `ysyx_24080020_SRLA: begin
                        alu_op = funct7[5] == 0 ? `ysyx_24080020_ALU_SRL : `ysyx_24080020_ALU_SRA;
                    end
                    `ysyx_24080020_OR: begin
                        alu_op = `ysyx_24080020_ALU_OR;
                    end
                    `ysyx_24080020_AND: begin
                        alu_op = `ysyx_24080020_ALU_AND;
                    end
                    default: begin
                        wen = 1'b0;
                    end
                endcase

            end

            `ysyx_24080020_S_TYPE: begin
                alu_op = `ysyx_24080020_ALU_ADD;
                alu_src1 = val_raddr1;
                alu_src2 = imm;
                mwaddr = alu_out;
                mwen = 1'b1;
                case(funct3)
                    `ysyx_24080020_SB: begin
                        mwdata = {{24{1'b0}}, val_raddr2[7:0]};
                        mwlen = 4'b001;
                    end
                    `ysyx_24080020_SH: begin
                        mwdata = {{16{1'b0}}, val_raddr2[15:0]};
                        mwlen = 4'b010;
                    end
                    `ysyx_24080020_SW: begin
                        mwdata = val_raddr2;
                        mwlen = 4'b100;
                    end

                    default: mwen = 1'b0;
                endcase
            end

            `ysyx_24080020_B_TYPE: begin
                alu_src1 = val_raddr1;
                alu_src2 = val_raddr2;
                alu_pc = pc;
                alu_shift = imm;
                dnpc = alu_out;
                is_dnpc = 1'b1;
                case(funct3)
                    `ysyx_24080020_BEQ: begin
                        alu_op = `ysyx_24080020_ALU_BEQ;
                        // dnpc = val_raddr1 == val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BNE: begin
                        alu_op = `ysyx_24080020_ALU_BNE;
                        // dnpc = val_raddr1 != val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BLT: begin
                        alu_op = `ysyx_24080020_ALU_BLT;
                        // dnpc = $signed(val_raddr1) < $signed(val_raddr2) ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BGE: begin
                        alu_op = `ysyx_24080020_ALU_BGE;
                        // dnpc = $signed(val_raddr1) >= $signed(val_raddr2) ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BLTU: begin
                        alu_op = `ysyx_24080020_ALU_BLTU;
                        // dnpc = val_raddr1 < val_raddr2 ? pc + imm : pc + 4;
                    end
                    `ysyx_24080020_BGEU: begin
                        alu_op = `ysyx_24080020_ALU_BGEU;
                        // dnpc = val_raddr1 >= val_raddr2 ? pc + imm : pc + 4;
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
                        else if(imm == 32'b0) begin
                            // ecall
                            // csrs[mepc] = pc;
                            wcsraddr = `ysyx_24080020_MEPC_ADDR;
                            wcsrdata = pc;
                            wcsren = 1'b1;

                            // csrs[mcause] = R[a5];
                            wcsraddr2 = `ysyx_24080020_MCAUSE_ADDR;
                            wcsrdata2 = val_raddr1; 
                            wcsren2 = 1'b1;

                            // dnpc = rcsrdata;
                            rcsraddr = `ysyx_24080020_MTVEC_ADDR;
                            dnpc = rcsrdata;
                            is_dnpc = 1'b1;
                        end
                        else if(imm == 32'b1100000010) begin
                            // mret
                            rcsraddr = `ysyx_24080020_MEPC_ADDR;
                            dnpc = rcsrdata;
                            is_dnpc = 1'b1;
                        end
                        else begin
                            invalid_inst();
                        end
                    end
                    `ysyx_24080020_CSRRW: begin
                        wcsraddr = imm[11:0];
                        wcsrdata = val_raddr1;
                        wcsren = 1'b1;

                        rcsraddr = imm[11:0];

                        waddr = rd;
                        wdata = rcsrdata;
                        wen = 1'b1;
                    end
                    `ysyx_24080020_CSRRS: begin
                        rcsraddr = imm[11:0];

                        wcsraddr = imm[11:0];
                        alu_op = `ysyx_24080020_ALU_OR;
                        alu_src1 = val_raddr1;
                        alu_src2 = rcsrdata;
                        wcsrdata = alu_out;
                        // wcsrdata = val_raddr1 | rcsrdata;
                        wcsren = 1'b1;

                        waddr = rd;
                        wdata = rcsrdata;
                        wen = 1'b1;

                    end
                    default: begin
                        invalid_inst();
                    end
                endcase
            end

            `ysyx_24080020_AUIPC: begin
                alu_op = `ysyx_24080020_ALU_ADD;
                alu_src1 = pc;
                alu_src2 = imm;
                wdata = alu_out;
                // wdata = pc + imm;
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
                    alu_op = `ysyx_24080020_ALU_ADD;
                    alu_src1 = pc;
                    alu_src2 = imm;
                    dnpc = alu_out;
                    wdata = pc + 4;
                    wen = 1'b1;
                    waddr = rd;
                    // dnpc = pc + imm;
                    is_dnpc = 1'b1;
                end
            end
            `ysyx_24080020_JALR: begin
                update_ftrace_dpi();
                wdata = pc + 4;
                wen = 1'b1;
                waddr = rd;
                alu_op = `ysyx_24080020_ALU_ADD;
                alu_src1 = val_raddr1;
                alu_src2 = imm;
                dnpc = alu_out & {{31{1'b1}},1'b0};
                // dnpc = (val_raddr1 + imm)&{{31{1'b1}},1'b0};
                is_dnpc = 1'b1;
            end

            // rst
            7'b0000000 : begin
                wdata = 32'b0;
                wen = 1'b0;
                mwen = 1'b0;
            end
            default: begin
                invalid_inst();
                wdata = 32'b0;
                wen = 1'b0;
                mwen = 1'b0;
            end
        endcase
    end

    always @(posedge clk) begin
        if(idu_exu_valid) begin
            if(exu_mem_valid) exu_idu_ready <=  1'b0;
            else exu_idu_ready <= 1'b1;
        end
        else if(mem_exu_ready && mem_exu_ready && !state) begin
            exu_mem_valid <= 1'b0;
        end
        else begin
            exu_mem_valid <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(!state) begin
            if(exu_mem_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(mem_exu_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end


endmodule

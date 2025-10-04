`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IDU (
    input clk,
    input rst,
    // input data_adventure,
    input need_stall,
    input rs1_conflict,
    input rs2_conflict,
    input [`ysyx_24080020_WIDTH-1:0] rd_data1_forward,
    input [`ysyx_24080020_WIDTH-1:0] rd_data2_forward,

    input [`ysyx_24080020_WIDTH-1:0] inst_ifu,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr1,
    input [`ysyx_24080020_WIDTH-1:0] val_raddr2,
    // input [`ysyx_24080020_WIDTH-1:0] snpc_ifu,
    input [`ysyx_24080020_WIDTH-1:0] pc_ifu,
    input flush_pipeline,

    output reg [`ysyx_24080020_WIDTH-1:0] imm_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] branch_src1_idu,

    output reg is_ebreak,
    // reg
    output reg wen_idu,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] rs1,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] rs2,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] wdata_idu,
    output reg is_load_idu,
    output reg is_dnpc_idu,
    output reg is_jal_idu,
    output reg is_btype_idu,
    output reg is_jalr_idu,
    // output reg [2:0] is_btype_idu,
    output reg is_csrtype_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_idu,
    output reg fencei_idu,
    output reg skip_ref_idu,

    // csrs
    input [`ysyx_24080020_WIDTH-1:0] rcsrdata,
    output reg [2:0] rcsraddr_,
    output reg wcsren_idu,
    output reg [2:0] wcsraddr_idu_,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu,
    output reg wcsren2_idu,
    output reg [2:0] wcsraddr2_idu_,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu,

    // alu control
    output reg [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu,
    output reg alu_src2_con_idu,
    // output reg reg_dst_con_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] src1_idu,
    output reg [`ysyx_24080020_WIDTH-1:0] src2_idu,

    // memory
    output reg mren_idu,
    output reg mrtype_idu,
    output reg mwen_idu,
    output reg [3:0] mwmask_idu,
    output reg [3:0] mrlen_idu,


    input ifu_idu_valid,
    input exu_idu_ready,
    output reg idu_ifu_ready,
    output reg idu_exu_valid_reg

);
`ifdef CONFIG_DPIC
    // import "DPI-C" function void invalid_inst();
    // import "DPI-C" function void halt();
    import "DPI-C" function void update_ftrace_dpi();
    // import "DPI-C" function void statistics_idu_calculate_type();
    // import "DPI-C" function void statistics_idu_load_type();
    // import "DPI-C" function void statistics_idu_store_type();
    // import "DPI-C" function void statistics_idu_csr_type();
    // import "DPI-C" function void statistics_idu_jump_type();
`endif

    wire [6:0] opcode, funct7;
    wire [2:0] funct3;
    wire [`ysyx_24080020_REG_WIDTH-1:0] rd;


    // reg state; // 0: idle;    1: wait_ready

    reg [1:0] cnt;
    reg next_inst;


    reg idu_exu_valid;

    reg [`ysyx_24080020_WIDTH-1:0] inst_idu;

    reg [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_idu;
    reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_idu;

    assign opcode = inst_idu[`ysyx_24080020_OPCODE];
    assign rd = inst_idu[`ysyx_24080020_RD];
    assign funct3 = inst_idu[`ysyx_24080020_FUNCT3];
    assign rs1 = inst_idu == `ysyx_24080020_ECALL ? 'hf : inst_idu[`ysyx_24080020_RS1];
    assign rs2 = inst_idu[`ysyx_24080020_RS2];
    assign funct7 = inst_idu[`ysyx_24080020_FUNCT7];

    // assign idu_exu_valid_reg = idu_exu_valid && !data_adventure;
    assign idu_exu_valid_reg = idu_exu_valid && !need_stall;

    // always @(posedge clk) begin
    //     if(!rst) begin
    //         state <= 1'b0;
    //     end
    //     else if(!state) begin
    //         if(idu_exu_valid) state <= 1'b1;
    //         else state <= 1'b0;
    //     end
    //     else begin
    //         if(exu_idu_ready) state <= 1'b0;
    //         else begin
    //             state <= 1'b1;
    //         end
    //     end
    // end

    always @(posedge clk) begin
        if(!rst) begin
            next_inst <= 'b1;
        end
        else if(ifu_idu_valid && idu_ifu_ready) begin
            next_inst <= 'b0;
        end
        else if((idu_exu_valid_reg && exu_idu_ready) /* || flush_pipeline */ ) begin
            next_inst <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            idu_ifu_ready <= 'b0;
            pc_idu <= 'b0;
        end
        else if(ifu_idu_valid && idu_ifu_ready) begin
            idu_ifu_ready <= 1'b0;

            // update inst reg
            pc_idu <= pc_ifu;

        end
        else if(next_inst && ifu_idu_valid) begin
            idu_ifu_ready <= 1'b1;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            idu_exu_valid <= 1'b0;
        end
        else if(idu_exu_valid_reg && exu_idu_ready) begin
            idu_exu_valid <= 1'b0;
        end
        else if(need_stall) begin
            idu_exu_valid <= 1'b0;
        end
        else if(cnt == 'd2) begin
            if(!flush_pipeline && !next_inst) begin
                idu_exu_valid <= 1'b1;
            end
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            inst_idu <= 'b0;
        end
        else if(idu_exu_valid_reg && exu_idu_ready) begin
            inst_idu <= 'b0;
        end
        else if(ifu_idu_valid && idu_ifu_ready) begin
            inst_idu <= inst_ifu;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            cnt <= 'b0;
        end
        else if((idu_exu_valid_reg && exu_idu_ready) || flush_pipeline ) begin
            cnt <= 'b0;
        end
        else if(cnt == 'b10) begin
            if(need_stall || flush_pipeline) begin
                cnt <= 'b1;
            end
        end
        else if(cnt == 'b1) begin
            if(need_stall) begin
                cnt <= 'b1;
            end
            else if(flush_pipeline) begin
                cnt <= 'b0;
            end
            else begin
                cnt <= 'd2;
            end
        end
        else if(ifu_idu_valid && idu_ifu_ready) begin
            cnt <= 'b1;
        end
    end

    // csr addr transform
    always @(*) begin
        rcsraddr_ = 'b0;
        case(rcsraddr)
            `ysyx_24080020_MEPC_ADDR:     rcsraddr_ = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  rcsraddr_ = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   rcsraddr_ = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    rcsraddr_ = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: rcsraddr_ = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: rcsraddr_ = 3'd5;
            default: rcsraddr_ = 3'd7;
        endcase
    end
    always @(*) begin
        wcsraddr_idu_ = 'b0;
        case(wcsraddr_idu)
            `ysyx_24080020_MEPC_ADDR:     wcsraddr_idu_ = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsraddr_idu_ = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsraddr_idu_ = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsraddr_idu_ = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: wcsraddr_idu_ = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: wcsraddr_idu_ = 3'd5;
            default: wcsraddr_idu_ = 3'd7;
        endcase
    end

    always @(*) begin
        wcsraddr2_idu_ = 'b0;
        case(wcsraddr2_idu)
            `ysyx_24080020_MEPC_ADDR:     wcsraddr2_idu_ = 3'd0;
            `ysyx_24080020_MSTATUS_ADDR:  wcsraddr2_idu_ = 3'd1;
            `ysyx_24080020_MCAUSE_ADDR:   wcsraddr2_idu_ = 3'd2;
            `ysyx_24080020_MTVEC_ADDR:    wcsraddr2_idu_ = 3'd3;
            `ysyx_24080020_MVENDORID_ADDR: wcsraddr2_idu_ = 3'd4;
            `ysyx_24080020_MARCHID_ADDR: wcsraddr2_idu_ = 3'd5;
            default: wcsraddr2_idu_ = 3'd7;
        endcase
    end

    // always @(inst_idu or rs1 or rs2 or rcsrdata or val_raddr1 or val_raddr2 or ifu_idu_valid or rd_data1_forward or rd_data2_forward) begin
    always @(posedge clk) begin
        if(!rst) begin
            // initial
            imm_idu <= 'b0;

            // pc
            is_dnpc_idu <= 1'b0;
            is_load_idu <= 1'b0;
            is_jal_idu <= 1'b0;
            is_jalr_idu <= 1'b0;
            is_btype_idu <= 1'b0;
            dnpc_idu <= 'b0;
            branch_src1_idu <= 'b0;

            // mem
            mren_idu <= 1'b0;
            mwen_idu <= 1'b0;
            mren_idu <= 'b0;
            mrlen_idu <= 'b0;
            mrtype_idu <= 'b0;
            mwmask_idu <= 'b0;

            // reg
            wen_idu <= 1'b0;
            waddr_idu <= 'b0;
            wdata_idu <= 'b0;

            // csr
            is_csrtype_idu <= 1'b0;
            wcsren_idu <= 1'b0;
            wcsren2_idu <= 1'b0;
            rcsraddr <= 'b0;
            wcsraddr_idu <= 'b0;
            wcsrdata_idu <= 'b0;
            wcsraddr2_idu <= 'b0;
            wcsrdata2_idu <= 'b0;
            is_ebreak <= 'b0;

            // alu
            alu_src2_con_idu <= 'b0;
            alu_op_idu <= 'b0;
            src1_idu <= 'b0;
            src2_idu <= 'b0;

            // other
            fencei_idu <= 'b0;
            skip_ref_idu <= 1'b0;
            imm_idu <= 'd0;
        end
        else if(cnt == 'b0) begin
            // initial

            // pc
            is_dnpc_idu <= 1'b0;
            is_load_idu <= 1'b0;
            is_jal_idu <= 1'b0;
            is_jalr_idu <= 1'b0;
            is_btype_idu <= 1'b0;
            dnpc_idu <= 'b0;
            branch_src1_idu <= 'b0;

            // mem
            mren_idu <= 1'b0;
            mwen_idu <= 1'b0;
            mren_idu <= 'b0;
            mrlen_idu <= 'b0;
            mrtype_idu <= 'b0;
            mwmask_idu <= 'b0;

            // reg
            wen_idu <= 1'b0;
            waddr_idu <= 'b0;
            wdata_idu <= 'b0;

            // csr
            is_csrtype_idu <= 1'b0;
            wcsren_idu <= 1'b0;
            wcsren2_idu <= 1'b0;
            rcsraddr <= 'b0;
            wcsraddr_idu <= 'b0;
            wcsrdata_idu <= 'b0;
            wcsraddr2_idu <= 'b0;
            wcsrdata2_idu <= 'b0;
            is_ebreak <= 'b0;

            // alu
            alu_src2_con_idu <= 'b0;
            alu_op_idu <= 'b0;
            src1_idu <= 'b0;
            src2_idu <= 'b0;

            // other
            fencei_idu <= 'b0;
            skip_ref_idu <= 1'b0;
            imm_idu <= 'd0;
        end
        else if(cnt == 'b1) begin
            // step 1 assignment for B-type
            src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
            src2_idu <= rs2_conflict ? rd_data2_forward : val_raddr2;


            // step 1 assignment for CSR-type
            if(opcode == `ysyx_24080020_CSR_TYPE) begin
                case(funct3)
                    `ysyx_24080020_ECALL_EBREAK: begin
                        if(inst_idu[`ysyx_24080020_IMM_I] == 'b0) begin
                            // ecall
                            // csrs[mcause] <= R[a5];
                            wcsraddr2_idu <= `ysyx_24080020_MCAUSE_ADDR;
                            wcsrdata2_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;

                            // dnpc <= csrs[mtvec];
                            rcsraddr <= `ysyx_24080020_MTVEC_ADDR;
                        end
                        else if(inst_idu[`ysyx_24080020_IMM_I] == 'b1100000010) begin
                            // mret
                            rcsraddr <= `ysyx_24080020_MEPC_ADDR;
                        end
                    end

                    `ysyx_24080020_CSRRW: begin
                        rcsraddr <= inst_idu[`ysyx_24080020_IMM_I];
                    end
                    `ysyx_24080020_CSRRS: begin
                        rcsraddr <= inst_idu[`ysyx_24080020_IMM_I];
                    end
                    default: begin
                        is_csrtype_idu <= 1'b0;
                    end
                endcase
            end
        end
        else if(cnt == 'd2) begin

            case(opcode)
                `ysyx_24080020_I_TYPE: begin
                    imm_idu <= {{20{inst_idu[31]}}, inst_idu[`ysyx_24080020_IMM_I]};
                    alu_src2_con_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;

                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    src2_idu <= 32'b0;
                    alu_src2_con_idu <= 1'b1;
                    case(funct3)
                        `ysyx_24080020_ADDI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_ADD;
                        end
                        `ysyx_24080020_SLTI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLT;
                        end
                        `ysyx_24080020_SLTU: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLTU;
                        end
                        `ysyx_24080020_XORI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_XOR;
                        end
                        `ysyx_24080020_ORI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_OR;
                        end
                        `ysyx_24080020_ANDI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_AND;
                        end
                        `ysyx_24080020_SLLI: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLL;
                            wen_idu <= inst_idu[25] == 'b1 ? 'b0 : 'b1;
                        end
                        `ysyx_24080020_SRLAI: begin
                            alu_op_idu <= imm_idu[10] == 0 ? `ysyx_24080020_ALU_SRL : `ysyx_24080020_ALU_SRA;
                            wen_idu <= inst_idu[25] == 'b1 ? 'b0 : 'b1;
                        end

                        default: begin
                            wen_idu <= 1'b0;
                        end
                    endcase
                end

                `ysyx_24080020_I_TYPEI: begin
                    // load
                    imm_idu <= {{20{inst_idu[31]}}, inst_idu[`ysyx_24080020_IMM_I]};
                    alu_src2_con_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;

                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    src2_idu <= 32'b0;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                    is_load_idu <= 1'b1;

                    mren_idu <= 1'b1;

                    case(funct3)
                        `ysyx_24080020_LB: begin
                            mrlen_idu <= 4'b001;
                            mrtype_idu <= 1'b0;
                        end
                        `ysyx_24080020_LH: begin
                            mrlen_idu <= 4'b010;
                            mrtype_idu <= 1'b0;
                        end
                        `ysyx_24080020_LW: begin
                            mrlen_idu <= 4'b100;
                            mrtype_idu <= 1'b0;
                        end
                        `ysyx_24080020_LBU: begin
                            mrlen_idu <= 4'b001;
                            mrtype_idu <= 1'b1;
                        end
                        `ysyx_24080020_LHU: begin
                            mrlen_idu <= 4'b010;
                            mrtype_idu <= 1'b1;
                        end
                        default: begin
                            mren_idu <= 1'b0;
                            wen_idu <= 1'b0;
                        end

                    endcase
                end

                `ysyx_24080020_FENCEI_TYPE: begin
                case(funct3)
                    `ysyx_24080020_FENCEI: begin
                    fencei_idu <= 'b1;
                    `ifdef CONFIG_DPIC
                    // $display("fencei type.");
                    `endif
                    end
                    default: begin
                    end
                endcase
                end

                `ysyx_24080020_S_TYPE: begin
                    imm_idu <= {{20{inst_idu[31]}}, inst_idu[31:25], inst_idu[11:7]};
                    alu_src2_con_idu <= 1'b1;

                    wen_idu <= 1'b0;
                    mwen_idu <= 1'b1;

                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    // src2_idu <= rs2_conflict ? rd_data2_forward : val_raddr2;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                    case(funct3)
                        `ysyx_24080020_SB: begin
                            mwmask_idu <= 4'b1;
                        end
                        `ysyx_24080020_SH: begin
                            mwmask_idu <= 4'b10;
                        end
                        `ysyx_24080020_SW: begin
                            mwmask_idu <= 4'b100;
                        end
                        default: begin
                            mwmask_idu <= 4'b0;
                            mwen_idu <= 1'b0;
                        end

                    endcase
                end

                `ysyx_24080020_B_TYPE: begin
                    imm_idu <= {{20{inst_idu[31]}}, inst_idu[7], inst_idu[30:25], inst_idu[11:8], 1'b0};
                    alu_src2_con_idu <= 1'b1;

                    wen_idu <= 1'b0;
                    mwen_idu <= 1'b0;

                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    // src2_idu <= rs2_conflict ? rd_data2_forward : val_raddr2;

                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                    // is_dnpc_idu <= 1'b1;
                    is_btype_idu <= 1'b1;

                    case(funct3)
                        `ysyx_24080020_BEQ: begin
                            is_dnpc_idu <= src1_idu == src2_idu ? 1'b1 : 1'b0;
                        end
                        `ysyx_24080020_BNE: begin
                            is_dnpc_idu <= src1_idu != src2_idu ? 1'b1 : 1'b0;
                        end
                        `ysyx_24080020_BLT: begin
                            is_dnpc_idu <= $signed(src1_idu) < $signed(src2_idu) ? 1'b1 : 1'b0;
                        end
                        `ysyx_24080020_BGE: begin
                            is_dnpc_idu <= $signed(src1_idu) >= $signed(src2_idu) ? 1'b1 : 1'b0;
                        end
                        `ysyx_24080020_BLTU: begin
                            is_dnpc_idu <= src1_idu < src2_idu ? 1'b1 : 1'b0;
                        end
                        `ysyx_24080020_BGEU: begin
                            is_dnpc_idu <= src1_idu >= src2_idu ? 1'b1 : 1'b0;
                        end

                        default: begin
                        end

                    endcase


                end

                `ysyx_24080020_R_TYPE: begin
                    imm_idu <= 32'b0;
                    alu_src2_con_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;
                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    // src2_idu <= rs2_conflict ? rd_data2_forward : val_raddr2;
                    alu_src2_con_idu <= 1'b0;

                    case(funct3)
                        `ysyx_24080020_ADD_SUB:begin
                            alu_op_idu <= funct7[5] == 1'b0 ? `ysyx_24080020_ALU_ADD : `ysyx_24080020_ALU_SUB;
                        end
                        `ysyx_24080020_SLL: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLL;
                        end
                        `ysyx_24080020_SLT: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLT;
                        end
                        `ysyx_24080020_SLTU: begin
                            alu_op_idu <= `ysyx_24080020_ALU_SLTU;
                        end
                        `ysyx_24080020_XOR: begin
                            alu_op_idu <= `ysyx_24080020_ALU_XOR;
                        end
                        `ysyx_24080020_SRLA: begin
                            alu_op_idu <= funct7[5] == 1'b0 ? `ysyx_24080020_ALU_SRL : `ysyx_24080020_ALU_SRA;
                        end
                        `ysyx_24080020_OR: begin
                            alu_op_idu <= `ysyx_24080020_ALU_OR;
                        end
                        `ysyx_24080020_AND: begin
                            alu_op_idu <= `ysyx_24080020_ALU_AND;
                        end

                        default: begin
                            wen_idu <= 1'b0;
                        end

                    endcase


                end

                `ysyx_24080020_CSR_TYPE: begin
                    // imm_idu <= {{20{1'b0}}, inst_idu[`ysyx_24080020_IMM_I]};

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;

                    // rcsraddr <= inst_idu[`ysyx_24080020_IMM_I];

                    // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                    alu_src2_con_idu <= 1'b1;

                    is_csrtype_idu <= 1'b1;

                    case(funct3)
                        `ysyx_24080020_ECALL_EBREAK: begin
                            if(inst_idu[`ysyx_24080020_IMM_I] == 'b1) begin
                                is_ebreak <= 1;
                                // `ifdef CONFIG_DPIC
                                // ebreak();
                                // `endif
                            end
                            else if(inst_idu[`ysyx_24080020_IMM_I] == 'b0) begin
                                // ecall
                                // csrs[mepc] <= pc;
                                wcsraddr_idu <= `ysyx_24080020_MEPC_ADDR;
                                wcsrdata_idu <= pc_idu;
                                wcsren_idu <= 1'b1;

                                // csrs[mcause] <= R[a5];
                                wcsraddr2_idu <= `ysyx_24080020_MCAUSE_ADDR;
                                // wcsrdata2_idu <= val_raddr1;
                                wcsrdata2_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                                wcsren2_idu <= 1'b1;

                                // dnpc <= csrs[mtvec];
                                // rcsraddr <= `ysyx_24080020_MTVEC_ADDR;
                                dnpc_idu <= rcsrdata;

                                is_dnpc_idu <= 1'b1;

                                // skip_ref_idu <= 1'b1;
                                // `ifdef CONFIG_DPIC
                                // npc_difftest_skip_ref();
                                // `endif
                            end
                            else if(inst_idu[`ysyx_24080020_IMM_I] == 'b1100000010) begin
                                // mret
                                // rcsraddr <= `ysyx_24080020_MEPC_ADDR;
                                dnpc_idu <= rcsrdata;
                                is_dnpc_idu <= 1'b1;

                                // only M mode
                                // CSRS[mstatus] = 1800
                                wcsraddr_idu <= `ysyx_24080020_MSTATUS_ADDR;
                                wcsrdata_idu <= 'h1800;
                                wcsren_idu <= 'b1;

                                // todo: privilege mode
                                // 1. privivlege_mode_idu <= CSRS(MSTATUS)[12:11];
                                // 2. mstatus.mie = mstatus.mpie
                                //    CSRS(MSTATUS)[3] <= CSRS(MSTATUS)[7];
                                // 3. mstatus.mpie = 'b1;
                                //    CSRS(MSTATUS)[7] <= 'b1;
                                // 4. return user mode, mstatus.mpp = 2'b0
                                //    CSRS(MSTATUS)[12:11] <= 2'b0;

                            end
                            else begin
                                is_csrtype_idu <= 1'b0;
                            end
                        end

                        `ysyx_24080020_CSRRW: begin
                            wcsraddr_idu <= inst_idu[`ysyx_24080020_IMM_I];
                            // wcsrdata_idu <= val_raddr1;
                            wcsrdata_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                            wcsren_idu <= 1'b1;

                            // rcsraddr <= inst_idu[`ysyx_24080020_IMM_I];

                            waddr_idu <= rd;
                            wdata_idu <= rcsrdata;
                            wen_idu <= 1'b1;

                            // skip_ref_idu <= 1'b1;
                            // `ifdef CONFIG_DPIC
                            // npc_difftest_skip_ref();
                            // `endif
                        end
                        `ysyx_24080020_CSRRS: begin
                            // rcsraddr <= inst_idu[`ysyx_24080020_IMM_I];

                            wcsraddr_idu <= inst_idu[`ysyx_24080020_IMM_I];
                            wcsrdata_idu <= rcsrdata | src1_idu;
                            wcsren_idu <= 1'b1;

                            waddr_idu <= rd;
                            // src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;
                            wdata_idu <= rcsrdata;
                            wen_idu <= 1'b1;

                            // skip_ref_idu <= 1'b1;
                            // `ifdef CONFIG_DPIC
                            // npc_difftest_skip_ref();
                            // `endif
                        end

                        default: begin
                            is_csrtype_idu <= 1'b0;
                        end

                    endcase


                end

                `ysyx_24080020_JAL: begin
                    imm_idu <= {{12{inst_idu[31]}}, inst_idu[19:12], inst_idu[20], inst_idu[30:21], 1'b0};
                    is_dnpc_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;
                    src1_idu <= pc_idu;
                    src2_idu <= 32'b100;
                    alu_src2_con_idu <= 1'b0;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                    is_jal_idu <= 'b1;

                    `ifdef CONFIG_DPIC
                    update_ftrace_dpi();
                    `endif
                    if(imm_idu == 32'b0) begin
                        `ifdef CONFIG_DPIC
                        // halt();
                        `endif
                    end
                end

                `ysyx_24080020_JALR: begin
                    imm_idu <= {{20{inst_idu[31]}}, inst_idu[`ysyx_24080020_IMM_I]};
                    is_dnpc_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;
                    src1_idu <= pc_idu;
                    src2_idu <= 32'b100;
                    alu_src2_con_idu <= 1'b0;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                    // branch_src1_idu <= val_raddr1;
                    branch_src1_idu <= rs1_conflict ? rd_data1_forward : val_raddr1;

                    is_jalr_idu <= 1'b1;
                    // update_ftrace_dpi();
                end

                `ysyx_24080020_AUIPC: begin
                    imm_idu <= {inst_idu[`ysyx_24080020_IMM_U], {12{1'b0}}};
                    alu_src2_con_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;

                    src1_idu <= pc_idu;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;


                end
                `ysyx_24080020_LUI: begin
                    imm_idu <= {inst_idu[`ysyx_24080020_IMM_U], {12{1'b0}}};
                    alu_src2_con_idu <= 1'b1;

                    mwen_idu <= 1'b0;

                    wen_idu <= 1'b1;
                    waddr_idu <= rd;
                    // reg_dst_con_idu <= 1'b0;

                    src1_idu <= 32'b0;
                    alu_op_idu <= `ysyx_24080020_ALU_ADD;

                end

                // rst
                7'b0000000 : begin
                    imm_idu <= 32'b0;
                end

                default: begin
                    imm_idu <= 32'b0;
                    // `ifdef CONFIG_DPIC
                    // invalid_inst();
                    // `endif
                end
            endcase
        end
    end



endmodule

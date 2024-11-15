`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IDU (
    input clk,
    input ir_idu_valid,
    input exu_idu_ready,
    input [`ysyx_24080020_WIDTH-1:0] inst,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] funct3,
    output [4:0] rs1,
    output [4:0] rs2,
    output reg [`ysyx_24080020_WIDTH-1:0] imm,
    output [6:0] funct7,

    output idu_ir_ready,
    output idu_exu_valid

);
    reg state = 1'b0; // 0: idle;    1: wait_ready

    assign opcode = inst[`ysyx_24080020_OPCODE];
    assign rd = inst[`ysyx_24080020_RD];
    assign funct3 = inst[`ysyx_24080020_FUNCT3];
    assign rs1 = inst == `ysyx_24080020_ECALL ? 5'hf : inst[`ysyx_24080020_RS1];
    assign rs2 = inst[`ysyx_24080020_RS2];
    assign funct7 = inst[`ysyx_24080020_FUNCT7];


    always @(inst) begin

        case(opcode)
            `ysyx_24080020_I_TYPE, `ysyx_24080020_I_TYPEI: begin
                imm = {{20{inst[31]}}, inst[`ysyx_24080020_IMM_I]};
            end
            `ysyx_24080020_JALR: begin
                imm = {{20{inst[31]}}, inst[`ysyx_24080020_IMM_I]};
                // update_ftrace_dpi();
            end

            `ysyx_24080020_AUIPC, `ysyx_24080020_LUI: begin
                imm = {inst[`ysyx_24080020_IMM_U], {12{1'b0}}};
            end

            `ysyx_24080020_JAL: begin
                imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
                // update_ftrace_dpi();
                // if(imm == 32'b0) begin
                //     halt();
                // end
            end

            `ysyx_24080020_S_TYPE: begin
                imm = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            end

            `ysyx_24080020_B_TYPE: begin
                imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
            end

            `ysyx_24080020_R_TYPE: begin
                imm = 32'b0;
            end

            `ysyx_24080020_CSR_TYPE: begin
                imm = {{20{1'b0}}, inst[`ysyx_24080020_IMM_I]};
            end

            // rst
            7'b0000000 : begin
                imm = 32'b0;
            end
            /* `ysyx_24080020_EBREAK: begin
                imm = 32'b0;
                ebreak();
            end */

            default: begin
                imm = 32'b0;
                // invalid_inst();
            end
        endcase
    end

    always @(posedge clk) begin
        if(!state) begin
            if(idu_exu_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(exu_idu_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(ir_idu_valid) begin
            if(idu_exu_valid) idu_ir_ready <= 1'b0;
            else idu_ir_ready <= 1'b1;
        end
        else if(exu_idu_ready && exu_idu_ready && !state) begin
            idu_exu_valid <= 1'b0;
        end
        else begin
            idu_exu_valid <= 1'b1;
            idu_ir_ready <= 1'b0;
        end

    end


endmodule

`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IDU (
    input [`ysyx_24080020_WIDTH-1:0] inst,
    output [6:0] opcode,
    output [4:0] rd,
    output [2:0] funct3,
    output [4:0] rs1,
    output [4:0] rs2,
    output reg [`ysyx_24080020_WIDTH-1:0] imm,
    output [6:0] funct7

);
    import "DPI-C" function void ebreak();
    import "DPI-C" function void invalid_inst();
    import "DPI-C" function void halt();
    import "DPI-C" function void update_ftrace_dpi();

    assign opcode = inst[`ysyx_24080020_OPCODE];
    assign rd = inst[`ysyx_24080020_RD];
    assign funct3 = inst[`ysyx_24080020_FUNCT3];
    assign rs1 = inst[`ysyx_24080020_RS1];
    assign rs2 = inst[`ysyx_24080020_RS2];
    assign funct7 = inst[`ysyx_24080020_FUNCT7];


    always @(*) begin

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
endmodule

`include "vsrc/define.v"
module ysyx_24080020_IDU (
    input [`ysyx_24080020_WIDTH-1:0] inst,
    output reg [6:0] opcode,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [`ysyx_24080020_WIDTH-1:0] imm,
    output reg [6:0] funct7

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

    reg [6:0] last_opcode;

    always @(*) begin
        case(opcode)
            `ysyx_24080020_I_TYPE: begin
                imm = {{20{inst[31]}}, inst[`ysyx_24080020_IMM_I]};
            end
            `ysyx_24080020_JALR: begin
                imm = {{20{inst[31]}}, inst[`ysyx_24080020_IMM_I]};
                if(last_opcode != `ysyx_24080020_JALR) begin
                    update_ftrace_dpi();
                end
            end

            `ysyx_24080020_AUIPC, `ysyx_24080020_LUI: begin
                imm = {inst[`ysyx_24080020_IMM_U], {12{1'b0}}};
            end

            `ysyx_24080020_JAL: begin
                imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
                if(last_opcode != `ysyx_24080020_JAL) begin
                    update_ftrace_dpi();
                end
                if(imm == 32'b0) begin
                    halt();
                end
            end

            `ysyx_24080020_S_TYPE: begin
                imm = {inst[31:25], {25{1'b0}}};
            end

            7'b0000000 : begin
                // rst
                imm = 32'b0;
            end
            `ysyx_24080020_EBREAK: begin
                imm = 32'b0;
                ebreak();
            end

            default: begin
                last_opcode = opcode;
                imm = 32'b0;
                invalid_inst();
            end
        endcase


    end



endmodule
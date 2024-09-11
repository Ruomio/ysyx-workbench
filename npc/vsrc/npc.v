`include "vsrc/define.v"
module ysyx_24080020_NPC(
    input clk,
    input rst,
    output [31:0] pc
);

    reg [`ysyx_24080020_WIDTH-1:0] snpc;

    // inst
    reg [`ysyx_24080020_WIDTH-1:0] inst;
    reg [6:0] opcode;
    reg [4:0] rd;
    reg [2:0] funct3;
    reg [4:0] rs1;
    reg [4:0] rs2;
    reg [`ysyx_24080020_WIDTH-1:0] imm;
    reg [6:0] funct7;


    // register
    reg wen;
    reg [4:0] waddr;
    reg [`ysyx_24080020_WIDTH-1:0] wdata;
    reg [`ysyx_24080020_WIDTH-1:0] src1;
    reg [`ysyx_24080020_WIDTH-1:0] src2;

    // memory
    reg mwen;
    reg [3:0] mlen;
    reg [`ysyx_24080020_WIDTH-1:0] maddr;
    reg [`ysyx_24080020_WIDTH-1:0] mdata;
    reg [`ysyx_24080020_WIDTH-1:0] mrdata;


    assign pc = snpc;

    ysyx_24080020_MEM u_mem(.clk(clk), .rst(rst), .maddr(maddr), .mlen(mlen), .mdata(mdata), .wen(mwen), .mrdata(inst));
    
    ysyx_24080020_IFU ifu(.clk(clk), .rst(rst), .pc(pc), .len(`ysyx_24080020_LEN), .snpc(snpc), .maddr(maddr), .mlen(mlen));

    ysyx_24080020_IDU idu(.inst(inst), .opcode(opcode), .rd(rd), .funct3(funct3), .rs1(rs1), .rs2(rs2), .imm(imm), .funct7(funct7));

    ysyx_24080020_REG u_reg(.clk(clk), .rst(rst), .raddr1(rs1), .raddr2(rs2), .wen(wen), .waddr(waddr), .wdata(wdata), .val_raddr1(src1), .val_raddr2(src2));

    ysyx_24080020_EXU exu(.opcode(opcode), .funct3(funct3), .val_raddr1(src1), .val_raddr2(src2), .rd(rd), .imm(imm), .waddr(waddr), .wdata(wdata), .wen(wen), .pc(snpc));


endmodule

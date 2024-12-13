`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_NPC(
    input clk,
    input rst
);

  // pc
  wire [`ysyx_24080020_WIDTH-1:0] pc_ifu, pc_idu;
  wire [`ysyx_24080020_WIDTH-1:0] dnpc_idu, dnpc_new_exu, dnpc_mem, dnpc_wb;
  wire is_dnpc_idu, is_dnpc_exu, is_dnpc_mem, is_dnpc_wb;
  wire is_jalr_idu;

  // inst
  wire if_en;
  wire [`ysyx_24080020_WIDTH-1:0] inst_ifu, inst_idu;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [`ysyx_24080020_WIDTH-1:0] imm_idu, imm_exu;

  wire is_load_idu, is_load_exu, is_load_mem, is_load_wb;
  wire alu_src2_con_idu, alu_src2_con_exu;
  wire [`ysyx_24080020_WIDTH-1:0] branch_src1_idu;
  // wire reg_dst_con_idu, reg_dst_con_exu;


  // reg
  wire wen_idu, wen_exu, wen_mem, wen_wb;
  wire [4:0] waddr_idu, waddr_exu, waddr_mem, waddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_idu, wdata_exu, wdata_mem, wdata_wb;
  wire [`ysyx_24080020_WIDTH-1:0] src1_idu, src1_exu;
  wire [`ysyx_24080020_WIDTH-1:0] src2_idu, src2_exu, src2_mem;
  wire [`ysyx_24080020_WIDTH-1:0] val_raddr1, val_raddr2;
  // csrs
  wire is_csrtype_idu;
  wire wcsren_idu, wcsren_exu, wcsren_mem, wcsren_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_idu, wcsraddr_exu, wcsraddr_mem, wcsraddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu, wcsrdata_exu, wcsrdata_mem, wcsrdata_wb;
  wire wcsren2_idu, wcsren2_exu, wcsren2_mem, wcsren2_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_idu, wcsraddr2_exu, wcsraddr2_mem, wcsraddr2_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu, wcsrdata2_exu, wcsrdata2_mem, wcsrdata2_wb;
  wire [`ysyx_24080020_CSR_WIDTH-1:0] rcsraddr;
  wire [`ysyx_24080020_WIDTH-1:0] rcsrdata;

  // memory
  wire mwen_idu, mwen_exu, mwen_mem;
  wire mren_idu, mren_exu, mren_mem;
  wire mrtype_idu, mrtype_exu, mrtype_mem;
  wire [3:0] mrlen_idu, mrlen_exu, mrlen_mem, mrlen_wb;
  wire [3:0] mwmask_idu, mwmask_exu, mwmask_mem, mwmask_wb;
  wire [`ysyx_24080020_WIDTH-1:0] mraddr_exu, mraddr_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mwaddr_exu, mwaddr_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mwdata_exu, mwdata_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mrdata_exu, mrdata_mem, mrdata_wb;

  // alu
  wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu, alu_op_exu;
  wire [`ysyx_24080020_WIDTH-1:0] alu_out_exu, alu_out_mem;

  // bus control
  wire ifu_idu_valid;
  wire idu_ifu_ready;
  // idu -> exu
  wire idu_exu_valid;
  wire exu_idu_ready;
  // exu -> mem
  wire exu_mem_valid;
  wire mem_exu_ready;
  // mem -> reg
  wire mem_wb_valid;
  wire wb_mem_ready;
  // WB -> IFU
  wire wb_ifu_valid;
  wire ifu_wb_ready;

  // Arbiter
  wire arvalid_ifu, arready_ifu;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_ifu;
  wire rready_ifu, rvalid_ifu;
  wire [1:0] rresp_ifu;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_ifu;

  wire arvalid_mem, arready_mem;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_mem;
  wire rready_mem, rvalid_mem;
  wire [1:0] rresp_mem;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_mem;
  wire [`ysyx_24080020_WIDTH-1:0] awaddr_mem;
  wire awvalid_mem;
  wire awready_mem;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_axi_mem;
  wire [3:0] wstrb_mem;
  wire wvalid_mem;
  wire wready_mem;
  wire bvalid_mem, bready_mem;
  wire [1:0] bresp_mem;

  wire arvalid_arbiter, arready_xbar;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_arbiter;
  wire rvalid_xbar, rready_arbiter;
  wire [1:0] rresp_xbar;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_xbar, awaddr_arbiter;
  wire awvalid_arbiter, awready_xbar;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_arbiter;
  wire [3:0] wstrb_arbiter;
  wire wvalid_arbiter, wready_xbar;
  wire bvalid_xbar, bready_arbiter;
  wire [1:0] bresp_xbar;

  // Xbar
  wire arvalid_xbar_sram, arready_sram,
        arvalid_xbar_uart, arready_uart,
        arvalid_xbar_clint, arready_clint;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_xbar_sram,
                                  araddr_xbar_uart,
                                  araddr_xbar_clint;

  wire rvalid_sram, rready_xbar_sram,
        rvalid_uart, rready_xbar_uart,
        rvalid_clint, rready_xbar_clint;
  wire [1:0] rresp_sram, rresp_uart, rresp_clint;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_sram, rdata_uart, rdata_clint;

  wire awvalid_xbar_sram, awready_sram,
        awvalid_xbar_uart, awready_uart,
        awready_clint, awvalid_xbar_clint;
  wire [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_sram, awaddr_xbar_uart, awaddr_xbar_clint;

  wire wvalid_xbar_sram, wready_sram,
       wvalid_xbar_uart, wready_uart
       wvalid_xbar_clint, wready_clint;
  wire [3:0] wstrb_xbar_sram, wstrb_xbar_uart, wstrb_xbar_clint;
  wire [31:0] wdata_xbar_sram, wdata_xbar_uart, wdata_xbar_clint;

  wire bvalid_sram, bready_xbar_sram,
       bvalid_uart,  bready_xbar_uart
       bvalid_clint, bready_xbar_clint;
  wire [1:0] bresp_sram, bresp_uart, bresp_clint;




    ysyx_24080020_IFU ifu(
        .clk(clk),
        .rst(rst),
        .dnpc_wb(dnpc_wb),
        .is_dnpc_wb(is_dnpc_wb),
        .pc_ifu(pc_ifu),
        .inst_ifu(inst_ifu),
        .if_en(if_en),

        // axi-lite
        .arvalid(arvalid_ifu),
        .araddr(araddr_ifu),
        .arready(arready_ifu),

        .rvalid(rvalid_ifu),
        .rresp(rresp_ifu),
        .rdata(rdata_ifu),
        .rready(rready_ifu),

        .wb_ifu_valid(wb_ifu_valid),
        .idu_ifu_ready(idu_ifu_ready),
        .ifu_idu_valid(ifu_idu_valid),
        .ifu_wb_ready(ifu_wb_ready)
    );

    ysyx_24080020_IDU idu(
        .clk(clk),
        .rst(rst),
        .inst_ifu(inst_ifu),
        .rs1(rs1),
        .rs2(rs2),
        .val_raddr1(val_raddr1),
        .val_raddr2(val_raddr2),
        .pc_ifu(pc_ifu),
        .imm_idu(imm_idu),
        .branch_src1_idu(branch_src1_idu),
        .wen_idu(wen_idu),
        .waddr_idu(waddr_idu),
        .wdata_idu(wdata_idu),
        .is_load_idu(is_load_idu),
        .is_dnpc_idu(is_dnpc_idu),
        .is_jalr_idu(is_jalr_idu),
        .is_csrtype_idu(is_csrtype_idu),
        .dnpc_idu(dnpc_idu),

        .rcsrdata(rcsrdata),
        .rcsraddr(rcsraddr),
        .wcsren_idu(wcsren_idu),
        .wcsraddr_idu(wcsraddr_idu),
        .wcsrdata_idu(wcsrdata_idu),
        .wcsren2_idu(wcsren2_idu),
        .wcsraddr2_idu(wcsraddr2_idu),
        .wcsrdata2_idu(wcsrdata2_idu),

        .alu_op_idu(alu_op_idu),
        .alu_src2_con_idu(alu_src2_con_idu),
        .pc_idu(pc_idu),
        .src1_idu(src1_idu),
        .src2_idu(src2_idu),

        .mren_idu(mren_idu),
        .mrtype_idu(mrtype_idu),
        .mrlen_idu(mrlen_idu),
        .mwen_idu(mwen_idu),
        .mwmask_idu(mwmask_idu),

        .ifu_idu_valid(ifu_idu_valid),
        .exu_idu_ready(exu_idu_ready),
        .idu_exu_valid(idu_exu_valid),
        .idu_ifu_ready(idu_ifu_ready)
    );

    ysyx_24080020_REG u_reg(
        .clk(clk),
        .rst(rst),
        .raddr1(rs1),
        .raddr2(rs2),

        .is_load_mem(is_load_mem),
        .is_dnpc_mem(is_dnpc_mem),
        .is_dnpc_wb(is_dnpc_wb),
        .dnpc_mem(dnpc_mem),
        .dnpc_wb(dnpc_wb),

        .wen_mem(wen_mem),
        .waddr_mem(waddr_mem),
        .mrdata_mem(mrdata_mem),
        .alu_out_mem(alu_out_mem),

        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),
        .wcsren2_mem(wcsren2_mem),
        .wcsraddr2_mem(wcsraddr2_mem),
        .wcsrdata2_mem(wcsrdata2_mem),

        .val_raddr1(val_raddr1),
        .val_raddr2(val_raddr2),
        .rcsraddr(rcsraddr),
        .rcsrdata(rcsrdata),

        .mem_wb_valid(mem_wb_valid),
        .ifu_wb_ready(ifu_wb_ready),
        .wb_mem_ready(wb_mem_ready),
        .wb_ifu_valid(wb_ifu_valid)
    );

    ysyx_24080020_EXU exu(
        .clk(clk),
        .rst(rst),
        .pc_idu(pc_idu),
        .imm_idu(imm_idu),
        .is_load_idu(is_load_idu),
        .is_load_exu(is_load_exu),

        .is_jalr_idu(is_jalr_idu),
        .is_dnpc_idu(is_dnpc_idu),
        .branch_src1_idu(branch_src1_idu),
        .dnpc_idu(dnpc_idu),
        .is_dnpc_exu(is_dnpc_exu),
        .dnpc_new_exu(dnpc_new_exu),

        .alu_src2_con_idu(alu_src2_con_idu),
        .src1_idu(src1_idu),
        .src2_idu(src2_idu),
        .alu_op_idu(alu_op_idu),
        .alu_out_exu(alu_out_exu),

        // reg
        .wen_idu(wen_idu),
        .waddr_idu(waddr_idu),
        .wdata_idu(wdata_idu),
        .wen_exu(wen_exu),
        .waddr_exu(waddr_exu),

        //memory
        .mwen_idu(mwen_idu),
        .mwmask_idu(mwmask_idu),
        .mren_idu(mren_idu),
        .mrtype_idu(mrtype_idu),
        .mrlen_idu(mrlen_idu),
        .mwen_exu(mwen_exu),
        .mwmask_exu(mwmask_exu),
        .mren_exu(mren_exu),
        .mrtype_exu(mrtype_exu),
        .mrlen_exu(mrlen_exu),
        .mraddr_exu(mraddr_exu),
        .mwaddr_exu(mwaddr_exu),
        .mwdata_exu(mwdata_exu),

        // csrs
        .is_csrtype_idu(is_csrtype_idu),
        .wcsren_idu(wcsren2_idu),
        .wcsraddr_idu(wcsraddr_idu),
        .wcsrdata_idu(wcsrdata_idu),
        .wcsren2_idu(wcsren2_idu),
        .wcsraddr2_idu(wcsraddr2_idu),
        .wcsrdata2_idu(wcsrdata2_idu),
        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),
        .wcsren2_exu(wcsren2_exu),
        .wcsraddr2_exu(wcsraddr2_exu),
        .wcsrdata2_exu(wcsrdata2_exu),


        .idu_exu_valid(idu_exu_valid),
        .mem_exu_ready(mem_exu_ready),
        .exu_mem_valid(exu_mem_valid),
        .exu_idu_ready(exu_idu_ready)
    );


    ysyx_24080020_MEM u_mem(
        .clk(clk),
        .rst(rst),
        .mren_exu(mren_exu),
        .mrtype_exu(mrtype_exu),
        .mrlen_exu(mrlen_exu),
        .mwen_exu(mwen_exu),
        .mwmask_exu(mwmask_exu),
        .mraddr_exu(mraddr_exu),
        .mwaddr_exu(mwaddr_exu),
        .mwdata_exu(mwdata_exu),
        .mrdata_mem(mrdata_mem),

        .alu_out_exu(alu_out_exu),
        .alu_out_mem(alu_out_mem),

        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),
        .wcsren2_exu(wcsren2_exu),
        .wcsraddr2_exu(wcsraddr2_exu),
        .wcsrdata2_exu(wcsrdata2_exu),
        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),
        .wcsren2_mem(wcsren2_mem),
        .wcsraddr2_mem(wcsraddr2_mem),
        .wcsrdata2_mem(wcsrdata2_mem),

        .wen_exu(wen_exu),
        .waddr_exu(waddr_exu),
        .wen_mem(wen_mem),
        .waddr_mem(waddr_mem),

        .is_load_exu(is_load_exu),
        .is_load_mem(is_load_mem),

        .dnpc_new_exu(dnpc_new_exu),
        .dnpc_mem(dnpc_mem),
        .is_dnpc_exu(is_dnpc_exu),
        .is_dnpc_mem(is_dnpc_mem),

        // axi-lite
        .arvalid(arvalid_mem),
        .araddr(araddr_mem),
        .arready(arready_mem),

        .rready(rready_mem),
        .rvalid(rvalid_mem),
        .rresp(rresp_mem),
        .rdata(rdata_mem),

        .awvalid(awvalid_mem),
        .awaddr(awaddr_mem),
        .awready(awready_mem),

        .wvalid(wvalid_mem),
        .wstrb(wstrb_mem),
        .wdata(wdata_axi_mem),
        .wready(wready_mem),

        .bready(bready_mem),
        .bvalid(bvalid_mem),
        .bresp(bresp_mem),

        .exu_mem_valid(exu_mem_valid),
        .wb_mem_ready(wb_mem_ready),
        .mem_exu_ready(mem_exu_ready),
        .mem_wb_valid(mem_wb_valid)
    );

    ysyx_24080020_ARBITER u_arbiter(
        .clk(clk),
        .rst(rst),

        // master-1 ifu
        .arvalid_ifu(arvalid_ifu),
        .araddr_ifu(araddr_ifu),
        .arready_ifu(arready_ifu),

        .rready_ifu(rready_ifu),
        .rdata_ifu(rdata_ifu),
        .rresp_ifu(rresp_ifu),
        .rvalid_ifu(rvalid_ifu),

        // master-2 mem
        .arvalid_mem(arvalid_mem),
        .araddr_mem(araddr_mem),
        .arready_mem(arready_mem),

        .rready_mem(rready_mem),
        .rdata_mem(rdata_mem),
        .rresp_mem(rresp_mem),
        .rvalid_mem(rvalid_mem),

        .awaddr_mem(awaddr_mem),
        .awvalid_mem(awvalid_mem),
        .awready_arbiter(awready_mem),

        .wdata_mem(wdata_axi_mem),
        .wstrb_mem(wstrb_mem),
        .wvalid_mem(wvalid_mem),
        .wready_arbiter(wready_mem),

        .bresp_arbiter(bresp_mem),
        .bvalid_arbiter(bvalid_mem),
        .bready_mem(bready_mem),

        // arbiter deside
        .arvalid_arbiter(arvalid_arbiter),
        .araddr_arbiter(araddr_arbiter),
        .arready_xbar(arready_xbar),

        .rdata_xbar(rdata_xbar),
        .rresp_xbar(rresp_xbar),
        .rvalid_xbar(rvalid_xbar),
        .rready_arbiter(rready_arbiter),

        .awaddr_arbiter(awaddr_arbiter),
        .awvalid_arbiter(awvalid_arbiter),
        .awready_xbar(awready_xbar),

        .wdata_arbiter(wdata_arbiter),
        .wstrb_arbiter(wstrb_arbiter),
        .wvalid_arbiter(wvalid_arbiter),
        .wready_xbar(wready_xbar),

        .bresp_xbar(bresp_xbar),
        .bvalid_xbar(bvalid_xbar),
        .bready_arbiter(bready_arbiter)
    );

    ysyx_24080020_XBAR u_xbar(
        .clk(clk),
        .rst(rst),

        // arbiter -> xbar
        .arvalid_arbiter(arvalid_arbiter),
        .araddr_arbiter(araddr_arbiter),
        .arready_xbar(arready_xbar),

        .rdata_xbar(rdata_xbar),
        .rresp_xbar(rresp_xbar),
        .rvalid_xbar(rvalid_xbar),
        .rready_arbiter(rready_arbiter),

        .awaddr_arbiter(awaddr_arbiter),
        .awvalid_arbiter(awvalid_arbiter),
        .awready_xbar(awready_xbar),

        .wdata_arbiter(wdata_arbiter),
        .wstrb_arbiter(wstrb_arbiter),
        .wvalid_arbiter(wvalid_arbiter),
        .wready_xbar(wready_xbar),

        .bready_arbiter(bready_arbiter),
        .bvalid_xbar(bvalid_xbar),
        .bresp_xbar(bresp_xbar),

        // xbar -> sram
        .arvalid_xbar_sram(arvalid_xbar_sram),
        .araddr_xbar_sram(araddr_xbar_sram),
        .arready_sram(arready_sram),

        .rdata_sram(rdata_sram),
        .rresp_sram(rresp_sram),
        .rvalid_sram(rvalid_sram),
        .rready_xbar_sram(rready_xbar_sram),

        .awaddr_xbar_sram(awaddr_xbar_sram),
        .awvalid_xbar_sram(awvalid_xbar_sram),
        .awready_sram(awready_sram),

        .wdata_xbar_sram(wdata_xbar_sram),
        .wstrb_xbar_sram(wstrb_xbar_sram),
        .wvalid_xbar_sram(wvalid_xbar_sram),
        .wready_sram(wready_sram),

        .bvalid_sram(bvalid_sram),
        .bresp_sram(bresp_sram),
        .bready_xbar_sram(bready_xbar_sram),

        // xbar -> uart
        .arvalid_xbar_uart(arvalid_xbar_uart),
        .araddr_xbar_uart(araddr_xbar_uart),
        .arready_uart(arready_uart),

        .rdata_uart(rdata_uart),
        .rresp_uart(rresp_uart),
        .rvalid_uart(rvalid_uart),
        .rready_xbar_uart(rready_xbar_uart),

        .awaddr_xbar_uart(awaddr_xbar_uart),
        .awvalid_xbar_uart(awvalid_xbar_uart),
        .awready_uart(awready_uart),

        .wdata_xbar_uart(wdata_xbar_uart),
        .wstrb_xbar_uart(wstrb_xbar_uart),
        .wvalid_xbar_uart(wvalid_xbar_uart),
        .wready_uart(wready_uart),

        .bvalid_uart(bvalid_uart),
        .bresp_uart(bresp_uart),
        .bready_xbar_uart(bready_xbar_uart),

        // xbar -> clint
        .arvalid_xbar_clint(arvalid_xbar_clint),
        .araddr_xbar_clint(araddr_xbar_clint),
        .arready_clint(arready_clint),

        .rdata_clint(rdata_clint),
        .rresp_clint(rresp_clint),
        .rvalid_clint(rvalid_clint),
        .rready_xbar_clint(rready_xbar_clint),

        .awaddr_xbar_clint(awaddr_xbar_clint),
        .awvalid_xbar_clint(awvalid_xbar_clint),
        .awready_clint(awready_clint),

        .wdata_xbar_clint(wdata_xbar_clint),
        .wstrb_xbar_clint(wstrb_xbar_clint),
        .wvalid_xbar_clint(wvalid_xbar_clint),
        .wready_clint(wready_clint),

        .bvalid_clint(bvalid_clint),
        .bresp_clint(bresp_clint),
        .bready_xbar_clint(bready_xbar_clint)
    );

    ysyx_24080020_UART u_uart(
        .clk(clk),
        .rst(rst),

        .araddr(araddr_xbar_uart),
        .arvalid(arvalid_xbar_uart),
        .arready(arready_uart),

        .rdata(rdata_uart),
        .rresp(rresp_uart),
        .rvalid(rvalid_uart),
        .rready(rready_xbar_uart),

        .awaddr(awaddr_xbar_uart),
        .awvalid(awvalid_xbar_uart),
        .awready(awready_uart),

        .wdata(wdata_xbar_uart),
        .wstrb(wstrb_xbar_uart),
        .wvalid(wvalid_xbar_uart),
        .wready(wready_uart),

        .bready(bready_xbar_uart),
        .bresp(bresp_uart),
        .bvalid(bvalid_uart)
    );

    ysyx_24080020_SRAM u_sram(
        .clk(clk),
        .rst(rst),

        .arvalid(arvalid_xbar_sram),
        .araddr(araddr_xbar_sram),
        .arready(arready_sram),

        .rdata(rdata_sram),
        .rresp(rresp_sram),
        .rvalid(rvalid_sram),
        .rready(rready_xbar_sram),

        .awaddr(awaddr_xbar_sram),
        .awvalid(awvalid_xbar_sram),
        .awready(awready_sram),

        .wdata(wdata_xbar_sram),
        .wstrb(wstrb_xbar_sram),
        .wvalid(wvalid_xbar_sram),
        .wready(wready_sram),

        .bresp(bresp_sram),
        .bvalid(bvalid_sram),
        .bready(bready_xbar_sram)
    );

    ysyx_24080020_CLINT u_clint(
        .clk(clk),
        .rst(rst),

        .arvalid(arvalid_xbar_clint),
        .araddr(araddr_xbar_clint),
        .arready(arready_clint),

        .rdata(rdata_clint),
        .rresp(rresp_clint),
        .rvalid(rvalid_clint),
        .rready(rready_xbar_clint),

        .awaddr(awaddr_xbar_clint),
        .awvalid(awvalid_xbar_clint),
        .awready(awready_clint),

        .wdata(wdata_xbar_clint),
        .wstrb(wstrb_xbar_clint),
        .wvalid(wvalid_xbar_clint),
        .wready(wready_clint),

        .bresp(bresp_clint),
        .bvalid(bvalid_clint),
        .bready(bready_xbar_clint)
    );

endmodule

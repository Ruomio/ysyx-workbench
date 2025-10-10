`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_NPC(
    input clk,
    input rst,

    // master
    // AR
    input io_master_arready,
    output io_master_arvalid,
    output [31:0] io_master_araddr,
    output [3:0] io_master_arid,
    output [7:0] io_master_arlen,
    output [2:0] io_master_arsize,
    output [1:0] io_master_arburst,
    // R
    output io_master_rready,
    input io_master_rvalid,
    input [1:0] io_master_rresp,
    input [31:0] io_master_rdata,
    input io_master_rlast,
    input [3:0] io_master_rid,
    // AW
    input io_master_awready,
    output io_master_awvalid,
    output [31:0] io_master_awaddr,
    output [3:0] io_master_awid,
    output [7:0] io_master_awlen,
    output [2:0] io_master_awsize,
    output [1:0] io_master_awburst,
    // W
    input io_master_wready,
    output io_master_wvalid,
    output [31:0] io_master_wdata,
    output [3:0] io_master_wstrb,
    output io_master_wlast,
    // B
    output io_master_bready,
    input io_master_bvalid,
    input [1:0] io_master_bresp,
    input [3:0] io_master_bid,

    // slave
    // AR
    output io_slave_arready,
    input io_slave_arvalid,
    input [31:0] io_slave_araddr,
    input [3:0] io_slave_arid,
    input [7:0] io_slave_arlen,
    input [2:0] io_slave_arsize,
    input [1:0] io_slave_arburst,
    // R
    input io_slave_rready,
    output io_slave_rvalid,
    output [1:0] io_slave_rresp,
    output [31:0] io_slave_rdata,
    output io_slave_rlast,
    output [3:0] io_slave_rid,
    // AW
    output io_slave_awready,
    input io_slave_awvalid,
    input [31:0] io_slave_awaddr,
    input [3:0] io_slave_awid,
    input [7:0] io_slave_awlen,
    input [2:0] io_slave_awsize,
    input [1:0] io_slave_awburst,
    // W
    output io_slave_wready,
    input io_slave_wvalid,
    input [31:0] io_slave_wdata,
    input [3:0] io_slave_wstrb,
    input io_slave_wlast,
    // B
    input io_slave_bready,
    output io_slave_bvalid,
    output [1:0] io_slave_bresp,
    output [3:0] io_slave_bid
);

  // pc
  wire [`ysyx_24080020_WIDTH-1:0] pc_ifu, pc_idu, pc_exu, pc_lsu, pc_wbu;
  wire [`ysyx_24080020_WIDTH-1:0] dnpc_exu, dnpc_mem;
  wire branch_taken_exu, branch_taken_lsu, branch_taken_wbu,
        branch_not_taken_exu;

  // inst
  wire [`ysyx_24080020_WIDTH-1:0] inst_ifu;
  wire [`ysyx_24080020_WIDTH-1:0] imm_idu, imm_exu;

  wire alu_src2_con_idu, alu_src2_con_exu;
  wire [`ysyx_24080020_WIDTH-1:0] branch_src1_idu;
  // wire reg_dst_con_idu, reg_dst_con_exu;


  // reg
  wire wen_idu, wen_exu, wen_mem, wen_wb;
  wire [`ysyx_24080020_REG_WIDTH-1:0] rs1, rs2, waddr_idu, waddr_exu, waddr_mem, waddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_idu, wdata_exu, wdata_mem, wdata_wb;
  wire [`ysyx_24080020_WIDTH-1:0] src1_idu, src1_exu;
  wire [`ysyx_24080020_WIDTH-1:0] src2_idu, src2_exu, src2_mem;
  wire [`ysyx_24080020_WIDTH-1:0] val_raddr1, val_raddr2, val_raddr1_idu, val_raddr2_idu;
  wire [`ysyx_24080020_WIDTH-1:0] rd_data_wb;
  // csrs
  wire is_csrtype_idu;
  wire wcsren_idu, wcsren_exu, wcsren_mem, wcsren_wb;
  wire [2:0] wcsraddr_idu, wcsraddr_exu, wcsraddr_mem, wcsraddr_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata_idu, wcsrdata_exu, wcsrdata_mem, wcsrdata_wb;
  wire wcsren2_idu, wcsren2_exu, wcsren2_mem, wcsren2_wb;
  wire [2:0] wcsraddr2_idu, wcsraddr2_exu, wcsraddr2_mem, wcsraddr2_wb;
  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata2_idu, wcsrdata2_exu, wcsrdata2_mem, wcsrdata2_wb;
  wire [2:0] rcsraddr;
  wire [`ysyx_24080020_WIDTH-1:0] rcsrdata;

  // memory
  wire mwen_idu, mwen_exu, mwen_mem;
  wire mren_idu, mren_exu, mren_mem;
  wire mrtype_idu, mrtype_exu, mrtype_mem;
  wire [3:0] mrlen_idu, mrlen_exu, mrlen_mem, mrlen_wb;
  wire [3:0] mwmask_idu, mwmask_exu, mwmask_mem, mwmask_wb;
  wire [`ysyx_24080020_WIDTH-1:0] maddr_exu;
  wire [`ysyx_24080020_WIDTH-1:0] mwaddr_exu, mwaddr_mem;
  wire [`ysyx_24080020_WIDTH-1:0] mwdata_exu, mwdata_mem;
  wire [`ysyx_24080020_WIDTH-1:0] rd_data_mem, mrdata_mem;

  // alu
  wire [`ysyx_24080020_ALU_OP_WIDTH-1:0] alu_op_idu, alu_op_exu;
  wire [`ysyx_24080020_WIDTH-1:0] alu_out_exu, alu_out_mem;
  wire [`ysyx_24080020_WIDTH-1:0] alu_src1, alu_src2, alu_out;
  wire alu_zero;

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
  wire [1:0] arburst_ifu;
  wire [2:0] arsize_ifu;
  wire [3:0] arid_ifu;
  wire [7:0] arlen_ifu;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_ifu;
  wire rready_ifu, rvalid_ifu;
  wire [1:0] rresp_ifu;
  wire rlast_ifu;
  wire [3:0] rid_ifu;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_ifu, raddr_ifu, raddr_ir, raddr_icache;

  wire arvalid_icache, arready_icache;
  wire [1:0] arburst_icache;
  wire [2:0] arsize_icache;
  wire [3:0] arid_icache;
  wire [7:0] arlen_icache;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_icache;
  wire rready_icache, rvalid_icache;
  wire [1:0] rresp_icache;
  wire rlast_icache;
  wire [3:0] rid_icache;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_icache;

  wire arvalid_mem, arready_mem;
  wire [1:0] arburst_mem;
  wire [2:0] arsize_mem;
  wire [3:0] arid_mem;
  wire [7:0] arlen_mem;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_mem;
  wire rready_mem, rvalid_mem;
  wire [1:0] rresp_mem;
  wire rlast_mem;
  wire [3:0] rid_mem;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_mem;
  wire [`ysyx_24080020_WIDTH-1:0] awaddr_mem;
  wire awvalid_mem;
  wire awready_mem;
  wire [1:0] awburst_mem;
  wire [2:0] awsize_mem;
  wire [3:0] awid_mem;
  wire [7:0] awlen_mem;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_axi_mem;
  wire [3:0] wstrb_mem;
  wire wvalid_mem;
  wire wready_mem;
  wire wlast_mem;
  wire bvalid_mem, bready_mem;
  wire [1:0] bresp_mem;
  wire [3:0] bid_mem;

  wire arvalid_arbiter, arready_xbar;
  wire [1:0] arburst_arbiter;
  wire [2:0] arsize_arbiter;
  wire [3:0] arid_arbiter;
  wire [7:0] arlen_arbiter;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_arbiter;
  wire rvalid_xbar, rready_arbiter;
  wire [1:0] rresp_xbar;
  wire rlast_xbar;
  wire [3:0] rid_xbar;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_xbar, awaddr_arbiter;
  wire awvalid_arbiter, awready_xbar;
  wire [1:0] awburst_arbiter;
  wire [2:0] awsize_arbiter;
  wire [3:0] awid_arbiter;
  wire [7:0] awlen_arbiter;
  wire [`ysyx_24080020_WIDTH-1:0] wdata_arbiter;
  wire wlast_arbiter;
  wire [3:0] wstrb_arbiter;
  wire wvalid_arbiter, wready_xbar;
  wire bvalid_xbar, bready_arbiter;
  wire [3:0] bid_xbar;
  wire [1:0] bresp_xbar;

  wire special_pc_pc, special_pc_i, special_pc_ir_o, special_pc_ir, special_pc_icache;

  // Xbar
  wire arvalid_xbar_sram, arready_sram,
        arvalid_xbar_uart, arready_uart,
        arvalid_xbar_clint, arready_clint,
        arvalid_xbar_i, arready_soc_i;
  wire [1:0] arburst_xbar_clint, arburst_xbar_soc,
              arburst_xbar_i;
  wire [2:0] arsize_xbar_clint, arsize_xbar_soc,
              arsize_xbar_i;
  wire [3:0] arid_xbar_clint, arid_xbar_soc,
              arid_xbar_i;
  wire [7:0] arlen_xbar_clint, arlen_xbar_soc,
              arlen_xbar_i;
  wire [`ysyx_24080020_WIDTH-1:0] araddr_xbar_sram,
                                  araddr_xbar_uart,
                                  araddr_xbar_clint,
                                  araddr_xbar_i;
  `ifdef ysyx_24080020_NPC
  wire [3:0] arid_xbar_sram, arid_xbar_uart;
  wire [7:0] arlen_xbar_sram, arlen_xbar_uart;
  wire [2:0] arsize_xbar_sram, arsize_xbar_uart;
  wire [1:0] arburst_xbar_sram, arburst_xbar_uart;
  `endif

  wire rvalid_sram, rready_xbar_sram,
        rvalid_uart, rready_xbar_uart,
        rvalid_clint, rready_xbar_clint,
        rready_xbar_i,
        rvalid_soc_i;
  wire rlast_clint, rlast_soc,
        rlast_soc_i;
  wire [3:0] rid_clint, rid_soc,
             rid_soc_i;
  wire [1:0] rresp_sram, rresp_uart, rresp_clint,
             rresp_soc_i;
  wire [`ysyx_24080020_WIDTH-1:0] rdata_sram, rdata_uart, rdata_clint,
                                  rdata_soc_i;
  `ifdef ysyx_24080020_NPC
  wire [3:0] rid_sram, rid_uart;
  wire rlast_sram, rlast_uart;
  `endif

  wire awvalid_xbar_sram, awready_sram,
        awvalid_xbar_uart, awready_uart,
        awready_clint, awvalid_xbar_clint,
        awvalid_xbar_i, awready_soc_i;
  wire [1:0] awburst_xbar_clint, awburst_xbar_soc,
              awburst_xbar_i;
  wire [2:0] awsize_xbar_clint, awsize_xbar_soc,
              awsize_xbar_i;
  wire [3:0] awid_xbar_clint, awid_xbar_soc,
              awid_xbar_i;
  wire [7:0] awlen_xbar_clint, awlen_xbar_soc,
              awlen_xbar_i;
  wire [`ysyx_24080020_WIDTH-1:0] awaddr_xbar_sram, awaddr_xbar_uart, awaddr_xbar_clint,
                                  awaddr_xbar_i;
  `ifdef ysyx_24080020_NPC
  wire [3:0] awid_xbar_sram, awid_xbar_uart;
  wire [7:0] awlen_xbar_sram, awlen_xbar_uart;
  wire [2:0] awsize_xbar_sram, awsize_xbar_uart;
  wire [1:0] awburst_xbar_sram, awburst_xbar_uart;
  `endif

  wire wvalid_xbar_sram, wready_sram,
       wvalid_xbar_uart, wready_uart,
       wvalid_xbar_clint, wready_clint,
       wvalid_xbar_i, wready_soc_i;
  wire wlast_xbar_clint, wlast_xbar_soc,
        wlast_xbar_i;
  wire [3:0] wstrb_xbar_sram, wstrb_xbar_uart, wstrb_xbar_clint,
              wstrb_xbar_i;
  wire [31:0] wdata_xbar_sram, wdata_xbar_uart, wdata_xbar_clint,
              wdata_xbar_i;
  `ifdef ysyx_24080020_NPC
  wire wlast_xbar_sram, wlast_xbar_uart;
  `endif

  wire bvalid_sram, bready_xbar_sram,
       bvalid_uart,  bready_xbar_uart,
       bvalid_clint, bready_xbar_clint,
       bvalid_soc_i,
       bready_xbar_i;
  wire [3:0] bid_clint,
             bid_soc_i;
  wire [1:0] bresp_sram, bresp_uart, bresp_clint,
             bresp_soc_i;
  `ifdef ysyx_24080020_NPC
  wire [3:0] bid_sram, bid_uart;
  `endif

  // pipeline hazard
  wire structural_adventure, data_adventure, control_adventure;
  wire inst_fin;
  wire lsu_busy, lsu_busy_unused;
  wire exu_mem_shake_hands;
  wire idu_exu_shake_hands;
  wire update_pc, flush_pipeline, need_flush_pipeline;
  wire dnpc_en, get_right_inst;
  wire btype_n_jump_btb;


  `ifdef CONFIG_DPIC
  // skip difftest ref
  wire skip_ref_mem;
  `endif

  // forward
  wire [`ysyx_24080020_WIDTH-1:0] rd_data1_forward;
  wire [`ysyx_24080020_WIDTH-1:0] rd_data2_forward;
  wire rs1_conflict;
  wire rs2_conflict;
  wire need_stall;

  // flatten ifu
  wire inst_fin_valid, inst_fin_ready;
  wire if_en_valid, if_en_ready;
  wire [`ysyx_24080020_WIDTH-1:0] addr_pc, inst_ir;

  // BTB
  wire special_pc_btb, valid_btb, ready_btb;
  wire [`ysyx_24080020_WIDTH-1:0] pc_btb, correct_pc_btb;


    ysyx_24080020_BTB u_btb(
        .clk(clk),
        .rst(rst),

        .pc_exu(pc_exu),
        // .is_dnpc(is_dnpc_exu),
        .is_dnpc(branch_taken_exu),
        .dnpc(dnpc_exu),
        // .is_btype(is_btype_exu),
        .branch_not_taken_exu(branch_not_taken_exu),

        .pc(pc_btb),
        .correct_pc(correct_pc_btb),
        .out_special_pc(special_pc_btb),
        .flush_pipeline(need_flush_pipeline),

        .update_pc(arvalid_ifu && arready_ifu),

        // fence.i
        // .fencei_exu(fencei_exu),
        // .fencei_mem(fencei_mem),

        // bus
        .out_valid(valid_btb),
        .out_ready(ready_btb)
    );

    ysyx_24080020_PC u_pc(
        .clk(clk),
        .rst(rst),

        // btb <-> pc
        .in_valid(valid_btb),
        .in_ready(ready_btb),
        .in_pc(pc_btb),
        .in_special_pc(special_pc_btb),


        // pc <-> ir
        .special_pc(special_pc_pc),
        .if_en_valid(if_en_valid),
        .if_en_ready(if_en_ready),
        .addr(addr_pc)
    );

    ysyx_24080020_IR u_ir(
        .clk(clk),
        .rst(rst),

        // pc <-> ir
        .special_pc_i(special_pc_pc),
        .if_en_valid(if_en_valid),
        .if_en_ready(if_en_ready),
        .addr(addr_pc),

        // ir <-> ifu
        .inst(inst_ir),
        .inst_fin_valid(inst_fin_valid),
        .inst_fin_ready(inst_fin_ready),

        // icache -> ir
        .raddr_icache(raddr_icache),
        .special_pc_icache(special_pc_icache),
        .raddr_ir(raddr_ir),
        .special_pc_ir(special_pc_ir),

        .special_pc_o(special_pc_ir_o),
        // axi-lite
        .arvalid(arvalid_ifu),
        .araddr(araddr_ifu),
        .arburst(arburst_ifu),
        .arsize(arsize_ifu),
        .arid(arid_ifu),
        .arlen(arlen_ifu),
        .arready(arready_ifu),

        .rvalid(rvalid_ifu),
        .rlast(rlast_ifu),
        .rid(rid_ifu),
        .rresp(rresp_ifu),
        .rdata(rdata_ifu),
        .rready(rready_ifu)
    );

    ysyx_24080020_IFU u_ifu(
        .clk(clk),
        .rst(rst),

        .inst(inst_ir),
        .pc_ifu(pc_ifu),
        .inst_ifu(inst_ifu),

        .inst_fin(inst_fin),
        .flush_pipeline(flush_pipeline),
        .raddr(raddr_ir),
        .special_pc_i(special_pc_ir),
        .need_flush_pipeline(need_flush_pipeline),

        .correct_pc_btb(correct_pc_btb),
        .inst_fin_valid(inst_fin_valid),
        .inst_fin_ready(inst_fin_ready),

        .idu_ifu_ready(idu_ifu_ready),
        .ifu_idu_valid(ifu_idu_valid)
    );

    wire is_branch_idu, is_ecall_idu, is_jalr_idu, is_jal_idu, is_load_idu, is_store_idu,
        is_csr_idu, fencei_idu, is_ebreak_idu;
    wire [2:0] mem_len_idu, mem_wmask_idu;
    wire [31:0] rcsrdata_idu;

    ysyx_24080020_IDU u_idu(
		.clk(clk),
		.rst(rst),
        // IFU <---> IDU
		.inst_ifu(inst_ifu),
		.pc_ifu(pc_ifu),
		.ifu_idu_valid(ifu_idu_valid),
		.idu_ifu_ready(idu_ifu_ready),
        // IDU <---> EXU
		.idu_exu_valid(idu_exu_valid),
		.exu_idu_ready(exu_idu_ready),
		.flush_pipeline(flush_pipeline),
		.need_stall(need_stall),
		.pc_idu(pc_idu),

        // REGFILE 2 read 1 write
		.rs1(rs1),
		.rs2(rs2),
		.val_raddr1(rd_data1_forward),
		.val_raddr2(rd_data2_forward),
		.waddr_idu(waddr_idu),
		.wen_idu(wen_idu),
		.val_raddr1_idu(val_raddr1_idu),
		.val_raddr2_idu(val_raddr2_idu),

        // CSR 1 read 1 write
		.rcsraddr(rcsraddr),
		.rcsrdata(rcsrdata),
		.wcsren_idu(wcsren_idu),
		.wcsraddr_idu(wcsraddr_idu),
		.wcsrdata_idu(wcsrdata_idu),
		.rcsrdata_idu(rcsrdata_idu),
		// .wcsren2_idu(wcsren2_idu),
		// .wcsraddr2_idu(wcsraddr2_idu),
		// .wcsrdata2_idu(wcsrdata2_idu),

        // other control signal
        .is_ecall_idu(is_ecall_idu),
		.is_ebreak_idu(is_ebreak_idu),
		.alu_op_idu(alu_op_idu),
		.imm_idu(imm_idu),
		.is_branch_idu(is_branch_idu),
		.is_jal_idu(is_jal_idu),
		.is_jalr_idu(is_jalr_idu),
		.is_load_idu(is_load_idu),
		.is_store_idu(is_store_idu),
		.is_csr_idu(is_csr_idu),
		.fencei_idu(fencei_idu),
		.mem_len_idu(mem_len_idu),
		.mem_wmask_idu(mem_wmask_idu)
    );

    ysyx_24080020_ALU u_alu(
        .alu_op(alu_op_exu),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_out(alu_out),
        .alu_zero(alu_zero)
    );

    wire is_jal_exu, is_jalr_exu, is_store_exu, is_load_exu
         , is_ebreak_exu, is_ecall_exu, fencei_exu;
    wire [2:0] mem_len_exu, mem_wmask_exu;
    wire [31:0] store_data_exu, mem_addr_exu;

    ysyx_24080020_EXU u_exu(
        .clk(clk),
        .rst(rst),

        // idu <-> exu
        .idu_exu_valid(idu_exu_valid),
        .mem_exu_ready(mem_exu_ready),
        // exu <-> lsu
        .pc_exu(pc_exu),
        .exu_mem_valid(exu_mem_valid),
        .exu_idu_ready(exu_idu_ready),


        .pc_idu(pc_idu),
        .imm_idu(imm_idu),
        .alu_op_idu(alu_op_idu),
        .is_ecall_idu(is_ecall_idu),
        .is_ebreak_idu(is_ebreak_idu),
		.is_branch_idu(is_branch_idu),
		.is_jal_idu(is_jal_idu),
		.is_jalr_idu(is_jalr_idu),
		.is_load_idu(is_load_idu),
		.is_store_idu(is_store_idu),
		.is_csr_idu(is_csr_idu),
		.fencei_idu(fencei_idu),
		.mem_len_idu(mem_len_idu),
		.mem_wmask_idu(mem_wmask_idu),

		// reg
        .wen_idu(wen_idu),
        .waddr_idu(waddr_idu),
        .val_raddr1_idu(val_raddr1_idu),
        .val_raddr2_idu(val_raddr2_idu),
        // csr
        .wcsren_idu(wcsren_idu),
        .wcsraddr_idu(wcsraddr_idu),
        .wcsrdata_idu(wcsrdata_idu),


        // .alu_result_exu(alu_result_exu),
        .dnpc_exu(dnpc_exu),
        .branch_taken_exu(branch_taken_exu),
        .branch_not_taken_exu(branch_not_taken_exu),
        .is_ebreak_exu(is_ebreak_exu),
        .is_ecall_exu(is_ecall_exu),
		.is_load_exu(is_load_exu),
		.is_store_exu(is_store_exu),
		// .is_csr_exu(is_csr_exu),
		.fencei_exu(fencei_exu),
		.mem_len_exu(mem_len_exu),
		.mem_wmask_exu(mem_wmask_exu),
		.store_data_exu(store_data_exu),
		.mem_addr_exu(mem_addr_exu),

        .wen_exu(wen_exu),
        .waddr_exu(waddr_exu),
        .wdata_exu(wdata_exu),

        // csrs
        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),
        // .wcsren2_exu(wcsren2_exu),
        // .wcsraddr2_exu(wcsraddr2_exu),
        // .wcsrdata2_exu(wcsrdata2_exu),

        .alu_op_exu(alu_op_exu),
        .alu_src1(alu_src1),
        .alu_src2(alu_src2),
        .alu_result(alu_out),
        .alu_zero(alu_zero)


        // other control signal idu -> exu

    );


    ysyx_24080020_LSU u_lsu(
        .clk(clk),
        .rst(rst),

        `ifdef CONFIG_DPIC
        .skip_ref_mem(skip_ref_mem),

        .pc_exu(pc_exu),
        .pc_mem(pc_lsu),

        .is_dnpc_exu(branch_taken_exu),
        .is_dnpc_mem(branch_taken_lsu),

        .dnpc_new_exu(dnpc_exu),
        .dnpc_mem(dnpc_mem),
        `endif

        // exu <-> lsu
        .exu_mem_valid(exu_mem_valid),
        .wb_mem_ready(wb_mem_ready),
        .mem_exu_ready(mem_exu_ready),
        .mem_wb_valid(mem_wb_valid),

        // Load Store
        .mren_exu(is_load_exu),
        .mrlen_exu(mem_len_exu),
        .mwen_exu(is_store_exu),
        .mwmask_exu(mem_wmask_exu),
        .maddr_exu(mem_addr_exu),
        .mwdata_exu(store_data_exu),
        .mren_mem(mren_mem),

        // CSR
        .wcsren_exu(wcsren_exu),
        .wcsraddr_exu(wcsraddr_exu),
        .wcsrdata_exu(wcsrdata_exu),

        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),

        // REG
        .wen_exu(wen_exu),
        .waddr_exu(waddr_exu),
        .wdata_exu(wdata_exu),
        .wen_mem(wen_mem),
        .waddr_mem(waddr_mem),
        .wdata_mem(wdata_mem),

        // axi-lite
        .arvalid_reg(arvalid_mem),
        .araddr(araddr_mem),
        .arid(arid_mem),
        .arlen(arlen_mem),
        .arsize(arsize_mem),
        .arburst(arburst_mem),
        .arready(arready_mem),

        .rready(rready_mem),
        .rvalid(rvalid_mem),
        .rresp(rresp_mem),
        .rid(rid_mem),
        .rlast(rlast_mem),
        .rdata(rdata_mem),

        .awvalid_reg(awvalid_mem),
        .awid(awid_mem),
        .awlen(awlen_mem),
        .awsize(awsize_mem),
        .awburst(awburst_mem),
        .awaddr(awaddr_mem),
        .awready(awready_mem),

        .wvalid_reg(wvalid_mem),
        .wstrb(wstrb_mem),
        .wdata(wdata_axi_mem),
        .wlast(wlast_mem),
        .wready(wready_mem),

        .bready(bready_mem),
        .bvalid(bvalid_mem),
        .bid(bid_mem),
        .bresp(bresp_mem)
    );

    ysyx_24080020_REG u_reg(
        .clk(clk),
        .rst(rst),

        `ifdef CONFIG_DPIC
        .skip_ref_mem(skip_ref_mem),
        .pc_lsu(pc_lsu),
        .pc_wbu(pc_wbu),
        .is_dnpc_mem(branch_taken_lsu),
        .dnpc_mem(dnpc_mem),
        `endif

        .raddr1(rs1),
        .raddr2(rs2),

        .wen_mem(wen_mem),
        .waddr_mem(waddr_mem),
        .wdata_mem(wdata_mem),
        // .rd_data_mem(rd_data_mem),

        .waddr_wb(waddr_wb),
        .wdata_wb(wdata_wb),
        .wen_wb(wen_wb),

        .val_raddr1(val_raddr1),
        .val_raddr2(val_raddr2),

        .mem_wb_valid(mem_wb_valid),
        .wb_mem_ready(wb_mem_ready)
    );

    ysyx_24080020_CSR u_csr(
        .clk(clk),
        .rst(rst),

        .wcsren_mem(wcsren_mem),
        .wcsraddr_mem(wcsraddr_mem),
        .wcsrdata_mem(wcsrdata_mem),

        .rcsraddr(rcsraddr),
        .rcsrdata(rcsrdata),

        .mem_wb_valid(mem_wb_valid),
        .wb_mem_ready(wb_mem_ready)
    );

    ysyx_24080020_ARBITER u_arbiter(
        .clk(clk),
        .rst(rst),

        // master-1 ifu
        .arvalid_ifu(arvalid_icache),
        .araddr_ifu(araddr_icache),
        .arid_ifu(arid_icache),
        .arlen_ifu(arlen_icache),
        .arsize_ifu(arsize_icache),
        .arburst_ifu(arburst_icache),
        .arready_ifu(arready_icache),

        .rready_ifu(rready_icache),
        .rid_ifu(rid_icache),
        .rlast_ifu(rlast_icache),
        .rdata_ifu(rdata_icache),
        .rresp_ifu(rresp_icache),
        .rvalid_ifu(rvalid_icache),

        // master-2 mem
        .arvalid_mem(arvalid_mem),
        .araddr_mem(araddr_mem),
        .arid_mem(arid_mem),
        .arlen_mem(arlen_mem),
        .arsize_mem(arsize_mem),
        .arburst_mem(arburst_mem),
        .arready_mem(arready_mem),

        .rready_mem(rready_mem),
        .rdata_mem(rdata_mem),
        .rresp_mem(rresp_mem),
        .rid_mem(rid_mem),
        .rlast_mem(rlast_mem),
        .rvalid_mem(rvalid_mem),

        .awaddr_mem(awaddr_mem),
        .awvalid_mem(awvalid_mem),
        .awid_mem(awid_mem),
        .awlen_mem(awlen_mem),
        .awsize_mem(awsize_mem),
        .awburst_mem(awburst_mem),
        .awready_mem(awready_mem),

        .wdata_mem(wdata_axi_mem),
        .wstrb_mem(wstrb_mem),
        .wvalid_mem(wvalid_mem),
        .wlast_mem(wlast_mem),
        .wready_mem(wready_mem),

        .bresp_mem(bresp_mem),
        .bvalid_mem(bvalid_mem),
        .bid_mem(bid_mem),
        .bready_mem(bready_mem),

        // arbiter deside
        .arvalid_arbiter(arvalid_arbiter),
        .araddr_arbiter(araddr_arbiter),
        .arid_arbiter(arid_arbiter),
        .arlen_arbiter(arlen_arbiter),
        .arsize_arbiter(arsize_arbiter),
        .arburst_arbiter(arburst_arbiter),
        .arready_xbar(arready_xbar),

        .rdata_xbar(rdata_xbar),
        .rresp_xbar(rresp_xbar),
        .rvalid_xbar(rvalid_xbar),
        .rid_xbar(rid_xbar),
        .rlast_xbar(rlast_xbar),
        .rready_arbiter(rready_arbiter),

        .awaddr_arbiter(awaddr_arbiter),
        .awvalid_arbiter(awvalid_arbiter),
        .awid_arbiter(awid_arbiter),
        .awlen_arbiter(awlen_arbiter),
        .awsize_arbiter(awsize_arbiter),
        .awburst_arbiter(awburst_arbiter),
        .awready_xbar(awready_xbar),

        .wdata_arbiter(wdata_arbiter),
        .wstrb_arbiter(wstrb_arbiter),
        .wvalid_arbiter(wvalid_arbiter),
        .wlast_arbiter(wlast_arbiter),
        .wready_xbar(wready_xbar),

        .bresp_xbar(bresp_xbar),
        .bvalid_xbar(bvalid_xbar),
        .bid_xbar(bid_xbar),
        .bready_arbiter(bready_arbiter)
    );

    ysyx_24080020_XBAR u_xbar(
        .clk(clk),
        .rst(rst),

        // arbiter -> xbar
        .arvalid_arbiter(arvalid_arbiter),
        .araddr_arbiter(araddr_arbiter),
        .arid_arbiter(arid_arbiter),
        .arlen_arbiter(arlen_arbiter),
        .arsize_arbiter(arsize_arbiter),
        .arburst_arbiter(arburst_arbiter),
        .arready_xbar(arready_xbar),

        .rdata_xbar(rdata_xbar),
        .rresp_xbar(rresp_xbar),
        .rvalid_xbar(rvalid_xbar),
        .rid_xbar(rid_xbar),
        .rlast_xbar(rlast_xbar),
        .rready_arbiter(rready_arbiter),

        .awaddr_arbiter(awaddr_arbiter),
        .awvalid_arbiter(awvalid_arbiter),
        .awid_arbiter(awid_arbiter),
        .awlen_arbiter(awlen_arbiter),
        .awsize_arbiter(awsize_arbiter),
        .awburst_arbiter(awburst_arbiter),
        .awready_xbar(awready_xbar),

        .wdata_arbiter(wdata_arbiter),
        .wstrb_arbiter(wstrb_arbiter),
        .wvalid_arbiter(wvalid_arbiter),
        .wlast_arbiter(wlast_arbiter),
        .wready_xbar(wready_xbar),

        .bready_arbiter(bready_arbiter),
        .bvalid_xbar(bvalid_xbar),
        .bid_xbar(bid_xbar),
        .bresp_xbar(bresp_xbar),

        // xbar -> clint
        .arvalid_xbar_clint(arvalid_xbar_clint),
        .araddr_xbar_clint(araddr_xbar_clint),
        .arid_xbar_clint(arid_xbar_clint),
        .arlen_xbar_clint(arlen_xbar_clint),
        .arsize_xbar_clint(arsize_xbar_clint),
        .arburst_xbar_clint(arburst_xbar_clint),
        .arready_clint(arready_clint),

        .rdata_clint(rdata_clint),
        .rresp_clint(rresp_clint),
        .rvalid_clint(rvalid_clint),
        .rid_clint(rid_clint),
        .rlast_clint(rlast_clint),
        .rready_xbar_clint(rready_xbar_clint),

        .awaddr_xbar_clint(awaddr_xbar_clint),
        .awvalid_xbar_clint(awvalid_xbar_clint),
        .awid_xbar_clint(awid_xbar_clint),
        .awlen_xbar_clint(awlen_xbar_clint),
        .awsize_xbar_clint(awsize_xbar_clint),
        .awburst_xbar_clint(awburst_xbar_clint),
        .awready_clint(awready_clint),

        .wdata_xbar_clint(wdata_xbar_clint),
        .wstrb_xbar_clint(wstrb_xbar_clint),
        .wvalid_xbar_clint(wvalid_xbar_clint),
        .wlast_xbar_clint(wlast_xbar_clint),
        .wready_clint(wready_clint),

        .bvalid_clint(bvalid_clint),
        .bresp_clint(bresp_clint),
        .bid_clint(bid_clint),
        .bready_xbar_clint(bready_xbar_clint),

        `ifdef ysyx_24080020_NPC
        // xbar -> sram
        .arvalid_xbar_sram(arvalid_xbar_sram),
        .araddr_xbar_sram(araddr_xbar_sram),
        .arid_xbar_sram(arid_xbar_sram),
        .arlen_xbar_sram(arlen_xbar_sram),
        .arsize_xbar_sram(arsize_xbar_sram),
        .arburst_xbar_sram(arburst_xbar_sram),
        .arready_sram(arready_sram),

        .rdata_sram(rdata_sram),
        .rresp_sram(rresp_sram),
        .rvalid_sram(rvalid_sram),
        .rid_sram(rid_sram),
        .rlast_sram(rlast_sram),
        .rready_xbar_sram(rready_xbar_sram),

        .awaddr_xbar_sram(awaddr_xbar_sram),
        .awvalid_xbar_sram(awvalid_xbar_sram),
        .awid_xbar_sram(awid_xbar_sram),
        .awlen_xbar_sram(awlen_xbar_sram),
        .awsize_xbar_sram(awsize_xbar_sram),
        .awburst_xbar_sram(awburst_xbar_sram),
        .awready_sram(awready_sram),

        .wdata_xbar_sram(wdata_xbar_sram),
        .wstrb_xbar_sram(wstrb_xbar_sram),
        .wvalid_xbar_sram(wvalid_xbar_sram),
        .wlast_xbar_sram(wlast_xbar_sram),
        .wready_sram(wready_sram),

        .bvalid_sram(bvalid_sram),
        .bresp_sram(bresp_sram),
        .bid_sram(bid_sram),
        .bready_xbar_sram(bready_xbar_sram),

        // xbar -> uart
        .arvalid_xbar_uart(arvalid_xbar_uart),
        .araddr_xbar_uart(araddr_xbar_uart),
        .arid_xbar_uart(arid_xbar_uart),
        .arlen_xbar_uart(arlen_xbar_uart),
        .arsize_xbar_uart(arsize_xbar_uart),
        .arburst_xbar_uart(arburst_xbar_uart),
        .arready_uart(arready_uart),

        .rdata_uart(rdata_uart),
        .rresp_uart(rresp_uart),
        .rvalid_uart(rvalid_uart),
        .rid_uart(rid_uart),
        .rlast_uart(rlast_uart),
        .rready_xbar_uart(rready_xbar_uart),

        .awaddr_xbar_uart(awaddr_xbar_uart),
        .awvalid_xbar_uart(awvalid_xbar_uart),
        .awid_xbar_uart(awid_xbar_uart),
        .awlen_xbar_uart(awlen_xbar_uart),
        .awsize_xbar_uart(awsize_xbar_uart),
        .awburst_xbar_uart(awburst_xbar_uart),
        .awready_uart(awready_uart),

        .wdata_xbar_uart(wdata_xbar_uart),
        .wstrb_xbar_uart(wstrb_xbar_uart),
        .wvalid_xbar_uart(wvalid_xbar_uart),
        .wlast_xbar_uart(wlast_xbar_uart),
        .wready_uart(wready_uart),

        .bvalid_uart(bvalid_uart),
        .bresp_uart(bresp_uart),
        .bid_uart(bid_uart),
        .bready_xbar_uart(bready_xbar_uart)
        `endif

        `ifdef ysyxSoCFull
        // (x) xbar -> icache -> soc
        // (√)  xbar -> soc
        .arvalid_xbar_soc(io_master_arvalid),
        .araddr_xbar_soc(io_master_araddr),
        .arid_xbar_soc(io_master_arid),
        .arlen_xbar_soc(io_master_arlen),
        .arsize_xbar_soc(io_master_arsize),
        .arburst_xbar_soc(io_master_arburst),
        .arready_soc(io_master_arready),

        .rdata_soc(io_master_rdata),
        .rresp_soc(io_master_rresp),
        .rvalid_soc(io_master_rvalid),
        .rid_soc(io_master_rid),
        .rlast_soc(io_master_rlast),
        .rready_xbar_soc(io_master_rready),

        .awaddr_xbar_soc(io_master_awaddr),
        .awvalid_xbar_soc(io_master_awvalid),
        .awid_xbar_soc(io_master_awid),
        .awlen_xbar_soc(io_master_awlen),
        .awsize_xbar_soc(io_master_awsize),
        .awburst_xbar_soc(io_master_awburst),
        .awready_soc(io_master_awready),

        .wdata_xbar_soc(io_master_wdata),
        .wstrb_xbar_soc(io_master_wstrb),
        .wvalid_xbar_soc(io_master_wvalid),
        .wlast_xbar_soc(io_master_wlast),
        .wready_soc(io_master_wready),

        .bvalid_soc(io_master_bvalid),
        .bresp_soc(io_master_bresp),
        .bid_soc(io_master_bid),
        .bready_xbar_soc(io_master_bready)
        `endif
    );

`ifdef ysyx_24080020_NPC
    ysyx_24080020_UART u_uart(
        .clk(clk),
        .rst(rst),

        .araddr(araddr_xbar_uart),
        .arvalid(arvalid_xbar_uart),
        .arid(arid_xbar_uart),
        .arlen(arlen_xbar_uart),
        .arsize(arsize_xbar_uart),
        .arburst(arburst_xbar_uart),
        .arready(arready_uart),

        .rdata(rdata_uart),
        .rresp(rresp_uart),
        .rvalid(rvalid_uart),
        .rid(rid_uart),
        .rlast(rlast_uart),
        .rready(rready_xbar_uart),

        .awaddr(awaddr_xbar_uart),
        .awvalid(awvalid_xbar_uart),
        .awid(awid_xbar_uart),
        .awlen(awlen_xbar_uart),
        .awsize(awsize_xbar_uart),
        .awburst(awburst_xbar_uart),
        .awready(awready_uart),

        .wdata(wdata_xbar_uart),
        .wstrb(wstrb_xbar_uart),
        .wvalid(wvalid_xbar_uart),
        .wlast(wlast_xbar_uart),
        .wready(wready_uart),

        .bready(bready_xbar_uart),
        .bresp(bresp_uart),
        .bid(bid_uart),
        .bvalid(bvalid_uart)
    );

    ysyx_24080020_SRAM u_sram(
        .clk(clk),
        .rst(rst),

    `ifdef CONFIG_DPIC
        .arvalid(arvalid_xbar_sram),
        .araddr(araddr_xbar_sram),
        .arid(arid_xbar_sram),
        .arlen(arlen_xbar_sram),
        .arsize(arsize_xbar_sram),
        .arburst(arburst_xbar_sram),
        .arready(arready_sram),

        .rdata(rdata_sram),
        .rresp(rresp_sram),
        .rvalid(rvalid_sram),
        .rid(rid_sram),
        .rlast(rlast_sram),
        .rready(rready_xbar_sram),

        .awaddr(awaddr_xbar_sram),
        .awvalid(awvalid_xbar_sram),
        .awid(awid_xbar_sram),
        .awlen(awlen_xbar_sram),
        .awsize(awsize_xbar_sram),
        .awburst(awburst_xbar_sram),
        .awready(awready_sram),

        .wdata(wdata_xbar_sram),
        .wstrb(wstrb_xbar_sram),
        .wvalid(wvalid_xbar_sram),
        .wlast(wlast_xbar_sram),
        .wready(wready_sram),

        .bresp(bresp_sram),
        .bvalid(bvalid_sram),
        .bid(bid_sram),
        .bready(bready_xbar_sram)
    `else

        .arvalid(arvalid_xbar_sram),
        .araddr(araddr_xbar_sram),
        .arid(arid_xbar_sram),
        .arlen(arlen_xbar_sram),
        .arsize(arsize_xbar_sram),
        .arburst(arburst_xbar_sram),
        .arready(arready_sram),

        .rdata(rdata_sram),
        .rresp(rresp_sram),
        .rvalid(rvalid_sram),
        .rid(rid_sram),
        .rlast(rlast_sram),
        .rready(rready_xbar_sram),

        .awaddr(awaddr_xbar_sram),
        .awvalid(awvalid_xbar_sram),
        .awid(awid_xbar_sram),
        .awlen(awlen_xbar_sram),
        .awsize(awsize_xbar_sram),
        .awburst(awburst_xbar_sram),
        .awready(awready_sram),

        .wdata(wdata_xbar_sram),
        .wstrb(wstrb_xbar_sram),
        .wvalid(wvalid_xbar_sram),
        .wlast(wlast_xbar_sram),
        .wready(wready_sram),

        .bresp(bresp_sram),
        .bvalid(bvalid_sram),
        .bid(bid_sram),
        .bready(bready_xbar_sram),

        .out_arvalid(io_master_arvalid),
        .out_araddr(io_master_araddr),
        .out_arid(io_master_arid),
        .out_arlen(io_master_arlen),
        .out_arsize(io_master_arsize),
        .out_arburst(io_master_arburst),
        .out_arready(io_master_arready),

        .out_rdata(io_master_rdata),
        .out_rresp(io_master_rresp),
        .out_rvalid(io_master_rvalid),
        .out_rid(io_master_rid),
        .out_rlast(io_master_rlast),
        .out_rready(io_master_rready),

        .out_awaddr(io_master_awaddr),
        .out_awvalid(io_master_awvalid),
        .out_awid(io_master_awid),
        .out_awlen(io_master_awlen),
        .out_awsize(io_master_awsize),
        .out_awburst(io_master_awburst),
        .out_awready(io_master_awready),

        .out_wdata(io_master_wdata),
        .out_wstrb(io_master_wstrb),
        .out_wvalid(io_master_wvalid),
        .out_wlast(io_master_wlast),
        .out_wready(io_master_wready),

        .out_bresp(io_master_bresp),
        .out_bvalid(io_master_bvalid),
        .out_bid(io_master_bid),
        .out_bready(io_master_bready)
    `endif // CONFIG_DPIC
    );
`endif // ysyx_24080020_NPC

    ysyx_24080020_CLINT u_clint(
        .clk(clk),
        .rst(rst),

        .arvalid(arvalid_xbar_clint),
        .araddr(araddr_xbar_clint),
        .arid(arid_xbar_clint),
        .arlen(arlen_xbar_clint),
        .arsize(arsize_xbar_clint),
        .arburst(arburst_xbar_clint),
        .arready(arready_clint),

        .rdata(rdata_clint),
        .rresp(rresp_clint),
        .rvalid(rvalid_clint),
        .rid(rid_clint),
        .rlast(rlast_clint),
        .rready(rready_xbar_clint),

        .awaddr(awaddr_xbar_clint),
        .awvalid(awvalid_xbar_clint),
        .awid(awid_xbar_clint),
        .awlen(awlen_xbar_clint),
        .awsize(awsize_xbar_clint),
        .awburst(awburst_xbar_clint),
        .awready(awready_clint),

        .wdata(wdata_xbar_clint),
        .wstrb(wstrb_xbar_clint),
        .wvalid(wvalid_xbar_clint),
        .wlast(wlast_xbar_clint),
        .wready(wready_clint),

        .bresp(bresp_clint),
        .bvalid(bvalid_clint),
        .bid(bid_clint),
        .bready(bready_xbar_clint)
    );

    ysyx_24080020_ICACHE u_icache(
      .clk(clk),
      .rst(rst),
      .fencei_exu(fencei_exu),

      .raddr(raddr_icache),
      .special_pc_i(special_pc_ir_o),
      .special_pc_o(special_pc_icache),
      // axi from lsu
      .arvalid_i(arvalid_ifu),
      .araddr_i(araddr_ifu),
      .arid_i(arid_ifu),
      .arlen_i(arlen_ifu),
      .arsize_i(arsize_ifu),
      .arburst_i(arburst_ifu),
      .arready_i(arready_ifu),

      .rready_i(rready_ifu),
      .rdata_i(rdata_ifu),
      .rresp_i(rresp_ifu),
      .rvalid_i(rvalid_ifu),
      .rid_i(rid_ifu),
      .rlast_i(rlast_ifu),


      // axi to arbiter
      .arvalid_o(arvalid_icache),
      .araddr_o(araddr_icache),
      .arid_o(arid_icache),
      .arlen_o(arlen_icache),
      .arsize_o(arsize_icache),
      .arburst_o(arburst_icache),
      .arready_o(arready_icache),

      .rready_o(rready_icache),
      .rdata_o(rdata_icache),
      .rresp_o(rresp_icache),
      .rvalid_o(rvalid_icache),
      .rid_o(rid_icache),
      .rlast_o(rlast_icache)
    );


    // ysyx_24080020_HAZARD u_hazard(
    //     .clk(clk),
    //     .rst(rst),

    //     // Structural adventures, between ifu and lsu
    //     .arvalid_AND_arready(arvalid_icache & arready_icache),
    //     .inst_fin(rvalid_icache && rready_icache && rlast_icache),
    //     .structural_adventure(structural_adventure),

    //     // Data adventures, between ifu and {idu, exu, wbu}
    //     .rs1_idu(rs1),
    //     .rs2_idu(rs2),
    //     .rd_exu(waddr_exu),
    //     .rd_lsu(waddr_mem),
    //     .rd_wbu(waddr_wb),
    //     .data_adventure(data_adventure),

    //     // control adventures, between ifu and exu
    //     .is_dnpc(is_dnpc_exu),
    //     .exu_lsu_shake_hands(exu_mem_shake_hands),
    //     .control_adventure(control_adventure)

    // );

    ysyx_24080020_FORWARD u_forward(
		.clk(clk),
		.rst(rst),

		.rs1_idu(rs1),
		.rs2_idu(rs2),

		.rd_exu(waddr_exu),
		.rd_data_exu(wdata_exu),
		// .rd_en_exu(wen_exu),

		.rd_lsu(waddr_mem),
		.rd_data_lsu(wdata_mem),
		// .rd_en_lsu(wen_mem),
		// .rd_data_lsu(alu_out_mem),
		.is_load(mren_mem),
		// .mrdata(mrdata_mem),
		// .fin_load(mem_wb_valid),

		.rd_wbu(waddr_wb),
		.rd_data_wbu(wdata_wb),
		// .rd_en_wbu(wen_wb),

		.val_raddr1(val_raddr1),
		.val_raddr2(val_raddr2),

		.need_stall(need_stall),
		.rd_data1_forward(rd_data1_forward),
		.rd_data2_forward(rd_data2_forward),
		.rs1_conflict(rs1_conflict),
		.rs2_conflict(rs2_conflict)
    );

    // slave
    // AR
    assign io_slave_arready = 'b0;
    assign io_slave_rvalid = 'b0;
    assign io_slave_rresp = 'b0;
    assign io_slave_rdata = 'b0;
    assign io_slave_rlast = 'b0;
    assign io_slave_rid = 'b0;
    // AW
    assign io_slave_awready = 'b0;
    // W
    assign io_slave_wready = 'b0;
    // B
    assign io_slave_bvalid = 'b0;
    assign io_slave_bresp = 'b0;
    assign io_slave_bid = 'b0;

endmodule

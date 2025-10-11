`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_LSU_opt (
    input  wire        clk,
    input  wire        rst_n,
    // EXU <---> LSU
    input  wire        exu_mem_valid,
    output wire        mem_exu_ready,
    output wire        mem_wb_valid,
    input  wire        wb_mem_ready,
    input  wire [`ysyx_24080020_WIDTH-1:0] pc_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] pc_mem,
    input  wire        is_dnpc_exu,
    output wire        is_dnpc_mem,
    input  wire [`ysyx_24080020_WIDTH-1:0] dnpc_new_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] dnpc_mem,
    input  wire        mren_exu,
    input  wire [2:0]  mrlen_exu,
    input  wire        mwen_exu,
    input  wire [2:0]  mwmask_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] maddr_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] mwdata_exu,
    output wire        mren_mem,
    output wire [2:0]  mrlen_mem,
    output wire [3:0]  mwmask_mem,
    output wire [`ysyx_24080020_WIDTH-1:0] maddr_mem,
    output wire [`ysyx_24080020_WIDTH-1:0] mwdata_mem,
    // CSR 1 写口（单口）
    input  wire        wcsren_exu,
    input  wire [2:0]  wcsraddr_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] wcsrdata_exu,
    output wire        wcsren_mem,
    output wire [2:0]  wcsraddr_mem,
    output wire [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    // REGFILE 回写
    input  wire        wen_exu,
    input  wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] wdata_exu,
    output wire        wen_mem,
    output wire [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,
    output wire [`ysyx_24080020_WIDTH-1:0] wdata_mem,
    // 边带
    input  wire        is_ecall_exu,
    output wire        is_ecall_lsu,
    // AXI-Full（单 beat，完全组合）
    output wire        arvalid,
    output wire [3:0]  arid,
    output wire [7:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [`ysyx_24080020_WIDTH-1:0] araddr,
    input  wire        arready,
    output wire        rready,
    input  wire        rvalid,
    input  wire [1:0]  rresp,
    input  wire [3:0]  rid,
    input  wire        rlast,
    input  wire [`ysyx_24080020_WIDTH-1:0] rdata,
    input  wire        awready,
    output wire        awvalid,
    output wire [3:0]  awid,
    output wire [7:0]  awlen,
    output wire [2:0]  awsize,
    output wire [1:0]  awburst,
    output wire [`ysyx_24080020_WIDTH-1:0] awaddr,
    input  wire        wready,
    output wire        wvalid,
    output wire        wlast,
    output wire [3:0]  wstrb,
    output wire [`ysyx_24080020_WIDTH-1:0] wdata,
    input  wire        bvalid,
    input  wire [1:0]  bresp,
    input  wire [3:0]  bid,
    output wire        bready
);

//=========================================================================
// 1. 经典 valid-ready 握手（无状态机）
//=========================================================================
// 反压：本级空就能收
assign mem_exu_ready = ~mem_valid_q;
// 向下游：有数据就 valid
assign mem_wb_valid  = mem_valid_q;

//=========================================================================
// 2. 只锁 72 bit 控制向量（位宽已砍半）
//=========================================================================
reg        mem_valid_q;      // 1 bit
reg [31:0] mem_pc_q;         // 32 bit
reg [31:0] mem_result_q;     // 32 bit（读数据或写数据）
reg [2:0]  mem_len_q;        // 3 bit
reg [3:0]  mem_wmask_q;      // 4 bit
reg        mem_csr_wen_q;    // 1 bit
reg        mem_ecall_q;      // 1 bit
// 总锁存位宽 = 1+32+32+3+4+1+1 = 74 bit

// 组合输出：直接连 Q
assign mren_mem   = mem_valid_q & (mem_len_q != 3'd0);
assign mwen_mem   = mem_valid_q & (mem_wmask_q != 4'd0);
assign mrlen_mem  = mem_len_q;
assign mwmask_mem = mem_wmask_q;
assign maddr_mem  = mem_result_q;   // 地址来自 ALU
assign mwdata_mem = mem_result_q;   // 写数据来自 ALU
assign wcsren_mem = mem_csr_wen_q;
assign wcsraddr_mem = 3'd0;         // 固定地址，边带区分
assign wcsrdata_mem = mem_result_q;
assign wen_mem    = mem_valid_q & (mem_len_q != 3'd0); // 写回寄存器
assign waddr_mem  = mem_result_q[4:0]; // 低 5 位是寄存器号
assign wdata_mem  = mem_result_q;
assign is_ecall_lsu = mem_ecall_q;
assign pc_mem     = mem_pc_q;
assign dnpc_mem   = mem_result_q; // 跳转目标
assign is_dnpc_mem = mem_valid_q & mem_ecall_q; // 只有 ecall 才跳转

//=========================================================================
// 3. 一级寄存器更新（经典 valid-ready）
//=========================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        mem_valid_q    <= 1'b0;
        mem_pc_q       <= 32'd0;
        mem_result_q   <= 32'd0;
        mem_len_q      <= 3'd0;
        mem_wmask_q    <= 4'd0;
        mem_csr_wen_q  <= 1'b0;
        mem_ecall_q    <= 1'b0;
    end
    else if (wb_mem_ready) begin        // 下游能收
        mem_valid_q    <= exu_mem_valid; // 上游有数据就锁
        mem_pc_q       <= pc_exu;
        mem_result_q   <= (mren_exu) ? mrdata_mem : wdata_exu; // 读/写结果
        mem_len_q      <= mrlen_exu;
        mem_wmask_q    <= mwmask_exu;
        mem_csr_wen_q  <= wcsren_exu;
        mem_ecall_q    <= is_ecall_exu;
    end
end

//=========================================================================
// 4. AXI-Full：单 beat，完全组合（不锁 valid）
//=========================================================================
// VALID 用组合逻辑（不锁）
assign arvalid = mren_exu & mem_exu_ready;
assign awvalid = mwen_exu & mem_exu_ready;
assign wvalid  = mwen_exu & mem_exu_ready;

// 边带信号：只锁必要位（≤ 20 bit）
reg [7:0]  arlen_q, awlen_q;
reg        wlast_q;
reg [3:0]  wstrb_q;

always @(posedge clk) begin
    if (!rst_n) begin
        arlen_q <= 8'd0;
        awlen_q <= 8'd0;
        wlast_q <= 1'b0;
        wstrb_q <= 4'd0;
    end
    else if (wb_mem_ready) begin
        arlen_q <= 8'd0;      // 单 beat
        awlen_q <= 8'd0;
        wlast_q <= 1'b1;
        wstrb_q <= mwmask_exu;
    end
end

assign arlen = arlen_q;
assign awlen = awlen_q;
assign wlast = wlast_q;
assign wstrb = wstrb_q;

// 其余 AXI 信号直接连组合
assign arid   = 4'd0;
assign arsize = 3'b010;      // 4 字节
assign arburst = 2'b01;      // INCR
assign araddr = mem_result_q;

assign awid   = 4'd0;
assign awsize = 3'b010;
assign awburst = 2'b01;
assign awaddr = mem_result_q;

assign wdata  = mem_result_q;
assign bready = 1'b1;        // 永远 ready（单 beat）

// 读数据组合路径（不锁）
assign rready = 1'b1;        // 永远 ready
wire [31:0] rdata_shift = (maddr_mem[1:0] == 2'b00) ? rdata :
                          (maddr_mem[1:0] == 2'b01) ? rdata >> 8 :
                          (maddr_mem[1:0] == 2'b10) ? rdata >> 16 :
                          rdata >> 24;

// 读完成组合标志（不锁）
wire rdone = rvalid & rlast;

//=========================================================================
// 5. 读数据写回（组合路径，不锁）
//=========================================================================
// 读数据：同一周期直接写回 mem_result_q
always @(*) begin
    case (mem_len_q)
        3'b000: mrdata_mem = {{24{rdata_shift[7]}},  rdata_shift[7:0]};   // LB
        3'b001: mrdata_mem = {{16{rdata_shift[15]}}, rdata_shift[15:0]};  // LH
        3'b010: mrdata_mem = rdata_shift;                                 // LW
        3'b100: mrdata_mem = {24'd0, rdata_shift[7:0]};                 // LBU
        3'b101: mrdata_mem = {16'd0, rdata_shift[15:0]};                // LHU
        default: mrdata_mem = 32'hffffffff;
    endcase
end

//=========================================================================
// 6. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
assign is_dnpc_mem = mem_valid_q & mem_ecall_q;
assign dnpc_mem    = mem_result_q;
assign pc_mem      = mem_pc_q;
`else
assign is_dnpc_mem = 1'b0;
assign dnpc_mem    = 32'd0;
assign pc_mem      = 32'd0;
`endif

endmodule
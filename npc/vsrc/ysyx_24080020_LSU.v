`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_LSU (
    input  wire        clk,
    input  wire        rst,

    `ifdef CONFIG_DPIC
    output wire skip_ref_mem,

    input  wire [`ysyx_24080020_WIDTH-1:0] pc_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] pc_mem,
    input  wire        is_dnpc_exu,
    output wire        is_dnpc_mem,
    input  wire [`ysyx_24080020_WIDTH-1:0] dnpc_exu,
    output wire [`ysyx_24080020_WIDTH-1:0] dnpc_mem,

    `endif

    // EXU <---> LSU
    input  wire        exu_mem_valid,
    output wire        mem_exu_ready,
    output wire        mem_wb_valid,
    input  wire        wb_mem_ready,

    // LOAD STORE
    input  wire        mren_exu,
    input  wire        mwen_exu,
    input  wire [2:0]  mem_len_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] maddr_exu,
    // input  wire [2:0]  mwmask_exu,
    // input  wire [`ysyx_24080020_WIDTH-1:0] mwdata_exu,

    // for pipeline control
    output wire wait_load,
    output wire mwen_mem  ,
    output wire mren_mem  ,

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

    // other
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
// 向下游：有数据且AXI传输完成就 valid
assign mem_wb_valid  = mem_valid_q & (all_done | axi_done);

//=========================================================================
// 2. 只锁 72 bit 控制向量（位宽已砍半）
//=========================================================================
reg                                mem_valid_q;      // 1 bit
reg                                mem_ecall_q;      // 1 bit
// REG
reg                                mem_wen_q;
reg [`ysyx_24080020_REG_WIDTH-1:0] mem_waddr_q;
// wdata is mem_result_q

// CSR
reg                                mem_csr_wen_q;
reg [2:0]                          mem_wcsraddr_q;
reg [`ysyx_24080020_WIDTH-1:0]     mem_wcsrdata_q;

// MEM
reg                                mem_mren_q;
reg                                mem_mwen_q;
reg [2:0]                          mem_len_q;        // 3 bit mwlen is same as mrlen
reg [31:0]                         mem_maddr_q;     // 32 bit（读数据或写数据）
reg [31:0]                         mem_result_q;     // 32 bit（读数据或写数据）

// stall_pipeline
reg                                mem_wait_load_q;

wire [2:0] mrlen_mem ;
wire [3:0] mwmask_mem;
wire [31:0] maddr_mem ;
wire [31:0] mwdata_mem;

// 组合输出：直接连 Q
assign wait_load  = mem_wait_load_q;
assign mren_mem   = mem_mren_q;
assign mwen_mem   = mem_mwen_q;
assign mrlen_mem  = mem_len_q;
assign mwmask_mem = (maddr_mem[1:0] == 2'b00) ?
                        (mrlen_mem == 3'b000) ? 4'b0001 :
                        (mrlen_mem == 3'b001) ? 4'b0011 :
                        (mrlen_mem == 3'b010) ? 4'b1111 : 4'b000 :
                    (maddr_mem[1:0] == 2'b01) ?
                        (mrlen_mem == 3'b000) ? 4'b0010 :
                        (mrlen_mem == 3'b001) ? 4'b0110 :
                        (mrlen_mem == 3'b010) ? 4'b1110 : 4'b000 :
                    (maddr_mem[1:0] == 2'b10) ?
                        (mrlen_mem == 3'b000) ? 4'b0100 :
                        (mrlen_mem == 3'b001) ? 4'b1100 :
                        (mrlen_mem == 3'b010) ? 4'b1100 : 4'b000 :
                    (maddr_mem[1:0] == 2'b11) ?
                        4'b1000 : 4'b000 ;

assign maddr_mem  = mem_maddr_q;   // 地址来自 ALU
assign mwdata_mem = mem_result_q;   // 写数据来自 ALU
assign wcsren_mem = mem_csr_wen_q;
assign wcsraddr_mem = mem_wcsraddr_q;
assign wcsrdata_mem = mem_wcsrdata_q;
assign wen_mem    = mem_wen_q;
assign waddr_mem  = mem_waddr_q;
assign wdata_mem  = mren_mem ? mrdata_mem : mem_result_q;
assign is_ecall_lsu = mem_ecall_q;

//=========================================================================
// 3. 一级寄存器更新（经典 valid-ready）
//=========================================================================
always @(posedge clk) begin
    if (!rst) begin
        mem_valid_q    <= 1'b0;
        mem_len_q      <= 3'd0;
        mem_csr_wen_q  <= 1'b0;
        mem_ecall_q    <= 1'b0;
    end
    else if(mem_wb_valid && wb_mem_ready) begin
        mem_valid_q    <= 1'b0;
        mem_wait_load_q<= 1'b0;
        mem_waddr_q    <= 'b0;
    end
    else if (exu_mem_valid && mem_exu_ready) begin        // 下游能收
        mem_wait_load_q<= mren_exu | mwen_exu;
        mem_valid_q    <= exu_mem_valid; // 上游有数据就锁
        mem_mren_q     <= mren_exu;
        mem_mwen_q     <= mwen_exu;
        mem_maddr_q    <= maddr_exu;
        mem_len_q      <= mem_len_exu;
        mem_ecall_q    <= is_ecall_exu;
        mem_csr_wen_q  <= wcsren_exu;
        mem_wcsraddr_q <= wcsraddr_exu;
        mem_wcsrdata_q <= wcsrdata_exu;
        mem_wen_q      <= wen_exu;
        mem_waddr_q    <= waddr_exu;
    end
end

always @(posedge clk) begin
    if (!rst) begin
        mem_result_q   <= 32'd0;
    end
    else if(rvalid & rready) begin
        mem_result_q   <= rdata; // 读/写结果
    end
    else if (exu_mem_valid && mem_exu_ready) begin        // 下游能收
        mem_result_q   <= wdata_exu; // 读/写结果
    end
end

//=========================================================================
// 4. AXI-Full：简化时序逻辑
//=========================================================================
// AXI传输控制寄存器
reg ar_sent, aw_sent, w_sent;
reg axi_done;



// AXI传输完成判断
wire read_done  = mren_mem && rvalid && rready && rlast;
wire write_done = mwen_mem && bvalid && bready;
wire all_done   = (~(mwen_mem | mren_mem)) ? 1'b1 :
                  (mren_mem ? read_done : write_done);

// AXI valid信号生成（握手成功后不再拉高）
assign arvalid = mren_mem && mem_valid_q && !ar_sent;
assign awvalid = mwen_mem && mem_valid_q && !aw_sent;
assign wvalid  = mwen_mem && mem_valid_q && !w_sent;

// AXI传输状态更新
always @(posedge clk) begin
    if (!rst) begin
        ar_sent   <= 1'b0;
        aw_sent   <= 1'b0;
        w_sent    <= 1'b0;
        axi_done  <= 1'b0;
    end
    else if (mem_wb_valid && wb_mem_ready) begin
        // 传输完成，重置状态
        ar_sent   <= 1'b0;
        aw_sent   <= 1'b0;
        w_sent    <= 1'b0;
        axi_done  <= 1'b0;
    end
    else if (mem_valid_q) begin
        // 记录握手成功状态
        if (arvalid && arready) ar_sent <= 1'b1;
        if (awvalid && awready) aw_sent <= 1'b1;
        if (wvalid && wready)   w_sent  <= 1'b1;

        // 记录传输完成状态
        if (all_done) axi_done <= 1'b1;
    end
end


assign arlen = 'b0;
assign awlen = 'b0;
assign wlast = 'b1;
assign wstrb = mwmask_mem;

// 其余 AXI 信号直接连组合
assign arid   = 4'd0;
assign arsize = 3'b010;      // 4 字节
assign arburst = 2'b01;      // INCR
assign araddr = mem_maddr_q;

assign awid   = 4'd0;
assign awsize = 3'b010;
assign awburst = 2'b01;
assign awaddr = mem_maddr_q;

assign wdata  = (mem_maddr_q[1:0] == 2'b00) ? mem_result_q :
                (mem_maddr_q[1:0] == 2'b01) ? mem_result_q << 8 :
                (mem_maddr_q[1:0] == 2'b10) ? mem_result_q << 16 :
                mem_result_q << 24;
assign bready = 1'b1;        // 永远 ready（单 beat）

// 读数据组合路径（不锁）
assign rready = 1'b1;        // 永远 ready
wire [31:0] rdata_shift = (maddr_mem[1:0] == 2'b00) ? mem_result_q :
                          (maddr_mem[1:0] == 2'b01) ? mem_result_q >> 8 :
                          (maddr_mem[1:0] == 2'b10) ? mem_result_q >> 16 :
                          mem_result_q >> 24;


//=========================================================================
// 5. 读数据写回（组合路径，不锁）
//=========================================================================
// 读数据：同一周期直接写回 mem_result_q
reg [31:0] mrdata_mem;
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
reg [31:0] mem_pc_q;         // 32 bit
reg [31:0] mem_dnpc_q;         // 32 bit
reg        mem_is_dnpc_q;
reg        mem_skip_ref_q;

assign is_dnpc_mem = mem_is_dnpc_q;
assign dnpc_mem    = mem_dnpc_q;
assign pc_mem      = mem_pc_q;
assign skip_ref_mem= mem_skip_ref_q;

always @(posedge clk) begin
    if (!rst) begin
        mem_pc_q       <= 32'd0;
    end
    else if (exu_mem_valid && mem_exu_ready) begin
        mem_pc_q       <= pc_exu;
        mem_is_dnpc_q  <= is_dnpc_exu;
        mem_dnpc_q     <= dnpc_exu;
    end
end


always @(posedge clk) begin
    if(!rst) begin
        mem_skip_ref_q <= 'b0;
    end
    else if(mem_wb_valid && wb_mem_ready) begin
        mem_skip_ref_q <= 'b0;
    end
    else if(arvalid && arready) begin
        `ifdef ysyxSoCFull
        if(araddr >= 32'h10000000 && araddr < 32'h10001000
            || araddr >= 32'h10011000 && araddr < 32'h10011008
            || araddr >= 32'h21000000 && araddr < 32'h21200000
            || araddr >= 32'h02000000 && araddr < 32'h02000008
            || araddr >= 32'hc0000000 && araddr < 32'hffffffff
            ) begin
            // skip uart keyboard etc.
            mem_skip_ref_q <= 'b1;
        end
        `endif
        `ifdef ysyx_24080020_NPC
        if(araddr >= 32'ha00003f8 && araddr < 32'ha0000400
            || araddr >= 32'ha0000048 && araddr < 32'ha0000050
            ) begin
            // skip uart keyboard etc.
            mem_skip_ref_q <= 'b1;
        end
        `endif

    end
    else if(awvalid && awready) begin
        // mwen_mem <= 1'b0;
        `ifdef ysyxSoCFull
        if(awaddr >= 32'h10000000 && awaddr < 32'h10001000
            || awaddr >= 32'h10011000 && awaddr < 32'h10011008
            || awaddr >= 32'h21000000 && awaddr < 32'h21200000
            || awaddr >= 32'h02000000 && awaddr < 32'h02000008
            || awaddr >= 32'hc0000000 && awaddr < 32'hffffffff
            ) begin
            // skip uart keyboard etc.
            mem_skip_ref_q <= 'b1;
        end
        `endif
        `ifdef ysyx_24080020_NPC
        if(awaddr >= 32'ha00003f8 && awaddr < 32'ha0000400
            || awaddr >= 32'ha0000048 && awaddr < 32'ha0000050
            ) begin
            // skip uart keyboard etc.
            mem_skip_ref_q <= 'b1;
        end
        `endif

    end
end

`endif

endmodule

`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR (
    input  wire        clk,
    input  wire        rst,

    input  wire        stall,

    // btb <-> ir
    input  wire        special_pc_i,
    input  wire [`ysyx_24080020_WIDTH-1:0] addr,
    input  wire        if_en_valid,
    output wire        if_en_ready,
    // ir <-> ifu
    output wire        inst_fin_valid,
    output wire [`ysyx_24080020_WIDTH-1:0] inst,
    input  wire        inst_fin_ready,
    output wire [`ysyx_24080020_WIDTH-1:0] raddr_ir,

    // icache -> ir
    input  wire        special_pc_icache,
    input  wire [`ysyx_24080020_WIDTH-1:0] raddr_icache,
    output wire        special_pc_ir,
    output wire        special_pc_o,
    // AXI-Full（单 beat，完全组合）
    output wire        arvalid,
    output wire [1:0]  arburst,
    output wire [2:0]  arsize,
    output wire [3:0]  arid,
    output wire [7:0]  arlen,
    output wire [`ysyx_24080020_WIDTH-1:0] araddr,
    input  wire        arready,
    input  wire        rvalid,
    input  wire        rlast,
    input  wire [1:0]  rresp,
    input  wire [3:0]  rid,
    input  wire [`ysyx_24080020_WIDTH-1:0] rdata,
    output wire        rready
);

//=========================================================================
// 1. 地址选择与输出（组合，与原文件 100 % 一致）
//=========================================================================
// assign raddr_ir     = (special_pc_icache) ? raddr_icache : 32'd0;
// assign raddr_ir     = raddr_icache;
assign special_pc_ir = special_pc_icache;
assign special_pc_o  = special_pc_q;

//=========================================================================
// 2. 经典 valid-ready 握手（零状态机）
//=========================================================================
reg valid_q_reg;
reg special_pc_q;
reg [31:0] addr_q;


always @(posedge clk) begin
    if (!rst) begin
        valid_q_reg     <= 1'b0;
    end
    // else if ((inst_fin_valid & inst_fin_ready)) begin
    else if (if_en_valid && if_en_ready) begin
        valid_q_reg     <= 1'b1;
        special_pc_q    <= special_pc_i;
        addr_q          <= addr;
    end
    else if (arready) begin
        valid_q_reg     <= 1'b0;
    end
end
// 反压：本级空就能收
assign if_en_ready = ~valid_q_reg;
// AXI valid：组合逻辑，握手后立即拉低
assign arvalid = valid_q_reg && !ar_sent;

reg ar_sent;

// AXI传输状态更新
always @(posedge clk) begin
    if (!rst) begin
        ar_sent   <= 1'b0;
    end
    else if (if_en_valid && if_en_ready) begin
        // 传输完成，重置状态
        ar_sent   <= 1'b0;
    end
    else if (arvalid && arready) begin
        ar_sent <= 1'b1;
    end
end

// reg arvalid_q;
//
// always @(posedge clk) begin
//     if (!rst)
//         arvalid_q <= 1'b0;
//     else if (arready)                       // 握手成功才更新
//         arvalid_q <= if_en_valid & ~arvalid_q; // 请求且未发
// end
//
// assign arvalid = arvalid_q;               // 寄存器输出
// assign if_en_ready = ~arvalid_q;          // 反压信号

// AXI 边带：单 beat，完全组合（与原文件一致）
assign arburst = 2'b01;   // INCR
assign arsize  = 3'b010;  // 4 字节
assign arid    = 4'd0;
assign arlen   = 8'd0;    // 单 beat
assign araddr  = addr_q;

//=========================================================================
// 3. 读数据：同一拍返回（不锁 rdata）
//=========================================================================
// assign rready = 1'b1;     // 永远 ready（单 beat）
// assign rdata  = rdata;    // 直接连 ICACHE
// assign rresp  = 2'b00;    // OKAY
// assign rid    = rid;
// assign rlast  = 1'b1;     // 单 beat


//=========================================================================
// 4. 输出：直接连组合（不锁整拍，与原文件一致）
//=========================================================================
// reg [31:0] rdata_q, raddr_icache_q;
//
// always @(posedge clk) begin
//     if (!rst) begin
//     end
//     else if (rvalid & rready) begin
//         rdata_q         <= rdata;
//         raddr_icache_q  <= raddr_icache;
//     end
// end
// assign inst       = rdata_q;
// // assign pc_mem     = addr;   // PC 直接连输入
// assign raddr_ir   = raddr_icache_q;   // 地址直接连输入
// assign rready = inst_fin_ready;     // 永远 ready（单 beat）
// // 读完成标志：同一拍有效（与原文件一致）
// assign inst_fin_valid = rvalid & rlast & rready & (rresp == 2'b00);


reg buffer_valid;
reg [31:0] rdata_q, raddr_icache_q;
always @(posedge clk) begin
    if (!rst) begin
        buffer_valid <= 0;
    end
    else if(inst_fin_valid & inst_fin_ready) begin
        buffer_valid <= 'b0;
    end
    else if(rvalid & rready) begin
        rdata_q         <= rdata;
        raddr_icache_q  <= raddr_icache;
        buffer_valid    <= 'b1;
    end
end

assign inst             = rdata_q;
assign inst_fin_valid   = buffer_valid & ~stall;
assign rready           = ~buffer_valid;
assign raddr_ir   = raddr_icache_q;   // 地址直接连输入




//=========================================================================
// 5. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
always @(posedge clk) begin
    if (rvalid & rlast & (rresp != 2'b00))
        $error("IR read error");
end
`endif

endmodule

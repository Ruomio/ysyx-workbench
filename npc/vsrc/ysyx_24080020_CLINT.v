`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_CLINT (
    input  wire        clk,
    input  wire        rst,
    // AXI-Full（单 beat，完全组合）
    input  wire        arvalid,
    input  wire [31:0] araddr,
    input  wire [3:0]  arid,
    input  wire [7:0]  arlen,
    input  wire [2:0]  arsize,
    input  wire [1:0]  arburst,
    output wire        arready,
    input  wire        rready,
    output wire        rvalid,
    output wire [1:0]  rresp,
    output wire [31:0] rdata,
    output wire [3:0]  rid,
    output wire        rlast,
    input  wire        awvalid,
    input  wire [31:0] awaddr,
    input  wire [3:0]  awid,
    input  wire [7:0]  awlen,
    input  wire [2:0]  awsize,
    input  wire [1:0]  awburst,
    output wire        awready,
    input  wire        wvalid,
    input  wire [3:0]  wstrb,
    input  wire [31:0] wdata,
    input  wire        wlast,
    output wire        wready,
    input  wire        bready,
    output wire        bvalid,
    output wire [3:0]  bid,
    output wire [1:0]  bresp
);

//=========================================================================
// 1. 64 bit 时间计数器（唯一锁存）
//=========================================================================
reg [31:0] timel_q, timeh_q;

always @(posedge clk) begin
    if (!rst) begin
        timel_q <= 32'd0;
        timeh_q <= 32'd0;
    end
    else if (timel_q == 32'hFFFFFFFF) begin
        timeh_q <= timeh_q + 32'd1;
        timel_q <= 32'd0;
    end
    else begin
        timel_q <= timel_q + 32'd1;
    end
end

//=========================================================================
// 2. 读地址解码（组合）
//=========================================================================
wire        is_time_l = (araddr == `ysyx_24080020_CLINT_ADDR);      // 0x0200BFF8
wire        is_time_h = (araddr == `ysyx_24080020_CLINT_ADDR + 4);  // 0x0200BFFC
wire        is_read   = arvalid & arready & (is_time_l | is_time_h);

//=========================================================================
// 3. 读数据：同一拍返回（不锁 rdata）
//=========================================================================
assign arready = is_time_h | is_time_l;      // 永远 ready（单 beat）
assign rdata   = is_time_l ? timel_q : timeh_q;
assign rresp   = 2'b00;     // OKAY
assign rid     = arid;
assign rlast   = 1'b1;      // 单 beat

// 读完成标志：同一拍有效
assign rvalid  = is_read;

//=========================================================================
// 4. 写通道：单拍完成（不锁 awready/wready/bvalid）
//=========================================================================
assign awready = 1'b1;      // 永远 ready
assign wready  = 1'b1;      // 永远 ready
assign bvalid  = awvalid & wvalid & wready; // 同一拍回 B
assign bresp   = 2'b01;     // SLVERR（CLINT 只读）
assign bid     = awid;

//=========================================================================
// 5. 调试开关（可选，综合时可 `ifdef` 关闭）
//=========================================================================
`ifdef CONFIG_DPIC
always @(posedge clk) begin
    if (awvalid & wvalid) begin
        $display("CLINT: write to 0x%08x ignored", awaddr);
    end
    if(arvalid & (~(is_time_h | is_time_l))) begin
        $display("CLINT: error forward, addr is not belong to CLINT");
    end
end
`endif

endmodule

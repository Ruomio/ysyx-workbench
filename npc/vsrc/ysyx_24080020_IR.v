`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR (
    input  wire        clk,
    input  wire        rst,

    // PC <-> IR
    input  wire [`ysyx_24080020_WIDTH-1:0] pc_addr,
    input  wire        pc_ir_valid,
    output wire        ir_pc_ready,

    // IR <-> IFU
    output wire        ir_ifu_valid,
    output wire [`ysyx_24080020_WIDTH-1:0] inst_data,
    output wire [`ysyx_24080020_WIDTH-1:0] inst_addr,
    input  wire        ifu_ir_ready,

    // AXI-Full接口（访问ICache）
    output wire        arvalid,
    output wire [3:0]  arid,
    output wire [7:0]  arlen,
    output wire [2:0]  arsize,
    output wire [1:0]  arburst,
    output wire [`ysyx_24080020_WIDTH-1:0] araddr,
    input  wire        arready,

    input  wire        rvalid,
    input  wire [1:0]  rresp,
    input  wire [3:0]  rid,
    input  wire        rlast,
    input  wire [`ysyx_24080020_WIDTH-1:0] rdata,
    output wire        rready
);

//=========================================================================
// 1. 流水线控制寄存器
//=========================================================================
reg                                ir_valid_q;
reg [`ysyx_24080020_WIDTH-1:0]     addr_q;
reg [`ysyx_24080020_WIDTH-1:0]     inst_q;

// AXI传输状态
reg                                ar_sent;
reg                                read_pending;

//=========================================================================
// 2. 流水线握手逻辑
//=========================================================================
// 反压：本级空就能接收新地址
assign ir_pc_ready = ~ir_valid_q;

// 向下游：有指令数据就valid
assign ir_ifu_valid = ir_valid_q;

// 输出指令和地址
assign inst_data = inst_q;
assign inst_addr = addr_q;

//=========================================================================
// 3. AXI读通道控制
//=========================================================================
// AXI valid信号：有地址且未发送请求
assign arvalid = ir_valid_q && !ar_sent;

// AXI配置信号
assign arid    = 4'd0;
assign arlen   = 8'd0;     // 单beat
assign arsize  = 3'b010;   // 4字节
assign arburst = 2'b01;    // INCR
assign araddr  = addr_q;

// AXI ready信号
assign rready = 1'b1;      // 始终准备好接收数据

//=========================================================================
// 4. 主控制逻辑（单个always块）
//=========================================================================
always @(posedge clk or negedge rst) begin
    if (!rst) begin
        ir_valid_q    <= 1'b0;
        addr_q        <= 32'd0;
        inst_q        <= 32'd0;
        ar_sent       <= 1'b0;
        read_pending  <= 1'b0;
    end
    else begin
        // 接收新PC地址
        if (pc_ir_valid && ir_pc_ready) begin
            ir_valid_q   <= 1'b1;
            addr_q       <= pc_addr;
            ar_sent      <= 1'b0;
            read_pending <= 1'b1;
        end

        // 记录AXI读请求发送
        if (arvalid && arready) begin
            ar_sent <= 1'b1;
        end

        // 接收ICache数据
        if (rvalid && rready && rlast && (rresp == 2'b00)) begin
            inst_q       <= rdata;
            read_pending <= 1'b0;
        end

        // 指令传递给IFU完成
        if (ir_ifu_valid && ifu_ir_ready) begin
            ir_valid_q <= 1'b0;
            ar_sent    <= 1'b0;
        end
    end
end

//=========================================================================
// 5. DPI-C调试接口（可选）
//=========================================================================
`ifdef CONFIG_DPIC
always @(posedge clk) begin
    if (rvalid && rready && (rresp != 2'b00)) begin
        $error("IR: AXI read error at address %h, response %b", araddr, rresp);
    end
end
`endif

endmodule
`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_LSU(
    input clk,
    input rst,

    `ifdef CONFIG_DPIC

    output reg skip_ref_mem,

    input [`ysyx_24080020_WIDTH-1:0] pc_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_mem,

    input is_dnpc_exu,
    output reg is_dnpc_mem,

    input [`ysyx_24080020_WIDTH-1:0] dnpc_new_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_mem,
    `endif

    // memory
    input mren_exu,
    input [2:0] mrlen_exu,
    input mwen_exu,
    input [2:0] mwmask_exu,
    input [`ysyx_24080020_WIDTH-1:0] maddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] mwdata_exu,

    output reg mren_mem,


    // csrs
    input wcsren_exu,
    input [2:0] wcsraddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_exu,
    // input wcsren2_exu,
    // input [2:0] wcsraddr2_exu,
    // input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_exu,
    output reg wcsren_mem,
    output reg [2:0] wcsraddr_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    // output reg wcsren2_mem,
    // output reg [2:0] wcsraddr2_mem,
    // output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,

    // regs
    input wen_exu,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] wdata_exu,
    output reg wen_mem,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,
    output [`ysyx_24080020_WIDTH-1:0] wdata_mem,

    // others
    input wire is_ecall_exu,
    output reg is_ecall_lsu,


    // axi-full
    output arvalid_reg,
    output reg [3:0] arid,
    output reg [7:0] arlen,
    output [2:0] arsize,
    output [1:0] arburst,
    output [`ysyx_24080020_WIDTH-1:0] araddr,
    input arready,

    output reg rready,
    input rvalid,
    input [1:0] rresp,
    input [3:0] rid,
    input rlast,
    input [`ysyx_24080020_WIDTH-1:0] rdata,

    input awready,
    output awvalid_reg,
    output reg [3:0] awid,
    output reg [7:0] awlen,
    output [2:0] awsize,
    output [1:0] awburst,
    output [`ysyx_24080020_WIDTH-1:0] awaddr,

    input wready,
    output wvalid_reg,
    output reg wlast,
    output reg [3:0] wstrb,
    output reg [`ysyx_24080020_WIDTH-1:0] wdata,

    output reg bready,
    input bvalid,
    input [1:0] bresp,
    input [3:0] bid,

    // bus
    input exu_mem_valid,
    input wb_mem_ready,
    output reg mem_exu_ready,
    output reg mem_wb_valid

);
    reg arvalid, awvalid, wvalid;
    assign arvalid_reg = arvalid;
    assign awvalid_reg = awvalid;
    assign wvalid_reg = wvalid;

    reg mwen_mem;
    reg [2:0] mrlen_mem;
    reg [2:0] mwmask_mem;
    reg [`ysyx_24080020_WIDTH-1:0] maddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwdata_mem;
    reg finish_read;

    reg [`ysyx_24080020_WIDTH-1:0] mrdata_mem;
    reg [`ysyx_24080020_WIDTH-1:0] wdata_exu_;

    // 一级 valid-ready 寄存器流水线控制（类似 IDU 实现）
    reg valid_q;
    reg mren_q;
    reg mwen_q;
    reg [2:0] mrlen_q;
    reg [2:0] mwmask_q;
    reg [`ysyx_24080020_WIDTH-1:0] maddr_q;
    reg [`ysyx_24080020_WIDTH-1:0] mwdata_q;
    reg wen_q;
    reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_q;
    reg [`ysyx_24080020_WIDTH-1:0] wdata_q;
    reg wcsren_q;
    reg [2:0] wcsraddr_q;
    reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_q;
    reg is_ecall_q;

    wire [31:0] rdata_shift;
    wire [3:0] wstrb_;
    wire [31:0] wdata_;

    assign arsize = 'b10;
    assign araddr = maddr_mem;
    assign arburst = 2'b1;
    assign rdata_shift = maddr_mem[1:0] == 2'b00 ? rdata :
                        maddr_mem[1:0] == 2'b01 ? rdata >> 8 :
                        maddr_mem[1:0] == 2'b10 ? rdata >> 16 :
                        maddr_mem[1:0] == 2'b11 ? rdata >> 24 :
                        32'b0;

    assign awburst = 2'b1;
    assign awsize = 'b10 ;
    assign awaddr = maddr_mem;
    assign wdata_ =  wstrb_ == 4'b1111 ? mwdata_mem :
                    wstrb_ == 4'b0011 ? mwdata_mem :
                    wstrb_ == 4'b0001 ? mwdata_mem :
                    wstrb_ == 4'b1110 ? mwdata_mem << 8 :
                    wstrb_ == 4'b0110 ? mwdata_mem << 8 :
                    wstrb_ == 4'b0010 ? mwdata_mem << 8 :
                    wstrb_ == 4'b1100 ? mwdata_mem << 16 :
                    wstrb_ == 4'b0100 ? mwdata_mem << 16 :
                    wstrb_ == 4'b1000 ? mwdata_mem << 24 :
                    32'b0;

    assign wstrb_ = maddr_mem[1:0] == 2'b00 ?
                        mwmask_mem == 3'b010 ? 4'b1111 :
                        mwmask_mem == 3'b001 ? 4'b0011 :
                        mwmask_mem == 3'b000 ? 4'b0001 :
                        4'b0000 :
                   maddr_mem[1:0] == 2'b01 ?
                        mwmask_mem == 3'b010 ? 4'b1110 :
                        mwmask_mem == 3'b001 ? 4'b0110 :
                        mwmask_mem == 3'b000 ? 4'b0010 :
                        4'b0000 :
                   maddr_mem[1:0] == 2'b10 ?
                        mwmask_mem == 3'b010 ? 4'b1100 :
                        mwmask_mem == 3'b001 ? 4'b1100 :
                        mwmask_mem == 3'b000 ? 4'b0100 :
                        4'b0000 :
                   maddr_mem[1:0] == 2'b11 ?
                        4'b1000 :
                    4'b0000;


    assign wdata_mem = mren_mem ? mrdata_mem : wdata_exu_;

    // 一级 valid-ready 寄存器流水线控制（类似 IDU 实现）
    // 转发机制：在 AXI R 通道完成之前不能向下传递数据
    assign mem_exu_ready = ~valid_q;  // 反压机制：当寄存器为空时才能接收新数据
    
    // 当有有效数据且不是内存读取操作，或者内存读取操作已完成时，可以向下传递
    wire can_pass_through = valid_q && (!mren_q || finish_read);
    assign mem_wb_valid = can_pass_through;

    always @(posedge clk) begin
        if (!rst) begin
            valid_q <= 1'b0;
            mren_mem <= 1'b0;
            mwen_mem <= 1'b0;
            wen_mem <= 1'b0;
            wcsren_mem <= 1'b0;
            is_ecall_lsu <= 1'b0;
        end
        else if (wb_mem_ready && can_pass_through) begin
            // 下一级准备好且当前可以传递数据
            valid_q <= 1'b0;
            mren_mem <= 1'b0;
            mwen_mem <= 1'b0;
            wen_mem <= 1'b0;
            wcsren_mem <= 1'b0;
            is_ecall_lsu <= 1'b0;
        end
        else if (exu_mem_valid && mem_exu_ready) begin
            // 上一级有效且当前可以接收，锁存数据
            valid_q <= 1'b1;
            
            // 锁存内存相关信号
            mren_q <= mren_exu;
            mwen_q <= mwen_exu;
            mrlen_q <= mrlen_exu;
            mwmask_q <= mwmask_exu;
            maddr_q <= maddr_exu;
            mwdata_q <= mwdata_exu;
            
            // 锁存寄存器写回信号
            wen_q <= wen_exu;
            waddr_q <= waddr_exu;
            wdata_q <= wdata_exu;
            
            // 锁存 CSR 信号
            wcsren_q <= wcsren_exu;
            wcsraddr_q <= wcsraddr_exu;
            wcsrdata_q <= wcsrdata_exu;
            
            // 锁存其他信号
            is_ecall_q <= is_ecall_exu;
            
            // 更新输出信号
            mren_mem <= mren_exu;
            mwen_mem <= mwen_exu;
            mrlen_mem <= mrlen_exu;
            mwmask_mem <= mwmask_exu;
            maddr_mem <= maddr_exu;
            mwdata_mem <= mwdata_exu;
            wen_mem <= wen_exu;
            waddr_mem <= waddr_exu;
            wdata_exu_ <= wdata_exu;
            wcsren_mem <= wcsren_exu;
            wcsraddr_mem <= wcsraddr_exu;
            wcsrdata_mem <= wcsrdata_exu;
            is_ecall_lsu <= is_ecall_exu;
        end
    end




    // AXI 总线控制逻辑（与新的流水线控制配合）
    // AR - 读请求
    always @(posedge clk) begin
        if (!rst) begin
            arvalid <= 1'b0;
        end
        else if (arvalid && arready) begin
            arvalid <= 1'b0;
        end
        else if (valid_q && mren_q && !arvalid) begin
            // 当有有效数据且需要读内存时，发起读请求
            arvalid <= 1'b1;
            arid <= 4'b0;
            arlen <= 8'b0;  // 单次传输
        end
    end

    // R - 读响应
    always @(posedge clk) begin
        if (!rst) begin
            rready <= 1'b0;
        end
        else if (rvalid && rready) begin
            rready <= 1'b0;
        end
        else if (rvalid && !rready) begin
            rready <= 1'b1;
        end
    end

    // AW - 写地址
    always @(posedge clk) begin
        if (!rst) begin
            awvalid <= 1'b0;
        end
        else if (awvalid && awready) begin
            awvalid <= 1'b0;
        end
        else if (valid_q && mwen_q && !awvalid) begin
            // 当有有效数据且需要写内存时，发起写地址请求
            awvalid <= 1'b1;
            awid <= 4'b0;
            awlen <= 8'b0;  // 单次传输
        end
    end

    // W - 写数据
    always @(posedge clk) begin
        if (!rst) begin
            wvalid <= 1'b0;
        end
        else if (wvalid && wready) begin
            wvalid <= 1'b0;
        end
        else if (valid_q && mwen_q && !wvalid) begin
            // 当有有效数据且需要写内存时，发起写数据请求
            wvalid <= 1'b1;
            wlast <= 1'b1;
            wdata <= wdata_;
            wstrb <= wstrb_;
        end
    end

    // B - 写响应
    always @(posedge clk) begin
        if (!rst) begin
            bready <= 1'b0;
        end
        else if (bvalid && bready) begin
            bready <= 1'b0;
        end
        else if (bvalid && !bready) begin
            bready <= 1'b1;
        end
    end

    // 处理读数据
    always @(posedge clk) begin
        if (!rst) begin
            finish_read <= 1'b0;
        end
        else if (finish_read) begin
            finish_read <= 1'b0;
        end
        else if (rvalid && rready && rlast) begin
            finish_read <= 1'b1;

            // 零扩展或有符号扩展
            case(mrlen_mem)
                3'b100:   mrdata_mem <= {{24{1'b0}}, rdata_shift[7:0]};
                3'b101:   mrdata_mem <= {{16{1'b0}}, rdata_shift[15:0]};
                3'b110:   mrdata_mem <= rdata_shift;
                3'b000:   mrdata_mem <= {{24{rdata_shift[7]}}, rdata_shift[7:0]};
                3'b001:   mrdata_mem <= {{16{rdata_shift[15]}}, rdata_shift[15:0]};
                3'b010:   mrdata_mem <= rdata_shift;
                default: mrdata_mem <= 32'hffffffff;
            endcase
        end
    end

    //=========================================================================
    // DPI-C调试接口（可选）
    //=========================================================================
    `ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_lsu_get_data();

    always @(posedge clk) begin
        if(!rst) begin

        end
        else if(exu_mem_valid && mem_exu_ready) begin

            pc_mem <= pc_exu;
            is_dnpc_mem <= is_dnpc_exu;
            dnpc_mem <= dnpc_new_exu;
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(rvalid && rready) begin
            if(rresp != 2'b0) begin
                // rresp fault;
                $display("rresp not be 0b00, ERROR");
            end
            statistics_lsu_get_data();
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(bvalid) begin
            if(bresp != 2'b0) begin
                $error("the bresp are not 2'b0");
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            skip_ref_mem <= 'b0;
        end
        else if(mem_wb_valid && wb_mem_ready) begin
            skip_ref_mem <= 'b0;
        end
        else if(mren_mem && valid_q) begin
            `ifdef ysyxSoCFull
            if(araddr >= 32'h10000000 && araddr < 32'h10001000
                || araddr >= 32'h10011000 && araddr < 32'h10011008
                || araddr >= 32'h21000000 && araddr < 32'h21200000
                || araddr >= 32'h02000000 && araddr < 32'h02000008
                || araddr >= 32'hc0000000 && araddr < 32'hffffffff
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
            end
            `endif
            `ifdef ysyx_24080020_NPC
            if(araddr >= 32'ha00003f8 && araddr < 32'ha0000400
                || araddr >= 32'ha0000048 && araddr < 32'ha0000050
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
            end
            `endif
        end
        else if(mwen_mem && valid_q) begin
            `ifdef ysyxSoCFull
            if(awaddr >= 32'h10000000 && awaddr < 32'h10001000
                || awaddr >= 32'h10011000 && awaddr < 32'h10011008
                || awaddr >= 32'h21000000 && awaddr < 32'h21200000
                || awaddr >= 32'h02000000 && awaddr < 32'h02000008
                || awaddr >= 32'hc0000000 && awaddr < 32'hffffffff
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
            end
            `endif
            `ifdef ysyx_24080020_NPC
            if(awaddr >= 32'ha00003f8 && awaddr < 32'ha0000400
                || awaddr >= 32'ha0000048 && awaddr < 32'ha0000050
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
            end
            `endif
        end
    end
    `endif

endmodule

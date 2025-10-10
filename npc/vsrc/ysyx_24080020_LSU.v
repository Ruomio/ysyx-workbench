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
    // output reg [`ysyx_24080020_WIDTH-1:0] mrdata_mem,

    output reg mren_mem,
    // input [`ysyx_24080020_WIDTH-1:0] alu_out_exu,
    // output [`ysyx_24080020_WIDTH-1:0] rd_data_mem,
    // output reg exu_mem_shake_hands,


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

    // reg mren_mem;
    reg mwen_mem;
    reg [2:0] mrlen_mem;
    reg [2:0] mwmask_mem;
    reg [`ysyx_24080020_WIDTH-1:0] maddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwdata_mem;
    reg finish_read;
    reg next_inst;

    reg arlen_cnt;
    reg awlen_cnt;
    reg [31:0] rdata1, rdata2;

    reg exu_mem_shake_hands;
    reg [`ysyx_24080020_WIDTH-1:0] mrdata_mem;
    reg [`ysyx_24080020_WIDTH-1:0] alu_out_mem;
    reg [`ysyx_24080020_WIDTH-1:0] wdata_exu_;

    reg state; // 0: idle;   1: wait_ready

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

    always @(posedge clk) begin
        if(!rst) begin
            state <= 1'b0;
        end
        else if(!state) begin
            if(mem_wb_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(wb_mem_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            mem_exu_ready <= 1'b0;
            next_inst <= 'b1;

            wen_mem <= 'b0;
            waddr_mem <= 'b0;

            // is_load_mem <= 'b0;
            // is_dnpc_mem <= 'b0;
            // dnpc_mem <= 'b0;

            mren_mem <= 'b0;
            // mrlen_mem <= 'b0;
            // maddr_mem <= 'b0;
            mwen_mem <= 'b0;
            // mwmask_mem <= 'b0;
            // mwdata_mem <= 'b0;

            // alu_out_mem <= 'b0;

            // fencei_mem <= 'b0;

            // pc_mem <= 'b0;

            // mem_wb_valid <= 'b0;


            exu_mem_shake_hands <= 1'b0;

        end
        else if(mem_wb_valid && wb_mem_ready && state) begin

            waddr_mem <= 'b0;
            mren_mem <= 'b0;
            // is_load_mem <= 'b0;
            // fencei_mem <= 'b0;

            next_inst <= 'b1;

        end
        else if(exu_mem_shake_hands) begin
            exu_mem_shake_hands <= 1'b0;
        end
        else if(exu_mem_valid) begin
            if(mem_wb_valid) mem_exu_ready <= 1'b0;
            else if(mem_exu_ready) begin
                mem_exu_ready <= 'b0;
                exu_mem_shake_hands <= 1'b1;

                // update reg
                wen_mem <= wen_exu;
                waddr_mem <= waddr_exu;
                wdata_exu_ <= wdata_exu;


                mren_mem <= mren_exu;
                mrlen_mem <= mrlen_exu;
                maddr_mem <= maddr_exu;
                mwen_mem <= mwen_exu;
                mwmask_mem <= mwmask_exu;
                mwdata_mem <= mwdata_exu;

                alu_out_mem <= alu_out_exu;

                wcsren_mem <= wcsren_exu;
                wcsraddr_mem <= wcsraddr_exu;
                wcsrdata_mem <= wcsrdata_exu;

                // fencei_mem <= fencei_exu;

                next_inst <= 'b0;


            end
            else if(next_inst) begin
                mem_exu_ready <= 1'b1;


            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            mem_wb_valid <= 'b0;

        end
        else if(mem_wb_valid && wb_mem_ready && state) begin
            mem_wb_valid <= 1'b0;
        end
        else if(exu_mem_shake_hands && !mwen_mem && !mren_mem) begin

            mem_wb_valid <= 1'b1;
        end
        else if(finish_read) begin
            mem_wb_valid <= 1'b1;
        end
        else if(bvalid && bready) begin
            mem_wb_valid <= 1'b1;
        end
    end




    // AR
    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
        end
        else if(arvalid && arready) begin
            arvalid <= 1'b0;
        end
        else if(mren_mem && exu_mem_shake_hands) begin
            arvalid <= 1'b1;
            arid <= 4'b0;
            arlen <= 'b0;
        end
    end

    // R
    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
            // arlen_cnt <= 1'b0;
            // rdata1 <= 'b0;
            // rdata2 <= 'b0;
            // mem_wb_valid <= 'b0;
        end
        else if(rvalid && rready) begin
            rready <= 1'b0;

        end
        else if(rvalid) begin
            rready <= 1'b1;
        end
    end


    // AW
    always @(posedge clk) begin
        if(!rst) begin
            awvalid <= 'b0;
        end
        else if(awvalid_reg && awready) begin
            awvalid <= 1'b0;
        end
        else if(mwen_mem && exu_mem_shake_hands) begin
            awvalid <= 1'b1;
            awlen <= 'b0;

        end
    end

    // W
    always @(posedge clk) begin
        if(!rst) begin
            wvalid <= 'b0;
        end
        else if(wvalid_reg && wready) begin
            wvalid <= 1'b0;
        end
        else if(mwen_mem && exu_mem_shake_hands) begin
            wvalid <= 1'b1;
            wlast <= 1'b1;
            wdata <= wdata_;
            wstrb <= wstrb_;
        end
    end

    // B
    always @(posedge clk) begin
        if(!rst) begin
            bready <= 1'b0;
        end
        else if(bvalid && bready) begin
            bready <= 'b0;
        end
        else if(bvalid) begin
            bready <= 1'b1;

        end
    end

    // process rdata
    always @(posedge clk) begin
        if(!rst) begin
            finish_read <= 1'b0;
            // mrdata_mem <= 'b0;
            // mem_wb_valid <= 'b0;
        end
        else if(finish_read) begin
            // finish all read
            // mem_wb_valid <= 1'b1;
            finish_read <= 1'b0;
        end
        else if(rvalid && rready && rlast) begin
            finish_read <= 1'b1;

            if(mrlen_mem[2]) begin
                // zero extension
                case(mrlen_mem)
                    3'd0:   mrdata_mem <= {{24{1'b0}}, rdata_shift[7:0]};
                    3'd1:   mrdata_mem <= {{16{1'b0}}, rdata_shift[15:0]};
                    3'd2:   mrdata_mem <= rdata_shift;
                    default: mrdata_mem <= 32'hffffffff;
                endcase
            end
            else begin
                // signed extension
                case(mrlen_mem)
                    3'd0:   mrdata_mem <= {{24{rdata_shift[7]}}, rdata_shift[7:0]};
                    3'd1:   mrdata_mem <= {{16{rdata_shift[15]}}, rdata_shift[15:0]};
                    3'd2:   mrdata_mem <= rdata_shift;
                    default: mrdata_mem <= 32'hffffffff;
                endcase
            end

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
        else if(mren_mem && exu_mem_shake_hands) begin
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
        else if(mwen_mem && exu_mem_shake_hands) begin
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

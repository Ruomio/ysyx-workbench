`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input structural_adventure,
    // memory
    input mren_exu,
    input mrtype_exu,
    input [3:0] mrlen_exu,
    input mwen_exu,
    input [3:0] mwmask_exu,
    input [`ysyx_24080020_WIDTH-1:0] mraddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] mwdata_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata_mem,

    input [`ysyx_24080020_WIDTH-1:0] alu_out_exu,
    output reg [`ysyx_24080020_WIDTH-1:0] alu_out_mem,
    output reg exu_mem_shake_hands,

    input skip_ref_exu,
    output reg skip_ref_mem,
    output reg axi_busy,

    input is_ebreak_exu,
    output reg is_ebreak_lsu,

    // csrs
    input wcsren_exu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_exu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata_exu,
    input wcsren2_exu,
    input [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_exu,
    input [`ysyx_24080020_WIDTH-1:0] wcsrdata2_exu,
    output reg wcsren_mem,
    output reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata_mem,
    output reg wcsren2_mem,
    output reg [`ysyx_24080020_CSR_WIDTH-1:0] wcsraddr2_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] wcsrdata2_mem,
    // regs
    input wen_exu,
    input [`ysyx_24080020_REG_WIDTH-1:0] waddr_exu,
    output reg wen_mem,
    output reg [`ysyx_24080020_REG_WIDTH-1:0] waddr_mem,

    input reg is_load_exu,
    output reg is_load_mem,

    input is_dnpc_exu,
    input [`ysyx_24080020_WIDTH-1:0] dnpc_new_exu,
    input [`ysyx_24080020_WIDTH-1:0] pc_exu,
    output reg is_dnpc_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] dnpc_mem,
    output reg [`ysyx_24080020_WIDTH-1:0] pc_mem,

    input fencei_exu,
    output reg fencei_mem,

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
    output [`ysyx_24080020_WIDTH-1:0] wdata,

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
`ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_lsu_get_data();
`endif

    reg arvalid, awvalid, wvalid;
    assign arvalid_reg = arvalid && !structural_adventure;
    // assign awvalid_reg = awvalid && !structural_adventure;
    // assign wvalid_reg = wvalid && !structural_adventure;
    assign awvalid_reg = awvalid;
    assign wvalid_reg = wvalid;

    reg mren_mem;
    reg mwen_mem;
    reg mrtype_mem;
    reg [3:0] mrlen_mem;
    reg [3:0] mwmask_mem;
    // reg [`ysyx_24080020_WIDTH-1:0] mrdata_tmp;
    reg [`ysyx_24080020_WIDTH-1:0] mraddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwaddr_mem;
    reg [`ysyx_24080020_WIDTH-1:0] mwdata_mem;
    reg finish_read;
    reg next_inst;

    reg arlen_cnt;
    reg awlen_cnt;
    reg [31:0] rdata1, rdata2;

    reg state; // 0: idle;   1: wait_ready

    wire [31:0] rdata_shift_1, rdata_shift_2, rdata_shift;
    wire get_arlen;
    wire get_awlen;
    wire [3:0] wstrb_1, wstrb_2;
    wire [31:0] wdata_1, wdata_2;

    assign arsize = mrlen_mem == 'b0001 ? 3'b000 :
                    mrlen_mem == 'b0010 ? 3'b001 :
                    mrlen_mem == 'b0100 ? 3'b010 :
                    3'b000;
    assign araddr = mraddr_mem;
    assign arburst = 2'b1;
    assign get_arlen = (({{2{1'b0}}, mraddr_mem[1:0]} + mrlen_mem) > 4'b100) ? 1'b1 : 1'b0;
    assign rdata_shift_1 = araddr[1:0] == 2'b00 ? rdata1 :
                        araddr[1:0] == 2'b01 ? rdata1 >> 8 :
                        araddr[1:0] == 2'b10 ? rdata1 >> 16 :
                        araddr[1:0] == 2'b11 ? rdata1 >> 24 :
                        32'b0;
    assign rdata_shift_2 =  araddr[1:0] == 2'b01 ?
                                mrlen_mem == 4'b100 ? rdata2 << 24 :
                                32'b0 :
                            araddr[1:0] == 2'b10 ?
                                mrlen_mem == 4'b100 ? rdata2 << 16 :
                                32'b0 :
                            araddr[1:0] == 2'b11 ?
                                mrlen_mem == 4'b100 ? rdata2 << 24 :
                                mrlen_mem == 4'b010 ? rdata2 << 8 :
                                32'b0 :
                            32'b0;

    assign rdata_shift = rdata_shift_1 | rdata_shift_2;


    assign awburst = 2'b1;
    assign awsize = mwmask_mem == 'b0001 ? 3'b000 :
                    mwaddr_mem == 'b0010 ? 3'b001 :
                    mwaddr_mem == 'b0100 ? 3'b010 :
                    3'b000;
    assign get_awlen = ({{2{1'b0}},mwaddr_mem[1:0]} + mwmask_mem) > 4'b100 ? 1'b1 : 1'b0;
    assign awaddr = mwaddr_mem;
    assign wdata_1 =  wstrb_1 == 4'b1111 ? mwdata_mem :
                    wstrb_1 == 4'b0011 ? mwdata_mem :
                    wstrb_1 == 4'b0001 ? mwdata_mem :
                    wstrb_1 == 4'b1110 ? mwdata_mem << 8 :
                    wstrb_1 == 4'b0110 ? mwdata_mem << 8 :
                    wstrb_1 == 4'b0010 ? mwdata_mem << 8 :
                    wstrb_1 == 4'b1100 ? mwdata_mem << 16 :
                    wstrb_1 == 4'b0100 ? mwdata_mem << 16 :
                    wstrb_1 == 4'b1000 ? mwdata_mem << 24 :
                    32'b0;
    assign wstrb_1 = mwaddr_mem[1:0] == 2'b00 ?
                        mwmask_mem == 4'b100 ? 4'b1111 :
                        mwmask_mem == 4'b010 ? 4'b0011 :
                        mwmask_mem == 4'b001 ? 4'b0001 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b01 ?
                        mwmask_mem == 4'b100 ? 4'b1110 :
                        mwmask_mem == 4'b010 ? 4'b0110 :
                        mwmask_mem == 4'b001 ? 4'b0010 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b10 ?
                        mwmask_mem == 4'b100 ? 4'b1100 :
                        mwmask_mem == 4'b010 ? 4'b1100 :
                        mwmask_mem == 4'b001 ? 4'b0100 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b11 ?
                        mwmask_mem == 4'b100 ? 4'b1000 :
                        mwmask_mem == 4'b010 ? 4'b1000 :
                        mwmask_mem == 4'b001 ? 4'b1000 :
                        4'b0000 :
                    4'b0000;

    assign wdata_2 =  wstrb_2 == 4'b1111 ? mwdata_mem :
                    wstrb_2 == 4'b0001 ? mwdata_mem >> 24 :
                    wstrb_2 == 4'b0011 ? mwdata_mem >> 16 :
                    wstrb_2 == 4'b0111 ? mwdata_mem >> 24 :
                    32'b0;
    assign wstrb_2 = mwaddr_mem[1:0] == 2'b00 ?
                        mwmask_mem == 4'b100 ? 4'b0000 :
                        mwmask_mem == 4'b010 ? 4'b0000 :
                        mwmask_mem == 4'b001 ? 4'b0000 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b01 ?
                        mwmask_mem == 4'b100 ? 4'b0001 :
                        mwmask_mem == 4'b010 ? 4'b0000 :
                        mwmask_mem == 4'b001 ? 4'b0000 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b10 ?
                        mwmask_mem == 4'b100 ? 4'b0011 :
                        mwmask_mem == 4'b010 ? 4'b0000 :
                        mwmask_mem == 4'b001 ? 4'b0000 :
                        4'b0000 :
                   mwaddr_mem[1:0] == 2'b11 ?
                        mwmask_mem == 4'b100 ? 4'b0111 :
                        mwmask_mem == 4'b010 ? 4'b0001 :
                        mwmask_mem == 4'b001 ? 4'b0000 :
                        4'b0000 :
                    4'b0000;


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
            waddr_mem <= 'b0;
        end
        else if(mem_wb_valid && wb_mem_ready && state) begin
            mem_wb_valid <= 1'b0;

            waddr_mem <= 'b0;

            next_inst <= 'b1;

        end
        else if(exu_mem_valid) begin
            if(mem_wb_valid) mem_exu_ready <= 1'b0;
            else if(mem_exu_ready) begin
                exu_mem_shake_hands <= 1'b1;
            end
            else if(next_inst) begin
                mem_exu_ready <= 1'b1;

                // update reg
                wen_mem <= wen_exu;
                waddr_mem <= waddr_exu;

                is_load_mem <= is_load_exu;
                is_dnpc_mem <= is_dnpc_exu;
                dnpc_mem <= dnpc_new_exu;

                mren_mem <= mren_exu;
                mrtype_mem <= mrtype_exu;
                mrlen_mem <= mrlen_exu;
                mraddr_mem <= mraddr_exu;
                mwen_mem <= mwen_exu;
                mwmask_mem <= mwmask_exu;
                mwaddr_mem <= mwaddr_exu;
                mwdata_mem <= mwdata_exu;

                alu_out_mem <= alu_out_exu;

                wcsren_mem <= wcsren_exu;
                wcsraddr_mem <= wcsraddr_exu;
                wcsrdata_mem <= wcsrdata_exu;
                wcsren2_mem <= wcsren2_exu;
                wcsraddr2_mem <= wcsraddr2_exu;
                wcsrdata2_mem <= wcsrdata2_exu;

                fencei_mem <= fencei_exu;

                pc_mem <= pc_exu;

                skip_ref_mem <= skip_ref_exu;

                is_ebreak_lsu <= is_ebreak_exu;

                next_inst <= 'b0;

                // mem_wb_valid <= 1'b1;
                if(!mwen_exu && !mren_exu) begin
                    mem_wb_valid <= 1'b1;
                end
                if(mren_exu && !structural_adventure) begin
                    axi_busy <= 'b1;
                end

            end
        end
        else begin
            mem_exu_ready <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            exu_mem_shake_hands <= 1'b0;

            wen_mem <= 'b0;
            waddr_mem <= 'b0;

            is_load_mem <= 'b0;
            is_dnpc_mem <= 'b0;
            dnpc_mem <= 'b0;

            mren_mem <= 'b0;
            mrtype_mem <= 'b0;
            mrlen_mem <= 'b0;
            mraddr_mem <= 'b0;
            mwen_mem <= 'b0;
            mwmask_mem <= 'b0;
            mwaddr_mem <= 'b0;
            mwdata_mem <= 'b0;

            alu_out_mem <= 'b0;

            wcsren_mem <= 'b0;
            wcsraddr_mem <= 'b0;
            wcsrdata_mem <= 'b0;
            wcsren2_mem <= 'b0;
            wcsraddr2_mem <= 'b0;
            wcsrdata2_mem <= 'b0;

            fencei_mem <= 'b0;

            pc_mem <= 'b0;

            mem_wb_valid <= 'b0;

            skip_ref_mem <= 'b0;

            is_ebreak_lsu <= 'b0;

        end
        else if(exu_mem_shake_hands) begin
            exu_mem_shake_hands <= 1'b0;
        end
        else begin
          fencei_mem <= 'b0;
        end
    end




    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
            arlen <= 'b0;
            arburst <= 'b0;
            arid <= 'b0;
            axi_busy <= 'b0;
        end
        else if(arvalid && arready) begin
            arvalid <= 1'b0;
        end
        else if(mren_mem) begin
            if(!structural_adventure) begin
                axi_busy <= 'b1;
                arvalid <= 1'b1;
                arid <= 4'b0;
                arlen <= {{7{1'b0}},get_arlen};
                `ifdef ysyxSoCFull
                if(araddr >= 32'h10000000 && araddr < 32'h10001000
                    || araddr >= 32'h10011000 && araddr < 32'h10011008
                    || araddr >= 32'h21000000 && araddr < 32'h21200000
                    || araddr >= 32'h02000000 && araddr < 32'h02000008
                    || araddr >= 32'hc0000000 && araddr < 32'hffffffff
                    ) begin
                    // skip uart keyboard etc.
                    skip_ref_mem <= 'b1;
                    // `ifdef CONFIG_DPIC
                    // npc_difftest_skip_ref();
                    // `endif
                end
                `endif
                `ifdef ysyx_24080020_NPC
                if(araddr >= 32'ha00003f8 && araddr < 32'ha0000400
                    || araddr >= 32'ha0000048 && araddr < 32'ha0000050
                    ) begin
                    // skip uart keyboard etc.
                    skip_ref_mem <= 'b1;
                    // `ifdef CONFIG_DPIC
                    // npc_difftest_skip_ref();
                    // `endif
                end
                `endif

                mren_mem <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
            mrdata_mem <= 32'b0;
            arlen_cnt <= 1'b0;
        end
        else if(rvalid && rready) begin
            rready <= 1'b0;
        end
        else if(rvalid && rlast) begin
            // finish all read
            axi_busy <= 'b0;
            rready <= 1'b1;
            finish_read <= 1'b1;
            if(rresp != 2'b0) begin
                // rresp fault;
                `ifdef CONFIG_DPIC
                $display("rresp not be 0b00, ERROR");
                `endif
            end
            else begin
                if(arlen_cnt == 1'b0) begin
                    // just read once
                    rdata1 <= rdata;
                    rdata2 <= 32'b0;
                end
                else begin
                    // second read
                    rdata2 <= rdata;
                end

                arlen_cnt <= 1'b0;
            end
            `ifdef CONFIG_DPIC
            if(rready)
              statistics_lsu_get_data();
            `endif
        end
        else if(rvalid && !rlast) begin
            // muti read, and the first read
            rready <= 1'b1;
            if(rresp == 2'b0) begin
                rdata1 <= rdata;
                rdata2 <= 32'b0;
                arlen_cnt <= 1'b1;
            end
            else begin
                // read error
                mrdata_mem <= 32'hffffffff;
                mem_wb_valid <= 1'b1;
                `ifdef CONFIG_DPIC
                $display("rresp not be 0b00, ERROR");
                `endif
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            finish_read <= 1'b0;
        end
        else if(finish_read) begin
            // finish all read
            if(mrtype_mem) begin
                // zero extension
                case(mrlen_mem)
                    4'd1:   mrdata_mem <= {{24{1'b0}}, rdata_shift[7:0]};
                    4'd2:   mrdata_mem <= {{16{1'b0}}, rdata_shift[15:0]};
                    4'd4:   mrdata_mem <= rdata_shift;
                    default: mrdata_mem <= 32'hffffffff;
                endcase
            end
            else begin
                // signed extension
                case(mrlen_mem)
                    4'd1:   mrdata_mem <= {{24{rdata_shift[7]}}, rdata_shift[7:0]};
                    4'd2:   mrdata_mem <= {{16{rdata_shift[15]}}, rdata_shift[15:0]};
                    4'd4:   mrdata_mem <= rdata_shift;
                    default: mrdata_mem <= 32'hffffffff;
                endcase
            end

            mem_wb_valid <= 1'b1;
            finish_read <= 1'b0;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            awvalid <= 1'b0;
            awlen <= 'b0;
        end
        else if(awvalid_reg && awready) begin
            awvalid <= 1'b0;

            // mwen_mem <= 1'b0;
        end
        else if(mwen_mem) begin
            awvalid <= 1'b1;
            awid <= 4'b0;
            awlen <= {{7{1'b0}}, get_awlen};

            mwen_mem <= 1'b0;
            `ifdef ysyxSoCFull
            if(awaddr >= 32'h10000000 && awaddr < 32'h10001000
                || awaddr >= 32'h10011000 && awaddr < 32'h10011008
                || awaddr >= 32'h21000000 && awaddr < 32'h21200000
                || awaddr >= 32'h02000000 && awaddr < 32'h02000008
                || awaddr >= 32'hc0000000 && awaddr < 32'hffffffff
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
                // `ifdef CONFIG_DPIC
                // npc_difftest_skip_ref();
                // `endif
            end
            `endif
            `ifdef ysyx_24080020_NPC
            if(awaddr >= 32'ha00003f8 && awaddr < 32'ha0000400
                || awaddr >= 32'ha0000048 && awaddr < 32'ha0000050
                ) begin
                // skip uart keyboard etc.
                skip_ref_mem <= 'b1;
                // `ifdef CONFIG_DPIC
                // npc_difftest_skip_ref();
                // `endif
            end


            `endif

        end
        else begin
            awvalid <= awvalid;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            awlen_cnt <= 1'b0;
            wlast <= 1'b0;
            wstrb <= 'b0;
            wdata <= 'b0;
        end
        else if(awlen_cnt == awlen[0] && awlen_cnt == 1'b0 && mwen_mem) begin
            // just once write
            wvalid <= 1'b1;
            wlast <= 1'b1;
            wdata <= wdata_1;
            wstrb <= wstrb_1;
        end
        else if(!awlen_cnt && awlen[0] && mwen_mem) begin
            // muti write, the first write
            wvalid <= 1'b1;
            awlen_cnt <= 1'b1;
            wdata <= wdata_1;
            wstrb <= wstrb_1;
            wlast <= 1'b0;
            // $display("first write");
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            wvalid <= 1'b0;
        end
        else if(wvalid_reg && wready && wlast && !awlen[0]) begin
            // finish once
            wvalid <= 1'b0;
        end
        else if(wvalid_reg && wready && wlast && awlen[0]) begin
            // finish all
            wvalid <= 1'b0;
            // wlast <= 1'b0;
            awlen_cnt <= 1'b0;
        end
        else if(wvalid_reg && wready && awlen_cnt && awlen[0]) begin
            // next W
            // muti write, the second write
            wlast <= 1'b1;
            wvalid <= 1'b1;
            wdata <= wdata_2;
            wstrb <= wstrb_2;
            // $display("second write");
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            bready <= 1'b0;
        end
        else if(bvalid && bready) begin
            bready <= 'b0;
        end
        else if(bvalid) begin
            bready <= 1'b1;

            // b_fin <= 1'b1;
            mem_wb_valid <= 1'b1;
            if(bresp != 2'b0) begin
                `ifdef CONFIG_DPIC
                $error("the bresp are not 2'b0");
                `endif
            end
        end
        // else begin
        //     bready <= 1'b0;
        // end
    end

endmodule

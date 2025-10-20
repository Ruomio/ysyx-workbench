`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_SRAM(
    input clk,
    input rst,

`ifdef CONFIG_DPIC
    // xbar -> sram: verilator
    // AXI-lite
    input arvalid,
    input [`ysyx_24080020_WIDTH-1:0] araddr,
    input [3:0] arid,
    input [7:0] arlen,
    input [2:0] arsize,
    input [1:0] arburst,
    output reg arready,

    input rready,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg [1:0] rresp,
    output reg [3:0] rid,
    output reg rlast,
    output reg rvalid,

    input [`ysyx_24080020_WIDTH-1:0] awaddr,
    input awvalid,
    input [3:0] awid,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst,
    output reg awready,

    input [`ysyx_24080020_WIDTH-1:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    input wlast,
    output reg wready,

    output reg [1:0] bresp,
    output reg bvalid,
    output reg [3:0] bid,
    input bready

`else
    // sram -> extern axi: yosys iverilog
    input arvalid,
    input [`ysyx_24080020_WIDTH-1:0] araddr,
    input [3:0] arid,
    input [7:0] arlen,
    input [2:0] arsize,
    input [1:0] arburst,
    output arready,

    input rready,
    output [`ysyx_24080020_WIDTH-1:0] rdata,
    output [1:0] rresp,
    output [3:0] rid,
    output rlast,
    output rvalid,

    input [`ysyx_24080020_WIDTH-1:0] awaddr,
    input awvalid,
    input [3:0] awid,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst,
    output awready,

    input [`ysyx_24080020_WIDTH-1:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    input wlast,
    output wready,

    output [1:0] bresp,
    output bvalid,
    output [3:0] bid,
    input bready,

    output out_arvalid,
    output [`ysyx_24080020_WIDTH-1:0] out_araddr,
    output [3:0] out_arid,
    output [7:0] out_arlen,
    output [2:0] out_arsize,
    output [1:0] out_arburst,
    input out_arready,

    output out_rready,
    input [`ysyx_24080020_WIDTH-1:0] out_rdata,
    input [1:0] out_rresp,
    input [3:0] out_rid,
    input out_rlast,
    input out_rvalid,

    output [`ysyx_24080020_WIDTH-1:0] out_awaddr,
    output out_awvalid,
    output [3:0] out_awid,
    output [7:0] out_awlen,
    output [2:0] out_awsize,
    output [1:0] out_awburst,
    input out_awready,

    output [`ysyx_24080020_WIDTH-1:0] out_wdata,
    output [3:0] out_wstrb,
    output out_wvalid,
    output out_wlast,
    input out_wready,

    input [1:0] out_bresp,
    input out_bvalid,
    input [3:0] out_bid,
    output out_bready
`endif
);
`ifdef CONFIG_DPIC
    import "DPI-C" function void printf_info();
    import "DPI-C" function int read_memory(input int addr, input int len);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);

    reg [`ysyx_24080020_WIDTH-1:0] paddr_r_base, paddr_r, paddr_w;
    reg [`ysyx_24080020_WIDTH-1:0] write_data;
    reg read_en, write_en, b_en;
    // reg read_before_write;

    reg [5:0] ar_cnt, aw_cnt, w_cnt;
    reg [5:0] r_cnt, b_cnt;

    reg [7:0] arlen_cnt;
    reg [31:0] w_rdata;



    wire [`ysyx_24080020_WIDTH-1:0] wstrb_full;
    wire [5:0] lfsr;    // the number of delay cycle

    assign wstrb_full = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};
    assign lfsr = 6'd32;

    // AR
    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
            read_en <= 1'b0;
            ar_cnt <= 6'b0;
            paddr_r_base <= 'b0;
        end
        else if(rready && rvalid && rlast) begin
            read_en <= 1'b0;
        end
        else if(arvalid && arready) begin
            arready <= 'b0;
        end
        else if(arvalid) begin
            if(ar_cnt < lfsr) begin
                ar_cnt <= ar_cnt + 6'b1;
            end
            else begin
                paddr_r_base <= {araddr[31:2],2'b0};
                read_en <= 1'b1;
                arready <= 1'b1;

                ar_cnt <= 6'b0;
            end
        end
    end

    // R
    always @(posedge clk) begin
        if(!rst) begin
            rvalid <= 1'b0;
            rresp <= 2'b0;
            rdata <= 32'b0;
            arlen_cnt <= 'b0;
            paddr_r <= 'b0;
            r_cnt <= 'b0;
            rlast <= 'b0;
        end
        else if(arvalid && arready) begin
            paddr_r <= paddr_r_base;
        end
        else if(read_en) begin
            if(r_cnt < lfsr) begin
                r_cnt <= r_cnt + 6'b1;
            end
            else if(rready && rvalid) begin
                rvalid <= 1'b0;
                rresp <= 2'b0;
                if(rlast) begin
                    r_cnt <= 'b0;
                    arlen_cnt <= 'b0;
                    rlast <= 'b0;
                end
                else begin
                    arlen_cnt <= arlen_cnt + 'b1;
                    if(arburst == 'b00) begin
                        paddr_r <= paddr_r;
                    end
                    else if(arburst == 'b01) begin
                        paddr_r <= paddr_r + 'd4;
                    end
                end
            end
            else if((arlen_cnt <= arlen) && !rvalid) begin
                `ifdef CONFIG_DPIC
                // printf_info();
                rdata <= read_memory(paddr_r, 32'd4);
                `endif

                rvalid <= 1'b1;
                rresp <= 2'b0;
                if(arlen_cnt == arlen) begin
                    rlast <= 1'b1;
                end
            end
        end
    end


    // AW
    always @(posedge clk) begin
        if(!rst) begin
            awready <= 1'b0;
            paddr_w <= 'b0;
            aw_cnt <= 'b0;
        end
        else if(awvalid && awready) begin
            awready <= 1'b0;
        end
        else if(awvalid) begin
            if(aw_cnt < lfsr) begin
                aw_cnt <= aw_cnt + 6'b1;
            end
            else begin
                paddr_w <= {awaddr[31:2], 2'b0};
                awready <= 1'b1;

                aw_cnt <= 6'b0;
            end
        end
    end

    // W
    always @(posedge clk) begin
        if(!rst) begin
            w_cnt <= 6'b0;
            wready <= 1'b0;
            write_en <= 1'b0;
            w_rdata <= 'b0;

            b_en <= 1'b0;
            write_data <= 'b0;
        end
        else if(b_en && b_cnt >= lfsr) begin
            b_en <= 'b0;
        end
        else if(wvalid && wready) begin
            wready <= 'b0;
            w_cnt <= 6'b0;
            write_en <= 1'b0;
        end
        else if(wvalid) begin
            if(w_cnt < lfsr) begin
                w_cnt <= w_cnt + 6'b1;
                if(w_cnt == lfsr - 'b1) begin
                    `ifdef CONFIG_DPIC
                    // printf_info();
                    w_rdata <= read_memory({awaddr[31:2], 2'b0}, 32'd4);
                    `endif
                end
            end
            else begin
                if(!write_en) begin
                    write_data <= wdata & wstrb_full | (w_rdata & ~wstrb_full);
                    write_en <= 1'b1;
                end
                else if(!wready) begin
                    `ifdef CONFIG_DPIC
                    write_memory(paddr_w, 32'd4, write_data);
                    `endif
                    b_en <= 1'b1;

                    wready <= 1'b1;
                end
            end
        end
    end

    // B
    always @(posedge clk) begin
        if(!rst) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
            b_cnt <= 'b0;
        end
        else if(b_en) begin
            if(b_cnt < lfsr) begin
                b_cnt <= b_cnt + 6'b1;
            end
            else begin
                bvalid <= 1'b1;
                bresp <= 2'b0;

                b_cnt <= 6'b0;
            end
        end
        else if(bready && bvalid) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
        end
    end

`else
    // iverilog simulation, sram on testbench file

    assign out_arvalid = arvalid;
    assign out_araddr = araddr;
    assign out_arid = arid;
    assign out_arlen = arlen;
    assign out_arsize = arsize;
    assign out_arburst = arburst;
    assign arready = out_arready;

    assign out_rready = rready;
    assign rdata = out_rdata;
    assign rresp = out_rresp;
    assign rid = out_rid;
    assign rlast = out_rlast;
    assign rvalid = out_rvalid;

    assign out_awaddr = awaddr;
    assign out_awvalid = awvalid;
    assign out_awid = awid;
    assign out_awlen = awlen;
    assign out_awsize = awsize;
    assign out_awburst = awburst;
    assign awready = out_awready;

    assign out_wdata = wdata;
    assign out_wstrb = wstrb;
    assign out_wvalid = wvalid;
    assign out_wlast = wlast;
    assign wready = out_wready;

    assign bresp = out_bresp;
    assign bvalid = out_bvalid;
    assign bid = out_bid;
    assign out_bready = bready;

`endif
endmodule

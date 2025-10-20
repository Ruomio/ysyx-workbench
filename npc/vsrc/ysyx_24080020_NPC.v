module ysyx_24080020_NPC(
    input wire clk,
    input wire rst
);

wire io_interrupt;
// master
// AR
wire io_master_arready;
wire io_master_arvalid;
wire [31:0] io_master_araddr;
wire [3:0] io_master_arid;
wire [7:0] io_master_arlen;
wire [2:0] io_master_arsize;
wire [1:0] io_master_arburst;
// R
wire io_master_rready;
wire io_master_rvalid;
wire [1:0] io_master_rresp;
wire [31:0] io_master_rdata;
wire io_master_rlast;
wire [3:0] io_master_rid;
// AW
wire io_master_awready;
wire io_master_awvalid;
wire [31:0] io_master_awaddr;
wire [3:0] io_master_awid;
wire [7:0] io_master_awlen;
wire [2:0] io_master_awsize;
wire [1:0] io_master_awburst;
// W
wire io_master_wready;
wire io_master_wvalid;
wire [31:0] io_master_wdata;
wire [3:0] io_master_wstrb;
wire io_master_wlast;
// B
wire io_master_bready;
wire io_master_bvalid;
wire [1:0] io_master_bresp;
wire [3:0] io_master_bid;

// slave
// AR
wire io_slave_arready;
wire io_slave_arvalid;
wire [31:0] io_slave_araddr;
wire [3:0] io_slave_arid;
wire [7:0] io_slave_arlen;
wire [2:0] io_slave_arsize;
wire [1:0] io_slave_arburst;
// R
wire io_slave_rready;
wire io_slave_rvalid;
wire [1:0] io_slave_rresp;
wire [31:0] io_slave_rdata;
wire io_slave_rlast;
wire [3:0] io_slave_rid;
// AW
wire io_slave_awready;
wire io_slave_awvalid;
wire [31:0] io_slave_awaddr;
wire [3:0] io_slave_awid;
wire [7:0] io_slave_awlen;
wire [2:0] io_slave_awsize;
wire [1:0] io_slave_awburst;
// W
wire io_slave_wready;
wire io_slave_wvalid;
wire [31:0] io_slave_wdata;
wire [3:0] io_slave_wstrb;
wire io_slave_wlast;
// B
wire io_slave_bready;
wire io_slave_bvalid;
wire [1:0] io_slave_bresp;
wire [3:0] io_slave_bid;



ysyx_24080020 u_cpu(
    .clk(clock),
    .rst(!reset),

    .io_interrupt(io_interrupt),

    // master
    // AR
    .io_master_arready(io_master_arready),
    .io_master_arvalid(io_master_arvalid),
    .io_master_araddr(io_master_araddr),
    .io_master_arid(io_master_arid),
    .io_master_arlen(io_master_arlen),
    .io_master_arsize(io_master_arsize),
    .io_master_arburst(io_master_arburst),
    // R
    .io_master_rready(io_master_rready),
    .io_master_rvalid(io_master_rvalid),
    .io_master_rresp(io_master_rresp),
    .io_master_rdata(io_master_rdata),
    .io_master_rlast(io_master_rlast),
    .io_master_rid(io_master_rid),
    // AW
    .io_master_awready(io_master_awready),
    .io_master_awvalid(io_master_awvalid),
    .io_master_awaddr(io_master_awaddr),
    .io_master_awid(io_master_awid),
    .io_master_awlen(io_master_awlen),
    .io_master_awsize(io_master_awsize),
    .io_master_awburst(io_master_awburst),
    // W
    .io_master_wready(io_master_wready),
    .io_master_wvalid(io_master_wvalid),
    .io_master_wdata(io_master_wdata),
    .io_master_wstrb(io_master_wstrb),
    .io_master_wlast(io_master_wlast),
    // B
    .io_master_bready(io_master_bready),
    .io_master_bvalid(io_master_bvalid),
    .io_master_bresp(io_master_bresp),
    .io_master_bid(io_master_bid),

    // slave
    // AR
    .io_slave_arready(io_slave_arready),
    .io_slave_arvalid(io_slave_arvalid),
    .io_slave_araddr(io_slave_araddr),
    .io_slave_arid(io_slave_arid),
    .io_slave_arlen(io_slave_arlen),
    .io_slave_arsize(io_slave_arsize),
    .io_slave_arburst(io_slave_arburst),
    // R
    .io_slave_rready(io_slave_rready),
    .io_slave_rvalid(io_slave_rvalid),
    .io_slave_rresp(io_slave_rresp),
    .io_slave_rdata(io_slave_rdata),
    .io_slave_rlast(io_slave_rlast),
    .io_slave_rid(io_slave_rid),
    // AW
    .io_slave_awready(io_slave_awready),
    .io_slave_awvalid(io_slave_awvalid),
    .io_slave_awaddr(io_slave_awaddr),
    .io_slave_awid(io_slave_awid),
    .io_slave_awlen(io_slave_awlen),
    .io_slave_awsize(io_slave_awsize),
    .io_slave_awburst(io_slave_awburst),
    // W
    .io_slave_wready(io_slave_wready),
    .io_slave_wvalid(io_slave_wvalid),
    .io_slave_wdata(io_slave_wdata),
    .io_slave_wstrb(io_slave_wstrb),
    .io_slave_wlast(io_slave_wlast),
    // B
    .io_slave_bready(io_slave_bready),
    .io_slave_bvalid(io_slave_bvalid),
    .io_slave_bresp(io_slave_bresp),
    .io_slave_bid(io_slave_bid)
);


    ysyx_24080020_SRAM u_sram(
        .clk(clk),
        .rst(rst),

        .arvalid(io_master_arvalid),
        .araddr(io_master_araddr),
        .arid(io_master_arid),
        .arlen(io_master_arlen),
        .arsize(io_master_arsize),
        .arburst(io_master_arburst),
        .arready(io_master_arready),

        .rdata(io_master_rdata),
        .rresp(io_master_rresp),
        .rvalid(io_master_rvalid),
        .rid(io_master_rid),
        .rlast(io_master_rlast),
        .rready(io_master_rready),

        .awaddr(io_master_awaddr),
        .awvalid(io_master_awvalid),
        .awid(io_master_awid),
        .awlen(io_master_awlen),
        .awsize(io_master_awsize),
        .awburst(io_master_awburst),
        .awready(io_master_awready),

        .wdata(io_master_wdata),
        .wstrb(io_master_wstrb),
        .wvalid(io_master_wvalid),
        .wlast(io_master_wlast),
        .wready(io_master_wready),

        .bresp(io_master_bresp),
        .bvalid(io_master_bvalid),
        .bid(io_master_bid),
        .bready(io_master_bready)
    );

endmodule

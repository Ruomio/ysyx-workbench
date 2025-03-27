`include "ysyx_24080020_IR.v"
`include "ysyx_24080020_DEFINE.v"

`timescale 1ps/1ps
module iCacheTest;

    reg clk;
    reg rst;
    reg if_en;
    reg [`ysyx_24080020_WIDTH-1:0] addr;
    
    reg [31:0] cnt;

    reg [`ysyx_24080020_WIDTH-1:0] inst;
    reg inst_fin;

    // axi-lite
    reg arvalid;
    reg [1:0] arburst;
    reg [2:0] arsize;
    reg [3:0] arid;
    reg [7:0] arlen;
    reg [`ysyx_24080020_WIDTH-1:0] araddr;
    reg arready;

    reg rvalid;
    reg rlast;
    reg [1:0] rresp;
    reg [3:0] rid; 
    reg [`ysyx_24080020_WIDTH-1:0] rdata;
    reg rready;

    wire [31:0] raddr_direct;
    reg [31:0] rdata_direct;

    initial begin
        clk = 1'b0;
        rst = 1'b0;
        addr = 'b0;
        if_en = 'b0;

        #100 rst = 1'b1;

        #100 addr = 32'h0;
        #100 arvalid = 1'b1;

    end

    always #5 clk = ~clk;



    assign raddr_direct = addr;

    always @(posedge clk) begin
        if(!rst) begin
            cnt <= 'b0;
        end
        else if(cnt == 32'd100) begin
            // rst <= 1'b0;
        end
        else begin
            cnt <= cnt + 'b1;
        end

    end




    `ifdef FORMAL
    always @(posedge clk) begin
        if(!rst) begin

        end
        else if(rvalid) begin
            assume(rst);

            assert(rdata_direct == inst);
        end
    end
    `endif







    ysyx_24080020_IR u_ir(
        .clk(clk),
        .rst(rst),
        .if_en(if_en),
        .addr(addr),

        .inst(inst),
        .inst_fin(inst_fin),

        .arvalid(arvalid),
        .arburst(arburst),
        .arsize(arsize),
        .arid(arid),
        .arlen(arlen),
        .araddr(araddr),
        .arready(arready),

        .rvalid(rvalid),
        .rlast(rlast),
        .rresp(rresp),
        .rid(rid), 
        .rdata(rdata),
        .rready(rready)
    );

    Memory u_memory(
        .clk(clk),
        .rst(rst),

        .raddr_direct(raddr_direct),
        .rdata_direct(rdata_direct),

        .arvalid(arvalid),
        .arburst(arburst),
        .arsize(arsize),
        .arid(arid),
        .arlen(arlen),
        .araddr(araddr),
        .arready(arready),

        .rvalid(rvalid),
        .rlast(rlast),
        .rresp(rresp),
        .rid(rid), 
        .rdata(rdata),
        .rready(rready)
    );


endmodule


module Memory(
    input clk,
    input rst,

    input [31:0] raddr_direct,
    output reg [31:0] rdata_direct,
    // axi-lite
    input arvalid,
    input [1:0] arburst,
    input [2:0] arsize,
    input [3:0] arid,
    input [7:0] arlen,
    input [`ysyx_24080020_WIDTH-1:0] araddr,
    output reg arready,

    output reg rvalid,
    output reg rlast,
    output reg [1:0] rresp,
    output reg [3:0] rid, 
    output reg [`ysyx_24080020_WIDTH-1:0] rdata,
    input rready
);

    localparam msize = 128;

    reg [31:0] mem [0 : (msize/4) -1];

    reg [31:0] paddr;
    reg r_en;


    always @(posedge clk) begin
        if(!rst || rst) begin
            for(integer i = 0; i < msize/4; i = i + 1) begin
                mem[i] <= 32'h00000000 + (1 << i);
            end

        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            arready <= 'b0;
 

            paddr <= 'b0;
            r_en <= 'b0;
        end
        else if(arvalid) begin
            paddr <= araddr;
            arready <= 1'b1;

            r_en <= 'b1;
        end
        else begin
            arready <= 'b0;
            r_en <= 'b0;
        end
    end
    always @(posedge clk) begin
        if(!rst) begin
           rvalid <= 'b0;
            rlast <= 'b0;
            rresp <= 'b0;
            rid <= 'b0;
            rdata <= 'b0;
        end
        else if(rready) begin
            rvalid <= 'b0;
            rlast <= 'b0;

        end
        else if(r_en) begin
            rvalid <= 'b1;
            rlast <= 'b1;
            rdata <= mem[paddr];
        end
    end



    assign rdata_direct = mem[raddr_direct];
endmodule
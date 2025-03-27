`include "ysyx_24080020_IR.v"
`include "ysyx_24080020_DEFINE.v"
module iCacheTest(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin,

    // axi-lite
    output reg arvalid,
    output reg [1:0] arburst,
    output reg [2:0] arsize,
    output reg [3:0] arid,
    output reg [7:0] arlen,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr,
    input arready,

    input rvalid,
    input rlast,
    input [1:0] rresp,
    input [3:0] rid, 
    input [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg rready

);
    wire [31:0] raddr_direct;
    reg [31:0] rdata_direct;


    assign raddr_direct = addr;

    always @(posedge clk) begin
        if(!rst) begin
        end

    end




    always @(*) begin
        if(inst_fin) begin

            assert(rdata_direct == inst);
        end

    end








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
    output [31:0] rdata_direct,
    // axi-lite
    input reg arvalid,
    input reg [1:0] arburst,
    input reg [2:0] arsize,
    input reg [3:0] arid,
    input reg [7:0] arlen,
    input reg [`ysyx_24080020_WIDTH-1:0] araddr,
    output arready,

    output rvalid,
    output rlast,
    output [1:0] rresp,
    output [3:0] rid, 
    output [`ysyx_24080020_WIDTH-1:0] rdata,
    input reg rready
);

    localparam msize = 128;

    reg [31:0] mem [0 : msize/4];

    reg [31:0] paddr;
    reg r_en;


    always @(posedge clk) begin
        if(!rst) begin
            for(integer i = 0; i < msize/4; i = i + 1) begin
                if(i == 0) begin
                    mem[i] <= 32'h00000000;
                end
                else begin
                    mem[i] <= mem[i-1] + 32'h00000004;
                end
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
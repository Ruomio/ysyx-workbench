`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_CLINT(
    input clk,
    input rst,

    input [31:0] araddr,
    input arvalid,
    input [3:0] arid,
    input [7:0] arlen,
    input [2:0] arsize,
    input [1:0] arburst,
    output reg arready,

    input rready,
    output reg rvalid,
    output reg [1:0] rresp,
    output reg [31:0] rdata,
    output reg [3:0] rid,
    output reg rlast,

    input awvalid,
    input [31:0] awaddr,
    input [3:0] awid,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst,
    output reg awready,

    input wvalid,
    input [3:0] wstrb,
    input [31:0] wdata,
    input wlast,
    output reg wready,

    input bready,
    output reg bvalid,
    output reg [3:0] bid,
    output reg [1:0] bresp
);

    reg [31:0] timel;
    reg [31:0] timeh;
    reg ren;

    wire l_or_h;

    assign l_or_h = araddr == `ysyx_24080020_CLINT_ADDR ? 1'b0 : 1'b1;

    always @(posedge clk) begin
        if(!rst) begin
            timel <= 32'b0;
            timeh <= 32'b0;
        end
        else if(timel == 32'hffffffff) begin
            timeh <= timeh + 32'b1;
        end
        else begin
            timel <= timel + 32'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
            ren <= 1'b0;
        end
        else if(arvalid) begin
            arready <= 1'b1;
            ren <= 1'b1;
        end
        else begin
            arready <= arready;
            ren <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            rdata <= 32'b0;
            rresp <= 2'b0;
            rvalid <= 'b0;
            rid <= 'b0;
            rlast <= 'b0;
        end
        else if(ren && rvalid == 1'b0) begin
            rdata <= l_or_h == 1'b0 ? timel : timeh;
            rresp <= 2'b0;
            rvalid <= 1'b1;
            rlast <= 1'b1;
        end
        else if(rready && rvalid) begin
            rvalid <= 1'b0;
        end
        else begin
            rvalid <= rvalid;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            awready <= 1'b0;
        end
        else if(awvalid) begin
            awready <= 1'b1;
            `ifdef CONFIG_DPIC
            $display("clint should not be writen, NOW!");
            `endif
        end
        else begin
            awready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            wready <= 1'b0;
        end
        else if(wvalid) begin
            wready <= 1'b1;
        end
        else begin
            wready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
            bid <= 'b0;
        end
        else if(wready && bvalid == 1'b0) begin
            bvalid <= 1'b1;
            bresp <= 2'b1;
        end
        else if(bready) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
        end
        else begin
            bvalid <= bvalid;
            bresp <= bresp;
        end
    end

endmodule

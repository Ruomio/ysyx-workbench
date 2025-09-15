`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_UART(
    input clk,
    input rst,

    // axi-lite
    input [31:0] araddr,
    input arvalid,
    input [3:0] arid,
    input [7:0] arlen,
    input [2:0] arsize,
    input [1:0] arburst,
    output reg arready,

    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    output reg [3:0] rid,
    output reg rlast,
    input rready,

    input [31:0] awaddr,
    input awvalid,
    input [3:0] awid,
    input [7:0] awlen,
    input [2:0] awsize,
    input [1:0] awburst,
    output reg awready,

    input [31:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    input wlast,
    output reg wready,

    input bready,
    output reg [1:0] bresp,
    output reg [3:0] bid,
    output reg bvalid
);

    reg wfin, ren;

    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
            ren <= 1'b0;
        end
        else if(ren) begin
            ren <= 1'b0;
        end
        else if(arvalid && arready) begin
            arready <= 1'b0;
        end
        else if(arvalid) begin
            `ifdef CONFIG_DPIC
            $display("UART should not be read, NOW!");
            `endif
            arready <= 1'b1;
            ren <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            rdata <= 32'b0;
            rresp <= 2'd1;
            rvalid <= 1'b1;
        end
        else if(ren) begin
            rdata <= 32'b0;
            rresp <= 2'd1;
            rvalid <= 1'b1;

        end
        else if(rready) begin
            rvalid <= 1'b0;
            rresp <= 2'b0;
        end
        else begin
            rdata <= rdata;
            rresp <= rresp;
            rvalid <= rvalid;
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            awready <= 1'b0;
        end
        else begin
            if(awvalid) begin
                awready <= 1'b1;

            end
            else begin
                awready <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            wfin <= 1'b0;
            wready <= 1'b0;
        end
        else if(wvalid && wready) begin
            `ifdef CONFIG_DPIC
            // $write("%c", wdata[7:0]);
            // $fflush();
            `endif
            `ifdef __ICARUS__
            $write("%c", wdata[7:0]);
            $fflush();
            `endif
            if(wfin) wfin <= 'b0;
        end
        else if(wvalid) begin
            wready <= 1'b1;

            wfin <= 1'b1;
        end
        else begin
            wready <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            bresp <= 2'b0;
            bvalid <= 1'b0;
        end
        else if(wfin) begin
            bresp <= 2'b0;
            bvalid <= 1'b1;

            // wfin <= 1'b0;
        end
        else if(bready) begin
            bresp <= 2'b0;
            bvalid <= 1'b0;
        end
        else begin
            bresp <= bresp;
            bvalid <= bvalid;
        end
    end


endmodule

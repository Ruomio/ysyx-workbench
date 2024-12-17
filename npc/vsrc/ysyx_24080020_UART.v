`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_UART(
    input clk,
    input rst,

    // axi-lite
    input [31:0] araddr,
    input arvalid,
    output reg arready,

    output reg [31:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,
    input rready,

    input [31:0] awaddr,
    input awvalid,
    output reg awready,

    input [31:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    output reg wready,

    input bready,
    output reg [1:0] bresp,
    output reg bvalid
);

    reg wfin, ren;

    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
        end
        else begin
            if(arvalid) begin
                $display("UART should not be read, NOW!");
                arready <= 1'b1;
                ren <= 1'b1;
            end
            else begin
                arready <= 1'b0;
            end
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            ren <= 1'b0;
        end
        else if(ren) begin
            rdata <= 32'b0;
            rresp <= 2'd1;
            rvalid <= 1'b1;

            ren <= 1'b0;
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
            $write("%c", wdata[7:0]);
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

            wfin <= 1'b0;
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

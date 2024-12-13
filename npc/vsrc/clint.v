`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_CLINT(
    input clk,
    input rst,

    input [31:0] araddr,
    input arvalid,
    output arready,

    input rready,
    output rvalid,
    output [1:0] rresp,
    output [31:0] rdata,

    input awvalid,
    input [31:0] awaddr,
    output awready,

    input wvalid,
    input [3:0] wstrb,
    input [31:0] wdata,
    output wready,

    input bready,
    output bvalid,
    output [1:0] bresp
);

    reg [31:0] timel;
    reg [31:0] timeh;
    reg ren;

    wire l_or_h;

    assign l_or_h = araddr == `ysyx_24080020_RTC_ADDR ? 1'b0 : 1'b1;

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
        end
        else if(ren && rvalid == 1'b0) begin
            rdata <= l_or_h == 1'b0 ? timel : timeh;
            rresp <= 2'b0;
            rvalid <= 1'b1;
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
            $display("clint should not be writen, NOW!");
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

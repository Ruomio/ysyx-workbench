`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_IR(
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

    always @(posedge clk) begin
        if(!rst) begin
            arvalid <= 1'b0;
        end
        else if(if_en) begin
            arvalid <= 1'b1;
            araddr <= addr;
            arid <= 4'b0;
            arlen <= 8/b0;
            arsize <= 3'b10;
            arburst <<= 2'b0;
        end
        else if(arready && arvalid) begin
            arvalid <= 1'b0;
        end
        else begin
            arvalid <= arvalid;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            rready <= 1'b0;
        end
        else if(rvalid) begin
            rready <= 1'b1;

            inst <= rdata;
            inst_fin <= 1'b1;

            // rresp != 2'b0 : error
        end
        else begin
            rready <= 1'b0;
            inst <= inst;
            inst_fin <= 1'b0;
        end
    end


endmodule

`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input if_en,
    input [`ysyx_24080020_WIDTH-1:0] addr,

    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg inst_fin,

    // axi-lite
    output reg arvalid,
    output reg [`ysyx_24080020_WIDTH-1:0] araddr,
    input arready,

    input rvalid,
    input [1:0] rresp,
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

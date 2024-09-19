`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [3:0] mlen,
    input [`ysyx_24080020_WIDTH-1:0] mraddr,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr,
    input [`ysyx_24080020_WIDTH-1:0] mdata,
    input wen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata

);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);

    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;
    reg [`ysyx_24080020_WIDTH-1:0] last_waddr;
   

    always @(posedge clk) begin
        if(!rst) begin
            mrdata <= `ysyx_24080020_WIDTH;
        end
        else if(wen && mwaddr != last_waddr) begin
            write_memory(mwaddr, {{28{1'b0}},mlen}, mdata);
            last_waddr <= mwaddr;
        end
        else begin
            mrdata <= mrdata;
        end
        
        if(mraddr != last_raddr) begin
            mrdata <= read_memory(mraddr, {{28{1'b0}}, mlen});
            last_raddr <= mraddr;
        end
        else begin
            mrdata <= mrdata;
        end

    end


endmodule
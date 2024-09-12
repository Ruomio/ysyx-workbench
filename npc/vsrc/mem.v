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
   

    always @(posedge clk) begin
        if(!rst) begin
            mrdata <= 32'b0;
        end
        else if(wen && mwaddr != 32'b0) begin
            write_memory(mwaddr, {{28{1'b0}},mlen}, mdata);
        end
        else begin
            mrdata <= mraddr;
        end
        
        if(mraddr != 32'b0) begin
            mrdata <= read_memory(mraddr, {{28{1'b0}}, mlen});
        end
        else begin
            mrdata <= mrdata;
        end

    end


endmodule
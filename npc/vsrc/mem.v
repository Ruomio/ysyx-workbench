`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] pc_len,
    input [3:0] mlen,
    input [`ysyx_24080020_WIDTH-1:0] mraddr,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr,
    input [`ysyx_24080020_WIDTH-1:0] mwdata,
    input mwen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata,
    output reg [`ysyx_24080020_WIDTH-1:0] inst

);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);

    reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;
    reg [`ysyx_24080020_WIDTH-1:0] last_waddr;
   

    // read mrdata
    always @(posedge clk) begin
        if(!rst) begin
            mrdata <= 32'b0;
            last_raddr <= 32'b0;
        end
        else if(mraddr != last_raddr) begin
            mrdata <= read_memory(mraddr, {{28{1'b0}}, mlen});
            last_raddr <= mraddr;
        end
        else begin
            mrdata <= mrdata;
        end

    end

    // read inst
    always @(posedge clk) begin
        if(!rst) begin
            inst <= 32'b0;
            last_pc <= 32'b0;
        end
        else if(pc != last_pc) begin
            inst <= read_memory(pc, {{28{1'b0}}, mlen});
            last_pc <= pc;
        end
        else begin
            inst <= inst;
        end

    end

    // write
    always @(posedge clk) begin
        if(!rst) begin
            last_waddr <= 32'b0;
        end
        else if(mwen && mwaddr != last_waddr) begin
            write_memory(mwaddr, {{28{1'b0}},mlen}, mwdata);
            last_waddr <= mwaddr;
        end

    end


endmodule
`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [3:0] mlen,
    input [`ysyx_24080020_WIDTH-1:0] maddr,
    input [`ysyx_24080020_WIDTH-1:0] mdata,
    input wen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata

);
    // import "DPI-C" function void init_memory(input int memory[]);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);
   
    // reg [`ysyx_24080020_WIDTH-1:0] memory[0:1023];     // 4KB

    always @(posedge clk) begin
        if(!rst) begin
            mrdata <= 32'b0;
        end
        else if(wen) begin
            write_memory(maddr, {32{1;b0}}|mlen, mdata);
        end
        else begin
            mrdata <= read_memory(maddr, {32{1;b0}}|mlen);
        end

    end


endmodule
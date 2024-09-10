`include "vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] maddr,
    input [`ysyx_24080020_WIDTH-1:0] mdata,
    input wen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata

);
    import "DPI-C" function void init_memory(int memory[]);
    // import "DPI-C" function void write_memory(output uint32_t *memory);


    reg [`ysyx_24080020_WIDTH-1:0] memory[1023:0];     // 4KB

    always @(posedge clk) begin
        if(!rst) begin
            // memory[0] <= 32'hFFF00093; //  addi   x1, x0, -1;
            // memory[1] <= 32'hFFF00113; //  addi   x2, x0, -1;
            // memory[2] <= 32'hFFF00193; //  addi   x3, x0. -1;
            // memory[3] <= 32'hFFF00203; //  addi   x4, 0x, -1;
            // memory[4] <= 32'h00010073; //  ebreak;
            init_memory(memory);

            mrdata <= 32'b0;
        end
        else if(wen) begin
            memory[maddr - `ysyx_24080020_MBASE] <= mdata;
        end
        else begin
            mrdata <= memory[maddr - `ysyx_24080020_MBASE];
        end

    end


endmodule
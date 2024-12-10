`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] pc_len,
    input [3:0] mrlen,
    input [3:0] mwlen,
    input [`ysyx_24080020_WIDTH-1:0] mraddr,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr,
    input [`ysyx_24080020_WIDTH-1:0] mwdata,
    input mwen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata,
    output reg [`ysyx_24080020_WIDTH-1:0] inst

);
    // import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    // import "DPI-C" function int read_memory(input int addr, input int len);

    reg [31:0] all_sram [511:0];

    reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;
   

    // reg [`ysyx_24080020_WIDTH-1:0] instMem [255:0];
    // reg [`ysyx_24080020_WIDTH-1:0] dataMem [255:0];

    // wire [7:0] idx, idx_read, idx_write;

    // wire [31:0] idx_tmp, idx_read_tmp, idx_write_tmp;

    // assign idx_tmp = (pc - 32'h80000000);
    // assign idx_read_tmp = (mraddr - 32'h80000000);
    // assign idx_write_tmp = (mwaddr - 32'h80000000);

    // assign idx = idx_tmp[7:0];
    // assign idx_read = idx_read_tmp[7:0];
    // assign idx_write = idx_write_tmp[7:0];

    // read mrdata
    always @(mraddr or mrlen or rst) begin
        if(!rst) begin
            mrdata = 32'b0;
        end
        else if(mraddr != 32'b0) begin
            // mrdata = read_memory(mraddr, {{28{1'b0}}, mrlen});
            mrdata = all_sram[mraddr];
            // mrdata = dataMem[idx_read];
        end
        else begin
            mrdata = 32'b0;
        end

    end

    // read inst
    always @(pc or pc_len or rst) begin
        if(!rst) begin
            inst <= 32'b0;
            last_pc <= 32'b0;
        end
        else if(pc != last_pc) begin
            // inst <= read_memory(pc, {{28{1'b0}}, pc_len});
            inst <= all_sram[pc];
            // inst <= instMem[idx];
            last_pc <= pc;
        end
        else begin
            inst <= inst;
        end

    end

    // write
    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(mwen) begin
            // write_memory(mwaddr, {{28{1'b0}},mwlen}, mwdata);
            all_sram[mwaddr] <= mwdata;
            // dataMem[idx_write] <= mwdata;
        end

    end


endmodule
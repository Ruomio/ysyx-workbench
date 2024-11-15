`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_MEM(
    input clk,
    input rst,
    input exu_mem_valid,
    input reg_mem_ready,
    input [3:0] mrlen,
    input [3:0] mwlen,
    input [`ysyx_24080020_WIDTH-1:0] mraddr,
    input [`ysyx_24080020_WIDTH-1:0] mwaddr,
    input [`ysyx_24080020_WIDTH-1:0] mwdata,
    input mwen,
    output reg [`ysyx_24080020_WIDTH-1:0] mrdata,
    output reg mem_exu_ready,
    output reg mem_reg_valid

);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    import "DPI-C" function int read_memory(input int addr, input int len);

    // reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    // reg [`ysyx_24080020_WIDTH-1:0] last_raddr;

    reg state = 1'b0; // 0: idle;   1: wait_ready

    always @(posedge clk) begin
        if(!state) begin
            if(mem_reg_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(reg_mem_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if(exu_mem_valid) begin
            if(mem_reg_valid) mem_exu_ready <= 1'b0;
            else mem_exu_ready <= 1'b1;
        end
        else if(reg_mem_ready && !state) begin
            mem_reg_valid <= 1'b0;
        end
        else begin
            mem_reg_valid <= 1'b1;
            mem_exu_ready <= 1'b0;
        end

    end
   

    // read mrdata
    always @(mraddr or mrlen or rst) begin
        if(!rst) begin
            mrdata <= 32'b0;
        end
        else if(mraddr != 32'b0 && !state && reg_mem_ready) begin
            mrdata <= read_memory(mraddr, {{28{1'b0}}, mrlen});
        end
        else begin
            mrdata <= mrdata;
        end

    end

    // write
    always @(posedge clk) begin
        if(!rst) begin
        end
        else if(mwen && reg_mem_ready && !state) begin
            write_memory(mwaddr, {{28{1'b0}},mwlen}, mwdata);
        end

    end


endmodule
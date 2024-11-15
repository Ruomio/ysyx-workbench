`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input pc_ir_valid,
    input idu_ir_ready,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] pc_len,
    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg ir_pc_ready,
    output reg ir_idu_valid

);
    import "DPI-C" function int read_memory(input int addr, input int len);

    // reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;

    reg state = 1'b0; // 0: idle;   1: wait_ready

    always @(posedge clk) begin
        if(!state) begin
            if(ir_idu_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(idu_ir_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end
   

    // read inst
    always @(posedge clk) begin
        if(!rst) begin
            inst <= 32'b0;
            ir_idu_valid <= 1'b0;
        end
        else if(pc_ir_valid) begin
            if(ir_idu_valid) ir_pc_ready <= 1'b0;
            else ir_pc_ready <= 1'b1;
        end
        else if(idu_ir_ready && !state) begin
            inst <= read_memory(pc, {{28{1'b0}}, pc_len});
            ir_idu_valid <= 1'b0;
        end
        else begin
            ir_idu_valid <= 1'b1;
            ir_pc_ready <= 1'b0;
        end

    end

endmodule
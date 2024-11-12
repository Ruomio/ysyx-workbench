`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_IR(
    input clk,
    input rst,
    input pc_ir_valid,
    input reg_ir_ready,
    input [`ysyx_24080020_WIDTH-1:0] pc,
    input [3:0] pc_len,
    output reg [`ysyx_24080020_WIDTH-1:0] inst,
    output reg ir_pc_ready,
    output reg ir_reg_valid

);
    import "DPI-C" function int read_memory(input int addr, input int len);

    // reg [`ysyx_24080020_WIDTH-1:0] last_pc;
    reg [`ysyx_24080020_WIDTH-1:0] last_raddr;

    reg state = 1'b0; // 0: idle;   1: waite_ready

    always @(posedge clk) begin
        if(!state) begin
            if(ir_reg_valid) state <= 1'b1;
            else state <= 1'b0;
        end
        else begin
            if(reg_ir_ready) state <= 1'b0;
            else state <= 1'b1;
        end
    end
   

    // read inst
    always @(posedge clk) begin
        if(!rst) begin
            inst <= 32'b0;
            ir_pc_ready <= 1'b1;
        end
        else if(pc_ir_valid) begin
            ir_reg_valid <= 1'b1;
            ir_pc_ready <= 1'b1;
        end
        else if(reg_ir_ready) begin
            inst <= read_memory(pc, {{28{1'b0}}, pc_len});
        end
        else begin
            inst <= inst;
            ir_reg_valid <= 1'b0;
            ir_pc_ready <= 1'b0;
        end

    end

endmodule
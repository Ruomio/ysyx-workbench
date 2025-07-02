`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_FORWARD(
    input clk,
    input rst,

    input [4:0] rs1_idu,
    input [4:0] rs2_idu,

    input [4:0] rd_exu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_exu,

    input [4:0] rd_lsu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_lsu,
    input is_load,
    input [`ysyx_24080020_WIDTH-1:0] mrdata,
    input fin_load,

    input [4:0] rd_wbu,
    input [`ysyx_24080020_WIDTH-1:0] rd_data_wbu,

    output reg need_stall,
    output need_stall_imme,
    output reg [`ysyx_24080020_WIDTH-1:0] rd_data1_forward,
    output reg [`ysyx_24080020_WIDTH-1:0] rd_data2_forward,
    output reg rs1_conflict,
    output reg rs2_conflict
);
    reg is_load_next;

    assign rs1_conflict = ((rs1_idu == rd_exu) || (rs1_idu == rd_lsu) || (rs1_idu == rd_wbu)) && (rs1_idu != 'b0);
    assign rs2_conflict = ((rs2_idu == rd_exu) || (rs2_idu == rd_lsu) || (rs2_idu == rd_wbu)) && (rs2_idu != 'b0);

    assign rd_data1_forward = rs1_conflict ?
                                rs1_idu == rd_exu ? rd_data_exu :
                                rs1_idu == rd_lsu ? is_load ? mrdata : rd_data_lsu :
                                rs1_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : 'b0;

    assign rd_data2_forward = rs2_conflict ?
                                rs2_idu == rd_exu ? rd_data_exu :
                                rs2_idu == rd_lsu ? is_load ? mrdata : rd_data_lsu :
                                rs2_idu == rd_wbu ? rd_data_wbu :
                                'b0
                            : 'b0;


    assign need_stall_imme = is_load;

    always @(posedge clk) begin
        if(!rst) begin
            need_stall <= 'b0;
        end
        else if(fin_load) begin
            need_stall <= 'b0;
        end
        else if(is_load && !is_load_next) begin
            need_stall <= 'b1;
        end

    end

    always @(posedge clk) begin
        if(!rst) begin
            is_load_next <= 'b0;
        end
        else if(is_load) begin
            is_load_next <= 'b1;
        end
        else begin
            is_load_next <= 'b0;
        end

    end


endmodule

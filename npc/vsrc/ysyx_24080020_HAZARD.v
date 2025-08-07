module ysyx_24080020_HAZARD(
    input clk,
    input rst,

    // Structural adventures, between ifu and lsu
    input arvalid_AND_arready,
    input inst_fin,
    output reg structural_adventure,

    // Data adventures, between ifu and {idu, exu, wbu}
    input [`ysyx_24080020_REG_WIDTH-1:0] rs1_idu,
    input [`ysyx_24080020_REG_WIDTH-1:0] rs2_idu,
    input [`ysyx_24080020_REG_WIDTH-1:0] rd_exu,
    input [`ysyx_24080020_REG_WIDTH-1:0] rd_lsu,
    input [`ysyx_24080020_REG_WIDTH-1:0] rd_wbu,
    output reg data_adventure,

    // control adventures, between ifu and exu
    input is_dnpc,
    input exu_lsu_shake_hands,
    output reg control_adventure
);

    reg en;

    always @(posedge clk) begin
        if(!rst) begin
            structural_adventure <= 'b0;
        end
        else if(inst_fin) begin
            structural_adventure <= 'b0;
        end
        else if(arvalid_AND_arready) begin
            structural_adventure <= 'b1;
        end
    end

    assign data_adventure = (((rs1_idu == rd_exu) || (rs1_idu == rd_lsu) || (rs1_idu == rd_wbu)) && (rs1_idu != 'b0))
                         || (((rs2_idu == rd_exu) || (rs2_idu == rd_lsu) || (rs2_idu == rd_wbu)) && (rs2_idu != 'b0));


    always @(posedge clk) begin
        if(!rst) begin
            control_adventure <= 'b0;
        end
        else if(exu_lsu_shake_hands) begin
            control_adventure <= 'b0;
        end
        else if(is_dnpc) begin
            control_adventure <= 'b1;
        end
    end


endmodule

`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_BTB (
    input  wire        clk,
    input  wire        rst_n,

    // pc -> btb
    input wire        in_valid,
    output  wire      in_ready,
    input wire [31:0] pc_addr,
    input wire        in_special,

    // btb -> pc
    output wire        btb_target_valid,
    output wire [31:0] btb_target,

    // update btb when exu are jump inst
    input  wire        is_dnpc,
    input  wire [`ysyx_24080020_WIDTH-1:0] pc_exu,
    input  wire [`ysyx_24080020_WIDTH-1:0] dnpc,

    // btb -> ir
    output wire        out_special_pc,
    output wire [`ysyx_24080020_WIDTH-1:0] out_pc,
    output wire        out_valid,
    input  wire        out_ready
);

//=========================================================================
// 1. 参数与信号（与原文件一致）
//=========================================================================
localparam branch_way   = `ysyx_24080020_BRANCH_WAY;
localparam branch_num   = `ysyx_24080020_BRANCH_NUM;
localparam branch_size  = `ysyx_24080020_BRANCH_SIZE;

localparam branch_num_bits   = $clog2(branch_num);
localparam branch_size_bits  = $clog2(branch_size);
localparam branch_tag_size   = 32 - branch_num_bits - branch_size_bits;
localparam branch_tag_group_size = branch_tag_size * branch_way;
localparam branch_data_group_size = (branch_size << 3) * branch_way;
localparam branch_tag_group_bits = $clog2(branch_tag_group_size);
localparam branch_data_group_bits = $clog2(branch_data_group_size);

wire [branch_num_bits-1:0]   index = is_dnpc ? pc_exu[branch_num_bits+branch_size_bits-1 : branch_size_bits] :
                                               pc_addr[branch_num_bits+branch_size_bits-1 : branch_size_bits];

wire [branch_tag_size-1:0]   tag   = is_dnpc ? pc_exu[31 : branch_num_bits+branch_size_bits] :
                                               pc_addr[31 : branch_num_bits+branch_size_bits];


//=========================================================================
// 2. BTB 表项（仅锁 64 bit）
//=========================================================================
reg [branch_data_group_size-1:0]                target [0:branch_num-1];   // 32 bit
reg [branch_tag_group_size-1:0]                 tag_r [0:branch_num-1];    // tag
reg [branch_way-1:0]                            valid [0:branch_num-1];    // valid bit

// 写指针（FIFO 替换）
reg [branch_way-1:0] fifo_ptr [0:branch_num-1];

//=========================================================================
// 3. 组合逻辑：命中检测 + 目标输出
//=========================================================================
wire [branch_way-1:0] way_hit;
wire        any_hit;
wire [31:0] hit_target;

// 并行比较所有 way
genvar j;
generate
    for (j = 0; j < branch_way; j = j + 1) begin : gen_hit
        // assign way_hit[j] = (tag_r[index][j] == tag) & valid[index][j];
        assign way_hit[j] = (tag_r[index][(j+1)*branch_tag_size-1:j*branch_tag_size] == tag)
                && ((valid[index] & ({ {(branch_way-1){1'b0}}, 1'b1} << j)) != 'b0);
    end
endgenerate

assign any_hit     = |way_hit;
assign hit_target  = target[index][(( {{(branch_data_group_bits-branch_way){1'b0}}, way_hit}+1) << 5)-: 32]; // 多路选择器

// 输出（组合）
assign out_special_pc  = in_special;
assign out_pc              = pc_addr;     // 顺序 PC
// assign correct_pc      = hit_target;         // 预测目标
// assign flush_pipeline  = (any_hit & is_dnpc & (hit_target != pc_exu + 32'd4)) |
//                           (branch_not_taken_exu & any_hit);

assign btb_target_valid = any_hit;
assign btb_target       = hit_target;

//=========================================================================
// 4. 更新逻辑（单拍完成，不等 B）
//=========================================================================
// wire update_en = is_dnpc;
wire [branch_way-1:0] way = fifo_ptr[index];

always @(posedge clk) begin
    if (!rst_n) begin
        for (integer i = 0; i < branch_num; i = i + 1) begin
            // target[i]   <= 32'd0;
            tag_r[i]    <= 'b0;
            valid[i]    <= 'b0;
            fifo_ptr[i] <= 'b0;
        end
    end
    else if (is_dnpc) begin
        // 同一拍完成写
        target[index][ (({ {(branch_data_group_bits-branch_way){1'b0}} , way}+ 'b1) << 5 )-:(branch_size<<3) ] <= dnpc;
        tag_r[index][( { {(branch_tag_size-branch_way){1'b0}}, way} +'b1 )-:branch_tag_size]  <= tag;
        valid[index][1 << way]  <= 1'b1;
        fifo_ptr[index]    <= (fifo_ptr[index] + 1) % branch_way;

    end
end

//=========================================================================
// 5. 经典 valid-ready（单 beat，零状态机）
//=========================================================================
assign out_valid = valid_q_reg;   // 有数据就向下传
assign in_ready  = ~valid_q_reg;

reg                     valid_q_reg;

always @(posedge clk) begin
    if (!rst_n) begin
        valid_q_reg <= 1'b0;
    end
    else if(out_valid & out_ready) begin
        valid_q_reg <= 'b0;
    end
    else if(in_valid & in_ready) begin
        valid_q_reg <= 'b1;
    end
end

//=========================================================================
// 6. DPI-C 调试接口（可选，面积可综合开关）
//=========================================================================
`ifdef CONFIG_DPIC
// always @(posedge clk) begin
// end
`endif

endmodule

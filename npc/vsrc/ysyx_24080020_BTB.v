`include "ysyx_24080020_DEFINE.v"

module ysyx_24080020_BTB(
    input clk,
    input rst,

    input [`ysyx_24080020_WIDTH-1:0] pc_exu,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    output reg [`ysyx_24080020_WIDTH-1:0] predict_pc,

    // bus
    input in_valid,
    output reg in_ready,
    output reg out_valid,
    input out_ready
);

    // BRANCH
    // branchway maybe not the 2^n
    localparam branch_way = `ysyx_24080020_BRANCH_WAY;
    localparam branch_size = `ysyx_24080020_BRANCH_SIZE;
    localparam branch_num = `ysyx_24080020_BRANCH_NUM;

    localparam branch_size_bits = $clog2(branch_size);
    localparam branch_size_shift = $clog2(branch_size << 3);
    localparam branch_num_bits = $clog2(branch_num);

    localparam branch_tag_size = 32 - branch_size_bits - branch_num_bits;
    localparam branch_data_ingroup_width = (branch_size << 3) * branch_way;
    localparam branch_tag_width = branch_tag_size;
    localparam branch_tag_ingroup_width = branch_tag_width * branch_way;
    localparam data_complete_bits = branch_data_ingroup_width - 32;
    localparam tag_complete_bits = branch_tag_ingroup_width - branch_tag_size;

    localparam IDLE = 0;
    localparam JUDGE = IDLE + 1;
    localparam HIT = JUDGE + 1;
    localparam MISS = HIT + 1;
    localparam Done = MISS + 1;  // not use cache, such as sram

    wire [branch_data_ingroup_width-1 : 0] shift_rdata;
    wire [branch_data_ingroup_width-1 : 0] shift_wdata;
    wire [branch_data_ingroup_width-1 : 0] data_mask;

    wire [branch_tag_ingroup_width-1 : 0]  shift_rtag;
    wire [branch_tag_ingroup_width-1 : 0]  shift_wtag;
    wire [branch_tag_ingroup_width-1 : 0]  tag_mask;

    wire [branch_tag_size-1:0]               branch_tag_tmp;
    wire [branch_num_bits-1:0]               branch_index_tmp;
    wire [branch_size_bits-1:0]              branch_offset_tmp;

    wire [branch_tag_size-1:0]               branch_tag_new;
    wire [branch_num_bits-1:0]               branch_index_new;
    wire [branch_size_bits-1:0]              branch_offset_new;

    reg [branch_data_ingroup_width - 1 : 0]  branch_data  [0 : branch_num - 1];
    reg [branch_tag_ingroup_width - 1 : 0]   branch_tag   [0 : branch_num - 1];
    reg [branch_way - 1 : 0]                 branch_valid [0 : branch_num - 1];

    reg [branch_way - 1 : 0]                 fifo_index [0 : branch_num - 1];
    reg [branch_way - 1 : 0]                 tag_index;

    wire [2:0] next_state;

    reg [2:0] current_state;
    reg [`ysyx_24080020_WIDTH-1:0] pc, pc_new;

    logic has_hit;
    logic total_hits [0 : branch_way - 1];
    logic [branch_way-1:0] tmp_tag_index;


    assign branch_tag_tmp = pc_tmp[31 : branch_num_bits+branch_size_bits];
    assign branch_index_tmp = pc_tmp[branch_num_bits+branch_size_bits-1 : branch_size_bits];
    assign branch_offset_tmp = pc_tmp[branch_size_bits-1 : 0];

    assign branch_tag_new = pc_new[31 : branch_num_bits+branch_size_bits];
    assign branch_index_new = pc_new[branch_num_bits+branch_size_bits-1 : branch_size_bits];
    assign branch_offset_new = pc_new[branch_size_bits-1 : 0];

    assign shift_rdata = branch_data[branch_index_tmp] >> ({ {(branch_data_ingroup_width-branch_way){1'b0}}, tag_index} << (branch_size_shift) ) >> ({{(32-branch_size_bits){1'b0}}, branch_offset_tmp} << 3);

    assign shift_wdata = ({{data_complete_bits{1'b0}}, dnpc_new} << (({{(branch_data_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]}) << branch_size_shift) << ({{(32-branch_size_bits){1'b0}}, branch_offset_new} << 3));
    assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(branch_data_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]}) << branch_size_shift) << ({{(32-branch_size_bits){1'b0}}, branch_offset_new} << 3));


    // assign shift_rtag = (branch_tag[branch_index_tmp] >> ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, tag_index} * branch_tag_width)) & ({ {tag_complete_bits{1'b0}}, {branch_tag_width{1'b1}} });

    assign shift_wtag = {{tag_complete_bits{1'b0}}, branch_tag_new} << ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]} * branch_tag_width);
    assign tag_mask = {{tag_complete_bits{1'b0}}, ~{branch_tag_size{1'b0}}} << ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]} * branch_tag_width);


    generate
      genvar j;
      for (j = 0; j < branch_way; j++) begin
          assign total_hits[j] = (branch_tag[branch_index_tmp][(j+1)*branch_tag_width-1:j*branch_tag_width] == branch_tag_tmp) && ((branch_valid[branch_index_tmp] & ({ {(branch_way-1){1'b0}}, 1'b1} << j)) != 'b0);
      end
    endgenerate

    always_comb begin
        tmp_tag_index = 0;
        has_hit = 0;
        for (int i = 0; i < branch_way; i++) begin
            if (total_hits[i]) begin
                has_hit = 'b1;
                tmp_tag_index = i[branch_way-1:0];
            end
        end
    end

    always @(posedge clk or posedge rst) begin
        if (!rst) begin
            current_state <= 'b0;

            for (integer i = 'b0; i < `ysyx_24080020_BRANCH_NUM; i = i + 'b1 ) begin
                branch_data[i]   <= 'b0;
                branch_tag[i]    <= 'b0;
                branch_valid[i]  <= 'b0;
                fifo_index[i]   <= 'b0;
            end
        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case(current_state)
            IDLE: begin
                if(in_valid && in_ready && is_dnpc) begin
                    next_state = JUDGE;
                end else begin
                    next_state = IDLE;
                end
            end
            JUDGE: begin
                if(is_hit) begin
                    next_state = HIT;
                end else begin
                    next_state = MISS;
                end
            end
            HIT: begin
                next_state = Done;
            end
            MISS: begin
                next_state = Done;
            end
            Done: begin
                next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if(current_state == IDLE) begin
            // init
            is_hit <= 'b0;
        end
        else if(current_state == JUDGE) begin
            if(has_hit) begin
                is_hit <= 'b1;
            end
            else begin
                is_hit <= 'b0;
            end
        end
        else if(current_state == HIT) begin
            predict_pc <= shift_rdata[31:0];
        end
        else if(current_state == MISS) begin
            predict_pc <= pc;
        end
        else if(current_state == Done) begin
            out_valid <= 'b1;
        end
    end

    // update BTB
    always @(posedge clk) begin
        if(!rst) begin

            dnpc_tmp <= 'b0;
            is_dnpc_tmp <= 'b0;
        end
        else if(is_dnpc_tmp) begin
            is_dnpc_tmp <= 'b0;
            pc <= pc_new;

            // write BTB
            fifo_index[branch_index_new] <= (fifo_index[branch_index_new] + 'b1) % branch_way;
            branch_tag[branch_index_new] <= branch_tag[branch_index_new] & ~tag_mask | shift_wtag;
            branch_data[branch_index_new] <= (branch_data[branch_index_new] & ~data_mask) | shift_wdata;
            branch_valid[branch_index_new] <= branch_valid[branch_index_new] | (1 << fifo_index[branch_index_new]);

        end
        else if(is_dnpc && !is_dnpc_next) begin
            pc_new <= pc_exu;
            is_dnpc_tmp <= is_dnpc;
            dnpc_tmp <= dnpc;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            is_dnpc_next <= 'b0;
        end
        else if(is_dnpc) begin
            is_dnpc_next <= 'b1;
        end
        else begin
            is_dnpc_next <= 'b0;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            pc_tmp <= 'b0;
            in_ready <= 'b0;
        end
        else if(in_valid && in_ready) begin
            in_ready <= 'b0;
            pc_tmp <= pc;
            btb_busy <= 'b1;
        end
        else if(in_valid && (current_state == IDLE)) begin
            in_ready <= 'b1;
        end
    end

    always @(posedge clk)begin
        if(!rst) begin
            out_valid <= 'b0;
            pc <= `ysyx_24080020_MBASE;
        end
        else if(out_valid && out_ready) begin
            out_valid <= 'b0;
            pc <= pc + 32'd4;
        end
    end
endmodule

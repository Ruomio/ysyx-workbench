`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_BTB(
    input clk,
    input rst,

    input update_pc,

    output btb_hit_,
    // input is_btype,
    input branch_not_taken_exu,
    input [`ysyx_24080020_WIDTH-1:0] pc_exu,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,
    input new_inst,

    output reg out_special_pc,
    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output reg [`ysyx_24080020_WIDTH-1:0] correct_pc,

    output reg flush_pipeline,

    // fence.i
    // input fencei_exu,
    // input fencei_mem,

    // bus
    output reg out_valid,
    input out_ready
);

    `ifdef CONFIG_DPIC
    import "DPI-C" function void statistics_btb_total();
    import "DPI-C" function void statistics_btb_hit();
    import "DPI-C" function void statistics_btb_err_hit();
    `endif

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

    localparam IDLE = 3'd0;
    localparam JUDGE = IDLE + 1;
    localparam HIT = JUDGE + 1;
    localparam MISS = HIT + 1;
    localparam Done = MISS + 1;  // not use cache, such as sram

    wire [branch_data_ingroup_width-1 : 0] shift_rdata;
    wire [branch_data_ingroup_width-1 : 0] shift_wdata;
    wire [branch_data_ingroup_width-1 : 0] data_mask;

    // wire [branch_tag_ingroup_width-1 : 0]  shift_rtag;
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


    wire [`ysyx_24080020_WIDTH-1:0] n_dnpc;
    reg [2:0] next_state;

    reg fin_judge, fin_hit, fin_miss, fin_done, out_en;
    reg next_special_pc;

    reg in_valid;
    reg in_ready;
    reg is_dnpc_tmp, is_dnpc_next, is_hit, update_en, first, skip_once, btb_hit; // , fencei_mem_next;
    reg [2:0] current_state;
    reg [`ysyx_24080020_WIDTH-1:0] pc_new, pc_tmp, predict_pc, dnpc_tmp, hit_pc, hit_target_pc;

    reg has_hit;
    wire total_hits [0 : branch_way - 1];
    reg [branch_way-1:0] tmp_tag_index;

    assign btb_hit_ = btb_hit;

    assign branch_tag_tmp = pc_tmp[31 : branch_num_bits+branch_size_bits];
    assign branch_index_tmp = pc_tmp[branch_num_bits+branch_size_bits-1 : branch_size_bits];
    assign branch_offset_tmp = pc_tmp[branch_size_bits-1 : 0];

    assign branch_tag_new = pc_new[31 : branch_num_bits+branch_size_bits];
    assign branch_index_new = pc_new[branch_num_bits+branch_size_bits-1 : branch_size_bits];
    assign branch_offset_new = pc_new[branch_size_bits-1 : 0];

    assign shift_rdata = branch_data[branch_index_tmp] >> ({ {(branch_data_ingroup_width-branch_way){1'b0}}, tag_index} << (branch_size_shift) ) >> ({{(32-branch_size_bits){1'b0}}, branch_offset_tmp} << 3);

    assign shift_wdata = ({{data_complete_bits{1'b0}}, dnpc_tmp} << (({{(branch_data_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]}) << branch_size_shift) << ({{(32-branch_size_bits){1'b0}}, branch_offset_new} << 3));
    assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(branch_data_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]}) << branch_size_shift) << ({{(32-branch_size_bits){1'b0}}, branch_offset_new} << 3));


    // assign shift_rtag = (branch_tag[branch_index_tmp] >> ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, tag_index} * branch_tag_width)) & ({ {tag_complete_bits{1'b0}}, {branch_tag_width{1'b1}} });

    assign shift_wtag = {{tag_complete_bits{1'b0}}, branch_tag_new} << ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]} * branch_tag_width);
    assign tag_mask = {{tag_complete_bits{1'b0}}, ~{branch_tag_size{1'b0}}} << ({ {(branch_tag_ingroup_width-branch_way){1'b0}}, fifo_index[branch_index_new]} * branch_tag_width);


    assign n_dnpc = pc_exu + 32'd4;

    generate
      genvar j;
      for (j = 0; j < branch_way; j++) begin
          assign total_hits[j] = (branch_tag[branch_index_tmp][(j+1)*branch_tag_width-1:j*branch_tag_width] == branch_tag_tmp) && ((branch_valid[branch_index_tmp] & ({ {(branch_way-1){1'b0}}, 1'b1} << j)) != 'b0);
      end
    endgenerate

    // always_comb begin
    always @(*) begin
        tmp_tag_index = 0;
        has_hit = 0;
        for (integer i = 0; i < branch_way; i++) begin
            if (total_hits[i]) begin
                has_hit = 'b1;
                tmp_tag_index = i[branch_way-1:0];
            end
        end
    end

    always @(posedge clk) begin
        if (!rst) begin
            current_state <= 'b0;

        end else begin
            current_state <= next_state;
        end
    end

    always @(*) begin
        case(current_state)
            IDLE: begin
                if(in_valid && in_ready) begin
                    next_state = JUDGE;
                end else begin
                    next_state = IDLE;
                end
            end
            JUDGE: begin
                if(fin_judge) begin

                    if(has_hit) begin
                        // avoid continuous hit
                        if(!btb_hit) begin
                            next_state = HIT;
                        end
                        else begin
                            next_state = JUDGE;
                        end
                    end else begin
                        next_state = MISS;
                    end
                end
                else begin
                    next_state = JUDGE;
                end
            end
            HIT: begin
                if(fin_hit)
                    next_state = Done;
                else next_state = HIT;
            end
            MISS: begin
                if(fin_miss)
                    next_state = Done;
                else next_state = MISS;
            end
            Done: begin
                if(fin_done)
                    next_state = IDLE;
                else next_state = Done;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    always @(posedge clk) begin
        if(!rst) begin
            out_valid <= 'b0;
            pc <= `ysyx_24080020_MBASE;
            // predict_pc <= 'b0;
            // hit_pc <= 'b0;
            // hit_target_pc <= 'b0;
            btb_hit <= 'b0;
            flush_pipeline <= 'b0;
            // pc_new <= 'b0;
            is_hit <= 'b0;
            tag_index <= 'b0;

            // correct_pc <= 'b0;
            // dnpc_tmp <= 'b0;
            is_dnpc_tmp <= 'b0;

            // state-machine
            // fin_judge <= 'b0;
            // fin_hit <= 'b0;
            // fin_miss <= 'b0;
            // fin_done <= 'b0;

            out_en <= 'b0;
            next_special_pc <= 'b0;
            out_special_pc <= 'b0;

            for (integer i = 'b0; i < `ysyx_24080020_BRANCH_NUM; i = i + 'b1 ) begin
                // branch_data[i]   <= 'b0;
                branch_tag[i]    <= 'b0;
                branch_valid[i]  <= 'b0;
                fifo_index[i]   <= 'b0;
            end
        end
        // flush btb
        // else if(fencei_exu && 1'b0) begin
        //     // need flush pipeline
        //     btb_hit <= 'b0;

        //     predict_pc <= n_dnpc;
        //     // pc <= n_dnpc;
        //     correct_pc <= n_dnpc;

        //     // update_en <= 'b1;
        //     // out_valid <= 'b0;
        //     next_special_pc <= 'b1;

        //     flush_pipeline <= 'b1;
        // end
        // update btb
        else if(is_dnpc_tmp) begin
            is_dnpc_tmp <= 'b0;

            // skip_once <= 'b1;

            // in_valid <= 'b1;
            // update_en <= 'b1;
            // out_valid <= 'b0;

            // pc <= dnpc_tmp;
            predict_pc <= dnpc_tmp;
            correct_pc <= dnpc_tmp;

            next_special_pc <= 'b1;

            btb_hit <= 'b0;


            // write BTB
            fifo_index[branch_index_new] <= (fifo_index[branch_index_new] + 'b1) % branch_way;
            branch_tag[branch_index_new] <= branch_tag[branch_index_new] & ~tag_mask | shift_wtag;
            branch_data[branch_index_new] <= (branch_data[branch_index_new] & ~data_mask) | shift_wdata;
            branch_valid[branch_index_new] <= branch_valid[branch_index_new] | (1 << fifo_index[branch_index_new]);

        end
        // else if(is_dnpc && !is_dnpc_next && is_btype) begin
        //     // btytpe
        //     if(btb_hit) begin
        //         btb_hit <= 'b0;
        //         if((hit_pc != pc_exu) || (dnpc != hit_target_pc)) begin
        //             // lack hit before this hit, need update btb
        //             pc_new <= pc_exu;
        //             dnpc_tmp <= dnpc;
        //             is_dnpc_tmp <= 'b1;
        //             correct_pc <= dnpc;

        //             flush_pipeline <= 'b1;
        //         end
        //         else if((hit_pc == pc_exu) && (dnpc == hit_target_pc)) begin
        //         `ifdef CONFIG_DPIC
        //             statistics_btb_hit();
        //         `endif
        //         end
        //     end
        //     else begin
        //         pc_new <= pc_exu;
        //         dnpc_tmp <= dnpc;
        //         is_dnpc_tmp <= 'b1;
        //         correct_pc <= dnpc;

        //         flush_pipeline <= 'b1;
        //     end

        //     `ifdef CONFIG_DPIC
        //     statistics_btb_total();
        //     `endif

        // end
        else if(is_dnpc && !is_dnpc_next) begin
            // jal or jalr or b-type

            if(btb_hit) begin
                btb_hit <= 'b0;

                if((hit_pc != pc_exu) || (dnpc != hit_target_pc)) begin
                    // ret diff pc, so need update btb
                    pc_new <= pc_exu;
                    dnpc_tmp <= dnpc;
                    is_dnpc_tmp <= 'b1;
                    correct_pc <= dnpc;

                    flush_pipeline <= 'b1;

                end
                `ifdef CONFIG_DPIC
                else if((hit_pc == pc_exu) && (dnpc == hit_target_pc)) begin
                    statistics_btb_hit();
                end
                `endif
            end
            else begin
                pc_new <= pc_exu;
                dnpc_tmp <= dnpc;
                is_dnpc_tmp <= 'b1;
                correct_pc <= dnpc;

                flush_pipeline <= 'b1;

            end
            `ifdef CONFIG_DPIC
            statistics_btb_total();
            `endif
        end
        // else if(!is_dnpc && is_btype && !is_btype_next ) begin
        else if(branch_not_taken_exu && !branch_not_taken_exu_next ) begin
            // error hit: should not jump, but jump
            if(btb_hit | 'b1) begin
                btb_hit <= 'b0;

                if(/* (hit_pc == pc_exu)*/ 'b1) begin
                    // b_type but not jump, so need flush
                    predict_pc <= n_dnpc;
                    // pc <= n_dnpc;
                    correct_pc <= n_dnpc;

                    // update_en <= 'b1;
                    // out_valid <= 'b0;
                    next_special_pc <= 'b1;

                    flush_pipeline <= 'b1;

                    `ifdef CONFIG_DPIC
                        statistics_btb_err_hit();
                    `endif
                end
            end
            else begin
                // `ifdef CONFIG_DPIC
                //     statistics_btb_hit();
                // `endif
            end

        end

        // state-machine
        else begin
            if(current_state == IDLE) begin
                // init
                is_hit <= 'b0;

                fin_judge <= 'b0;
                fin_miss <= 'b0;
                fin_hit <= 'b0;
                fin_done <= 'b0;

                out_en <= 'b0;
                out_valid <= 'b0;

            end
            else if(current_state == JUDGE) begin
                fin_judge <= 'b1;
                if(has_hit) begin
                    is_hit <= 'b1;
                    tag_index <= tmp_tag_index;
                end
                else begin
                    is_hit <= 'b0;
                end
            end
            else if(current_state == HIT) begin
                fin_hit <= 'b1;
                if(!next_special_pc) begin

                    hit_pc <= pc_tmp;
                    hit_target_pc <= shift_rdata[31:0];
                    btb_hit <= 'b1;

                    predict_pc <= shift_rdata[31:0];
                end

            end
            else if(current_state == MISS) begin
                fin_miss <= 'b1;
                if(!next_special_pc) begin
                    predict_pc <= pc + 32'd4;
                end
            end
            else if(current_state == Done) begin

            end
        end

        if(current_state == Done) begin
            if(out_valid && out_ready) begin
                fin_done <= 'b1;
                out_valid <= 'b0;

                pc <= predict_pc;
                if(next_special_pc) begin
                    next_special_pc <= 'b0;
                    out_special_pc <= 'b1;
                end
                else if(out_special_pc) begin
                    out_special_pc <= 'b0;
                end
                if(flush_pipeline) begin
                    flush_pipeline <= 'b0;
                end
            end
            else if(!out_en && !fin_done) begin
                out_en <= 'b1;
                out_valid <= 'b1;
            end

        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            is_dnpc_next <= 'b0;
        end
        else if(new_inst) begin  // muti jump
            is_dnpc_next <= 'b0;
        end
        else if(is_dnpc) begin
            is_dnpc_next <= 'b1;
        end
        else if(!is_dnpc) begin
            is_dnpc_next <= 'b0;
        end
    end
    // always @(posedge clk) begin
    //      if(!rst) begin
    //          is_btype_next <= 'b0;
    //      end
    //      else if(is_btype) begin
    //          is_btype_next <= 'b1;
    //      end
    //      else begin
    //          is_btype_next <= 'b0;
    //      end
    // end

    always @(posedge clk) begin
        if(!rst) begin
            pc_tmp <= 'b0;
            in_ready <= 'b0;
        end
        else if(in_valid && in_ready) begin
            in_ready <= 'b0;
            pc_tmp <= pc;

        end
        else if(current_state == IDLE) begin
            in_ready <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            in_valid <= 'b0;
        end
        else if(in_valid && in_ready) begin
            in_valid <= 'b0;
        end
        else if(update_en) begin
            in_valid <= 'b1;
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            update_en <= 'b1;
        end
        else if(update_en) begin
            update_en <= 'b0;
        end
        else if(update_pc) begin
            update_en <= 'b1;
        end
        else if(is_dnpc_tmp) begin
            update_en <= 'b1;
        end
        // else if(!is_dnpc && is_btype && !is_btype_next && btb_hit) begin
        else if(branch_not_taken_exu && !branch_not_taken_exu_next && btb_hit) begin
            update_en <= 'b1;
        end
        else if(is_dnpc && is_dnpc_next /* && !is_btype */) begin
            update_en <= 'b1;
        end
        // else if(fencei_exu) begin
        //     update_en <= 'b1;
        // end
    end

    reg branch_not_taken_exu_next;
    always @(posedge clk) begin
        if(!rst) begin
            branch_not_taken_exu_next <= 'b0;
        end
        else if(new_inst) begin
            branch_not_taken_exu_next <= 'b0;
        end
        else if(branch_not_taken_exu) begin
            branch_not_taken_exu_next <= 'b1;
        end
        else begin
            branch_not_taken_exu_next <= 'b0;
        end
    end

endmodule

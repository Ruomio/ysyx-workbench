`include "ysyx_24080020_DEFINE.v"
module ysyx_24080020_ICACHE(
  input clk,
  input rst,
  input fencei_exu,

  output reg [`ysyx_24080020_WIDTH-1:0] raddr,

  input special_pc_i,
  output reg special_pc_o,
  // axi from ir
  input arvalid_i,
  input [`ysyx_24080020_WIDTH-1:0] araddr_i,
  input [3:0] arid_i,
  input [7:0] arlen_i,
  input [2:0] arsize_i,
  input [1:0] arburst_i,
  output reg arready_i,

  input rready_i,
  output reg [`ysyx_24080020_WIDTH-1:0] rdata_i,
  output reg [1:0] rresp_i,
  output reg rvalid_i,
  output reg [3:0] rid_i,
  output reg rlast_i,

  // axi to soc
  output reg arvalid_o,
  output reg [`ysyx_24080020_WIDTH-1:0] araddr_o,
  output reg [3:0] arid_o,
  output reg [7:0] arlen_o,
  output reg [2:0] arsize_o,
  output reg [1:0] arburst_o,
  input arready_o,

  output reg rready_o,
  input [`ysyx_24080020_WIDTH-1:0] rdata_o,
  input [1:0] rresp_o,
  input rvalid_o,
  input [3:0] rid_o,
  input rlast_o
);

  `ifdef CONFIG_DPIC
  import "DPI-C" function void statistics_icache_hit();
  import "DPI-C" function void statistics_icache_miss();
  import "DPI-C" function void statistics_dcache_hit();
  `endif
`ifdef USE_ICACHE
`ifdef ICACHE_PIPELINE

  // CACHE
  // cacheway maybe not the 2^n
  localparam cache_way = `ysyx_24080020_CACHE_WAY;
  localparam cache_size = `ysyx_24080020_CACHE_SIZE;
  localparam cache_num = `ysyx_24080020_CACHE_NUM;

  localparam cache_size_bits = $clog2(cache_size);
  localparam cache_size_shift = $clog2(cache_size << 3);
  localparam cache_num_bits = $clog2(cache_num);

  localparam cache_tag_size = 32 - cache_size_bits - cache_num_bits;
  localparam cache_data_ingroup_width = (cache_size << 3) * cache_way;
  localparam cache_tag_width = cache_tag_size;
  localparam cache_tag_ingroup_width = cache_tag_width * cache_way;
  localparam data_complete_bits = cache_data_ingroup_width - 32;
  localparam tag_complete_bits = cache_tag_ingroup_width - cache_tag_size;


  reg fin_r, fin_ar, all_fin, fin_judge, is_hit, update_fifo_index;
  // reg [2:0] current_state, next_state;
  reg [31:0] rdata_tmp, araddr_tmp;

  reg flush_cache;
  reg [cache_num-1:0] num_index;

  reg cache_hit_next;

  wire use_icache;
  // wire in_flash;
  // wire in_mrom;
  // wire in_sdram;

  // integer  i;


  wire [cache_data_ingroup_width-1 : 0] shift_rdata;
  wire [cache_data_ingroup_width-1 : 0] shift_wdata;
  wire [cache_data_ingroup_width-1 : 0] data_mask;

  wire [cache_tag_ingroup_width-1 : 0]  shift_rtag;
  wire [cache_tag_ingroup_width-1 : 0]  shift_wtag;
  wire [cache_tag_ingroup_width-1 : 0]  tag_mask;

  wire                                    cache_hit;
  wire [cache_tag_size-1:0]               cache_tag_tmp;
  wire [cache_num_bits-1:0]               cache_index_tmp;
  wire [cache_size_bits-1:0]              cache_offset_tmp;

  reg [cache_data_ingroup_width - 1 : 0]  cache_data  [0 : cache_num - 1];
  reg [cache_tag_ingroup_width - 1 : 0]   cache_tag   [0 : cache_num - 1];
  reg [cache_way - 1 : 0]                 cache_valid [0 : cache_num - 1];

  reg [cache_way - 1 : 0]                 fifo_index [0 : cache_num - 1];
  // reg [cache_way - 1 : 0]                 tag_index;


  assign cache_tag_tmp = araddr_tmp[31 : cache_num_bits+cache_size_bits];
  assign cache_index_tmp = araddr_tmp[cache_num_bits+cache_size_bits-1 : cache_size_bits];
  assign cache_offset_tmp = araddr_tmp[cache_size_bits-1 : 0];




// bus
  reg s0_s1_valid;
  reg s1_s0_ready;
  reg s1_s2_valid;
  reg s2_s1_ready;
  reg s2_s3_valid;
  reg s3_s2_ready;
  reg s3_s4_valid;
  reg s4_s3_ready;
  reg s0_s1_shake_hands, s1_s2_shake_hands, s2_s3_shake_hands, s3_s4_shake_hands;
  // reg [`ysyx_24080020_WIDTH-1:0] inst_s0;
  // reg [`ysyx_24080020_WIDTH-1:0] rdata_araddr_s0;

  // reg special_pc_tmp;
  reg special_pc_s0;
  // reg special_pc_s0_o;


// s0
    reg [`ysyx_24080020_WIDTH-1:0] araddr_s0;
    reg [7:0] arlen_s0;
    reg [3:0] arid_s0;
    reg [1:0] arburst_s0;
    reg [2:0] arsize_s0;

    always @(posedge clk) begin
        if(!rst) begin
            s0_s1_valid <= 'b0;
            // inst_s0 <= 'b0;
            // special_pc_s0 <= 'b0;
            // special_pc_s0_o <= 'b0;

            // araddr_s0 <= 'b0;
            // arlen_s0 <= 'b0;
            // arid_s0 <= 'b0;
            // arburst_s0 <= 'b0;
            // arsize_s0 <= 'b0;
        end
        else if(s0_s1_valid && s1_s0_ready)begin
            s0_s1_valid <= 'b0;
        end
        else if(arvalid_i && arready_i) begin
            araddr_s0 <= araddr_i;
            arlen_s0 <= arlen_i;
            arid_s0 <= arid_i;
            arburst_s0 <= arburst_i;
            arsize_s0 <= arsize_i;
            special_pc_s0 <= special_pc_i;

            s0_s1_valid <= 'b1;
        end
    end


// s1: calculate tag and judge is hit
  reg [cache_tag_size-1:0]    cache_tag_s1;
  reg [cache_num_bits-1:0]    cache_index_s1;
  reg [cache_size_bits-1:0]   cache_offset_s1;
  reg [`ysyx_24080020_WIDTH-1:0] araddr_s1;

  reg [7:0] arlen_s1;
  reg [3:0] arid_s1;
  reg [1:0] arburst_s1;
  reg [2:0] arsize_s1;

  reg special_pc_s1;

  reg is_hit_s1;
  reg [cache_way-1:0] hit_tag_s1;

  reg has_hit_s1;
  wire total_hits_s1 [0 : cache_way - 1];
  reg [cache_way-1:0] tmp_tag_index_s1;


  generate
    genvar j;
    for (j = 0; j < cache_way; j++) begin
        assign total_hits_s1[j] = (cache_tag[cache_index_s1][(j+1)*cache_tag_width-1:j*cache_tag_width] == cache_tag_s1) && ((cache_valid[cache_index_s1] & ({ {(cache_way-1){1'b0}}, 1'b1} << j)) != 'b0);
    end
  endgenerate

  // always_comb begin
  always @(*) begin
      tmp_tag_index_s1 = 0;
      has_hit_s1 = 0;
      for (integer i = 0; i < cache_way; i++) begin
          if (total_hits_s1[i]) begin
              has_hit_s1 = 'b1;
              tmp_tag_index_s1 = i[cache_way-1:0];
          end
      end
  end

  always @(posedge clk) begin
    if(!rst) begin
      s1_s2_valid <= 'b0;
      s1_s0_ready <= 'b1;

      // araddr_s1 <= 'b0;
      // arlen_s1 <= 'b0;
      // arid_s1 <= 'b0;
      // arburst_s1 <= 'b0;
      // arsize_s1 <= 'b0;

      // cache_tag_s1 <= 'b0;
      // cache_index_s1 <= 'b0;
      // cache_offset_s1 <= 'b0;
      // special_pc_s1 <= 'b0;

      // is_hit_s1 <= 'b0;
      // hit_tag_s1 <= 'b0;
      s0_s1_shake_hands <= 'b0;
    end
    else if(s0_s1_valid && s1_s0_ready) begin
        s1_s0_ready <= 'b0;

        araddr_s1 <= araddr_s0;
        arlen_s1 <= arlen_s0;
        arid_s1 <= arid_s0;
        arburst_s1 <= arburst_s0;
        arsize_s1 <= arsize_s0;
        special_pc_s1 <= special_pc_s0;

        cache_tag_s1 <= araddr_s0[31 : cache_num_bits+cache_size_bits];
        cache_index_s1 <= araddr_s0[cache_num_bits+cache_size_bits-1 : cache_size_bits];
        cache_offset_s1 <= araddr_s0[cache_size_bits-1 : 0];

        s0_s1_shake_hands <= 'b1;
    end
    else if(s0_s1_shake_hands) begin
        s0_s1_shake_hands <= 'b0;

        is_hit_s1 <= has_hit_s1;
        hit_tag_s1 <= tmp_tag_index_s1;

        s1_s2_valid <= 'b1;

        `ifdef CONFIG_DPIC
        if(has_hit_s1) begin
            statistics_icache_hit();
        end
        else begin
            statistics_icache_miss();
        end
        `endif

    end
    else if(s1_s2_valid && s2_s1_ready) begin
        s1_s2_valid <= 'b0;
        s1_s0_ready <= 'b1;
    end
  end


// s2: pass the hit data
  reg [cache_tag_size-1:0]    cache_tag_s2;
  reg [cache_num_bits-1:0]    cache_index_s2;
  reg [cache_size_bits-1:0]   cache_offset_s2;

  reg [cache_way-1:0] hit_tag_s2;

  // logic has_hit;
  // logic total_hits [0 : cache_way - 1];
  // logic [cache_way-1:0] tmp_tag_index;

  reg bubble;
  reg all_fin_ready;
  reg special_pc_s2;
  reg is_hit_s2;

  reg [`ysyx_24080020_WIDTH-1:0] araddr_s2;
  reg [`ysyx_24080020_WIDTH-1:0] inst_s2;

  reg [7:0] arlen_s2;
  reg [3:0] arid_s2;
  reg [1:0] arburst_s2;
  reg [2:0] arsize_s2;


  wire [cache_data_ingroup_width-1 : 0] shift_rdata_s2;
  assign shift_rdata_s2 = cache_data[cache_index_s2] >> ({ {(cache_data_ingroup_width-cache_way){1'b0}}, hit_tag_s2} << (cache_size_shift) ) >> ({{(32-cache_size_bits){1'b0}}, cache_offset_s2} << 3);


  always @(posedge clk) begin
    if(!rst) begin
      s2_s1_ready <= 'b1;
      s2_s3_valid <= 'b0;

      // inst_s2 <= 'b0;

      // araddr_s2 <= 'b0;
      // arlen_s2 <= 'b0;
      // arid_s2 <= 'b0;
      // arburst_s2 <= 'b0;
      // arsize_s2 <= 'b0;
      // bubble <= 'b0;
      // special_pc_s2 <= 'b0;
      s1_s2_shake_hands <= 'b0;

      // is_hit_s2 <= 'b0;
      // hit_tag_s2 <= 'b0;
      // cache_index_s2 <= 'b0;
      // cache_offset_s2 <= 'b0;
      // cache_tag_s2 <= 'b0;
    end
    else if(s1_s2_valid && s2_s1_ready) begin
      s2_s1_ready <= 'b0;

      s1_s2_shake_hands <= 'b1;

      araddr_s2 <= araddr_s1;
      arlen_s2 <= arlen_s1;
      arid_s2 <= arid_s1;
      arburst_s2 <= arburst_s1;
      arsize_s2 <= arsize_s1;

      special_pc_s2 <= special_pc_s1;

      cache_tag_s2 <= cache_tag_s1;
      cache_index_s2 <= cache_index_s1;
      cache_offset_s2 <= cache_offset_s1;


      is_hit_s2 <= is_hit_s1;
      hit_tag_s2 <= hit_tag_s1;
    end
    else if(s1_s2_shake_hands) begin
        s1_s2_shake_hands <= 'b0;

        inst_s2 <= shift_rdata_s2[31:0];

        s2_s3_valid <= 'b1;

    end
    else if(s2_s3_valid && s3_s2_ready) begin
        s2_s3_valid <= 'b0;
        s2_s1_ready <= 'b1;
    end
  end



// s3: axi read and get inst data
    wire [cache_data_ingroup_width-1 : 0] shift_rdata_s3;
    wire [cache_data_ingroup_width-1 : 0] shift_rdata_s3_prev;
    reg [31:0] inst_s3;

    reg [31:0] araddr_s3, araddr_s3_tmp;
    reg [7:0] arlen_s3;
    reg [3:0] arid_s3;
    reg [1:0] arburst_s3;
    reg [2:0] arsize_s3;
    reg [31:0] araddr_s3_base;
    reg special_pc_s3;
    reg [cache_tag_size-1:0] cache_tag_s3;
    reg [cache_num_bits-1:0] cache_index_s3;
    wire [cache_size_bits-1:0] cache_offset_s3, cache_offset_s3_base;
    reg is_hit_s3;
    reg [cache_way-1:0] hit_tag_s3;

    wire [cache_way-1:0] last_fifo_index_s3;

    reg has_hit_s3;
    wire total_hits_s3 [0 : cache_way - 1];


    generate
    genvar i;
    for (i = 0; i < cache_way; i++) begin
        assign total_hits_s3[i] = (cache_tag[cache_index_s3][(i+1)*cache_tag_width-1:i*cache_tag_width] == cache_tag_s3) && ((cache_valid[cache_index_s3] & ({ {(cache_way-1){1'b0}}, 1'b1} << i)) != 'b0);
    end
    endgenerate

    always_comb begin
        has_hit_s3 = 0;
        for (integer i = 0; i < cache_way; i++) begin
            if (total_hits_s3[i]) begin
                has_hit_s3 = 'b1;
            end
        end
    end


    always @(posedge clk) begin
        if(!rst) begin
            s3_s2_ready <= 'b1;
            s2_s3_shake_hands <= 'b0;

            // // araddr_s3 <= 'b0;
            // arlen_s3 <= 'b0;
            // arid_s3 <= 'b0;
            // arburst_s3 <= 'b0;
            // arsize_s3 <= 'b0;

            // araddr_s3_base <= 'b0;
            // special_pc_s3 <= 'b0;

            // cache_tag_s3 <= 'b0;
            // cache_index_s3 <= 'b0;
            // cache_offset_s3 <= 'b0;

            // is_hit_s3 <= 'b0;
            // hit_tag_s3 <= 'b0;

            // inst_s3 <= 'b0;
            arvalid_o <= 'b0;
            // araddr_o <= 'b0;
            // arsize_o <= 'b0;
            // arid_o <= 'b0;
            // arlen_o <= 'b0;
            // arburst_o <= 'b0;
        end
        else if(arvalid_o && arready_o) begin
            arvalid_o <= 'b0;

        end
        else if(s2_s3_shake_hands) begin
            if(is_hit_s3 || has_hit_s3) begin
                // s3_s4_valid <= 'b1;
                s2_s3_shake_hands <= 'b0;
            end
            else begin
                s2_s3_shake_hands <= 'b0;

                arvalid_o <= 'b1;

                // burst trans in sdram
                araddr_o <= araddr_s3_base & ~(cache_size - 32'b1);

                arsize_o <= 'b10;
                arid_o <= 'b0;
                arlen_o <= (cache_size >> 2) - 1;
                arburst_o <= 'b01;

                // araddr_s3 <= araddr_s3 & ~(cache_size - 32'b1) ;
            end
        end
        else if(s2_s3_valid && s3_s2_ready) begin
            s3_s2_ready <= 'b0;
            s2_s3_shake_hands <= 'b1;

            // araddr_s3 <= araddr_s2 & ~(cache_size - 32'b1);
            arlen_s3 <= arlen_s2;
            arid_s3 <= arid_s2;
            arburst_s3 <= arburst_s2;
            arsize_s3 <= arsize_s2;

            araddr_s3_base <= araddr_s2;
            special_pc_s3 <= special_pc_s2;

            cache_tag_s3 <= cache_tag_s2;
            cache_index_s3 <= cache_index_s2;
            // cache_offset_s3 <= cache_offset_s2;
            // inst_s3 <= inst_s2;
            // inst_s3 <= shift_rdata_s3_prev[31:0];
            if(is_hit_s2) begin
                inst_s3 <= inst_s2;
            end
            else if(has_hit_s3) begin
                inst_s3 <= shift_rdata_s3_prev[31:0];
            end

            is_hit_s3 <= is_hit_s2;
            // is_hit_s3 <= (((hit_tag_s2 + 'b1) % cache_way == last_fifo_index_s3 || hit_tag_s2 == last_fifo_index_s3) && cache_index_s3 == cache_index_s2) ? 'b0 : is_hit_s2;
            hit_tag_s3 <= hit_tag_s2;
        end
        else if(s3_s4_valid && s4_s3_ready) begin
            s3_s2_ready <= 'b1;
        end

        if(fin_r) begin
            inst_s3 <= shift_rdata_s3[31:0];
        end
    end

    always @(posedge clk) begin
        if(!rst) begin
            rready_o <= 'b0;
            fin_r <= 'b0;
            araddr_s3 <= 'b0;

            s3_s4_valid <= 'b0;
            // inst_s3 <= 'b0;

            for (integer i = 'b0; i < `ysyx_24080020_CACHE_NUM; i = i + 'b1 ) begin
                cache_data[i]   <= 'b0;
                cache_tag[i]    <= 'b0;
                // cache_valid[i]  <= 'b0;
                fifo_index[i]   <= 'b0;
            end
        end
        else if(s3_s4_valid && s4_s3_ready) begin
            s3_s4_valid <= 'b0;
        end
        else if(s2_s3_shake_hands && (is_hit_s3 || has_hit_s3)) begin
            s3_s4_valid <= 'b1;
        end
        else if(fin_r) begin
            fin_r <= 'b0;
            // inst_s3 <= shift_rdata_s3[31:0];
            fifo_index[cache_index_s3] <= (fifo_index[cache_index_s3] + 'b1) % cache_way;

            s3_s4_valid <= 'b1;
        end
        else if(rvalid_o && rready_o) begin
            rready_o <= 'b0;
            if(rresp_o == 2'b00) begin // OKAY
                // rdata_s3 <= rdata_o;

                // update cache
                cache_data[cache_index_s3] <= (cache_data[cache_index_s3] & ~data_mask) | shift_wdata;

                if(rlast_o) begin
                  fin_r <= 'b1;
                  // araddr_s3 <= {araddr_s3_base[31 : 2], 2'b0};

                  cache_tag[cache_index_s3] <= (cache_tag[cache_index_s3] & ~tag_mask) | shift_wtag;
                  // cache_valid[cache_index_s3] <= cache_valid[cache_index_s3] | (1 << (fifo_index[cache_index_s3]));
                end
                else begin
                  // update araddr to adapt burst transmit, it's for icache parameter
                  araddr_s3 <= araddr_s3 + 2 ** arsize_o;
                end
            end
            else begin
                // error
                `ifdef CONFIG_DPIC
                $error("fetch inst error");
                `endif
            end
        end
        else if(rvalid_o) begin
            rready_o <= 'b1;

            if((cache_index_s2 == cache_index_s3) && (hit_tag_s2 == fifo_index[cache_index_s3]) && is_hit_s2) begin
                fifo_index[cache_index_s3] <= (fifo_index[cache_index_s3] + 'b1) % cache_way;
            end
            else if((cache_index_s1 == cache_index_s3) && (hit_tag_s1 == fifo_index[cache_index_s3]) && is_hit_s1) begin
                fifo_index[cache_index_s3] <= (fifo_index[cache_index_s3] + 'b1) % cache_way;
            end
        end
        else if(s2_s3_valid && s3_s2_ready) begin
            araddr_s3 <= araddr_s2 & ~(cache_size - 32'b1);
        end
    end



    assign last_fifo_index_s3 = (fifo_index[cache_index_s2] + (cache_way - 'b1)) % cache_way;

    assign cache_offset_s3 = araddr_s3[cache_size_bits-1 : 0];
    assign cache_offset_s3_base = araddr_s3_base[cache_size_bits-1 : 0];
    assign shift_rdata_s3 = cache_data[cache_index_s3] >> ({ {(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s3]} << (cache_size_shift) ) >> ({{(32-cache_size_bits){1'b0}}, cache_offset_s3_base} << 3);
    assign shift_rdata_s3_prev = cache_data[cache_index_s2] >> ({ {(cache_data_ingroup_width-cache_way){1'b0}}, last_fifo_index_s3} << (cache_size_shift) ) >> ({{(32-cache_size_bits){1'b0}}, cache_offset_s2} << 3);

    assign shift_wdata = ({{data_complete_bits{1'b0}}, rdata_o} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s3]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_s3} << 3));
    assign data_mask = ({{data_complete_bits{1'b0}}, ~32'b0} << (({{(cache_data_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s3]}) << cache_size_shift) << ({{(32-cache_size_bits){1'b0}}, cache_offset_s3} << 3));

    assign shift_wtag = {{tag_complete_bits{1'b0}}, cache_tag_s3} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s3]} * cache_tag_width);
    assign tag_mask = {{tag_complete_bits{1'b0}}, ~{cache_tag_size{1'b0}}} << ({ {(cache_tag_ingroup_width-cache_way){1'b0}}, fifo_index[cache_index_s3]} * cache_tag_width);


// s4: return inst data from axi
    reg [31:0] inst_s4;
    reg special_pc_s4;
    reg [31:0] raddr_s4;

    always @(posedge clk) begin
        if(!rst) begin
            // rdata_i <= 'b0;
            // raddr <= 'b0;
            s4_s3_ready <= 'b1;
            // raddr_s4 <= 'b0;
            // special_pc_o <= 'b0;
            s3_s4_shake_hands <= 'b0;
            // special_pc_s4 <= 'b0;
            // inst_s4 <= 'b0;
        end
        else if(s3_s4_shake_hands) begin
            s3_s4_shake_hands <= 'b0;

            rdata_i <= inst_s4;
            raddr <= raddr_s4;
            special_pc_o <= special_pc_s4;
        end
        else if(s3_s4_valid && s4_s3_ready) begin
            s4_s3_ready <= 'b0;
            s3_s4_shake_hands <= 'b1;

            raddr_s4 <= araddr_s3_base;
            special_pc_s4 <= special_pc_s3;

            inst_s4 <= inst_s3;
        end
        else if(rvalid_i && rready_i) begin
            s4_s3_ready <= 'b1;
        end
    end

// axi
  // AR
  always @(posedge clk) begin
    if(!rst)begin
      arready_i <= 'b1;
    end
    else if(arvalid_i && arready_i) begin
      arready_i <= 'b0;
      // busy <= 'b0;
    end
    else if(s0_s1_valid && s1_s0_ready) begin
        arready_i <= 'b1;
    end
  end
  // R
  always @(posedge clk) begin
    if(!rst) begin
      rvalid_i <= 'b0;
      rlast_i <= 'b0;
      rresp_i <= 'b0;
      rid_i <= 'b0;
    end
    else if(rready_i && rvalid_i) begin
      rvalid_i <= 'b0;
      rresp_i <= 'b0;
      rlast_i <= 'b0;
    end
    else if(s3_s4_shake_hands) begin
        rvalid_i <= 'b1;
        rlast_i <= 'b1;
        rresp_i <= 'b0;
    end
  end

  always @(posedge clk) begin
    if(!rst) begin
      flush_cache <= 'b0;
      num_index <= 'b0;

      for (integer i = 'b0; i < `ysyx_24080020_CACHE_NUM; i = i + 'b1 ) begin
          cache_valid[i]  <= 'b0;
      end
    end
    else if({{(32-cache_num){1'b0}}, num_index} == cache_num - 'b1) begin
      flush_cache <= 'b0;
    end
    else if(flush_cache) begin
      cache_valid[num_index[cache_num_bits-1:0]] <= {cache_way{1'b0}};
      num_index <= num_index + 'b1;
    end
    else if(fencei_exu && !flush_cache) begin
      flush_cache <= 'b1;
      num_index <= 'b0;
    end
    else if(rvalid_o && rready_o && rlast_o) begin
        cache_valid[cache_index_s3] <= cache_valid[cache_index_s3] | (1 << (fifo_index[cache_index_s3]));
    end
  end


`else       // not pipeline

    //=========================================================================
    // 1. 地址输出（组合，零缓冲）
    //=========================================================================
    assign raddr = araddr_o;           // 直接连 AXI 地址
    assign special_pc_o = special_pc_i; // 直通

    // ====== ICACHE 模式：零状态机 + 单拍完成 ======
    // ---------------------------------------------------------------------
    // 1. 参数（与原文件一致）
    // ---------------------------------------------------------------------
    localparam cache_way   = `ysyx_24080020_CACHE_WAY;
    localparam cache_num   = `ysyx_24080020_CACHE_NUM;
    localparam cache_size  = `ysyx_24080020_CACHE_SIZE;

    localparam index_bits = $clog2(cache_num);
    localparam offset_bits = $clog2(cache_size);
    localparam tag_bits = 32 - index_bits - offset_bits;

    // ---------------------------------------------------------------------
    // 2. 缓存表项（仅锁 64 bit + 4 bit 边带）
    // ---------------------------------------------------------------------
    reg [31:0] cache_data [0:cache_num-1];   // 32 bit 数据
    reg [tag_bits-1:0] cache_tag [0:cache_num-1]; // tag
    reg [cache_way-1:0] cache_valid [0:cache_num-1]; // valid bit
    reg [cache_way-1:0] fifo_ptr [0:cache_num-1];   // FIFO 替换指针

    // ---------------------------------------------------------------------
    // 3. 地址解码（组合）
    // ---------------------------------------------------------------------
    wire [index_bits-1:0] index = araddr_o[index_bits+offset_bits-1 : offset_bits];
    wire [tag_bits-1:0]   tag   = araddr_o[31 : index_bits+offset_bits];

    // ---------------------------------------------------------------------
    // 4. 命中检测（组合，零状态机）
    // ---------------------------------------------------------------------
    wire [cache_way-1:0] way_hit;
    wire        any_hit;
    wire [31:0] hit_data;

    genvar j;
    generate
        for (j = 0; j < cache_way; j = j + 1) begin : gen_hit
            assign way_hit[j] = (cache_tag[index][j] == tag) & cache_valid[index][j];
        end
    endgenerate
    assign any_hit = |way_hit;
    assign hit_data = cache_data[index][way_hit]; // 多路选择器

    // ---------------------------------------------------------------------
    // 5. 输出（组合，零缓冲）
    // ---------------------------------------------------------------------
    assign arvalid_o = arvalid_i;           // 直通 AXI
    assign araddr_o  = araddr_i;
    assign arid_o    = arid_i;
    assign arlen_o   = arlen_i;
    assign arsize_o  = arsize_i;
    assign arburst_o = arburst_i;
    assign arready_i = arready_o;           // 直通 AXI

    assign rready_o  = rready_i;            // 直通 AXI
    assign rdata_i   = rdata_o;             // 直通 AXI
    assign rresp_i   = rresp_o;
    assign rid_i     = rid_o;
    assign rlast_i   = rlast_o;
    assign rvalid_i  = rvalid_o;            // 直通 AXI

    // ---------------------------------------------------------------------
    // 6. 读完成标志（组合，单拍完成）
    // ---------------------------------------------------------------------
    wire rdone = rvalid_o & rlast_o & rready_o;
    wire update_en = rdone;                 // 单拍写表

    // ---------------------------------------------------------------------
    // 7. 写表（单拍完成，不等 B）
    // ---------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < cache_num; i = i + 1) begin
                cache_data[i]   <= 32'd0;
                cache_tag[i]    <= {tag_bits{1'b0}};
                cache_valid[i]  <= {cache_way{1'b0}};
                fifo_ptr[i]     <= {cache_way{1'b0}};
            end
        end
        else if (update_en) begin
            integer way = fifo_ptr[index];
            cache_data[index][(way+1)*32-1 : way*32] <= rdata_o;
            cache_tag[index][(way+1)*tag_bits-1 : way*tag_bits] <= tag;
            cache_valid[index][way] <= 1'b1;
            fifo_ptr[index] <= (fifo_ptr[index] + 1) % cache_way;
        end
        else if (fencei_exu) begin
            for (integer i = 0; i < cache_num; i = i + 1) begin
                cache_valid[i] <= {cache_way{1'b0}};
            end
        end
    end

`endif // `ifdef ICACHE_PIPELINE

`endif  // USE_ICACHE




`ifndef USE_ICACHE


  // assign special_pc_o = special_pc_i;
  always @(posedge clk) begin
    if(!rst)
      special_pc_o <= 'b0;
    else if(arvalid_o && arready_o) begin
      special_pc_o <= special_pc_i;
    end
  end

  // assign raddr = araddr_i;
  always @(posedge clk) begin
      if(!rst) begin
          raddr <= 'b0;
      end
      else if(arvalid_o && arready_o) begin
          raddr <= araddr_o;
      end
  end

  // ====== 非 ICACHE 模式：加 1 级寄存器缓冲, 防止stall造成流水线与axi互相等待的死锁 ======
      reg        next_inst;

      always @(posedge clk) begin
          if (!rst) begin
              next_inst      <= 1'b0;
          end
          else if(rvalid_o & rready_o) begin
              next_inst      <= 'b1;
          end
          else if (arvalid_o & arready_o) begin
              next_inst      <= 'b0;
          end
      end

  // AR
  assign arvalid_o = arvalid_i;
  assign araddr_o = araddr_i;
  assign arid_o = arid_i;
  assign arlen_o = arlen_i;
  assign arburst_o = arburst_i;
  assign arsize_o = arsize_i;
  assign arready_i = arready_o;
  // assign arready_i = next_inst;

  // R
  assign rvalid_i = rvalid_o;
  assign rdata_i = rdata_o;
  assign rresp_i = rresp_o;
  assign rid_i = rid_o;
  assign rlast_i = rlast_o;
  assign rready_o = rready_i;

`endif

endmodule

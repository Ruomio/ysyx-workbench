`timescale 1ns / 1ns

module sim_top;

    reg clock;
    reg reset;


    initial begin
        clock = 'b0;
        forever begin
            #1 clock = ~clock;
        end
    end

    initial begin
        reset = 'b1;
        #20 reset = 'b0;
    end


    initial begin
        // $dumpfile("build/tb_wave.fst"); // 指定 VCD 文件名
        // #200000;
        // $dumpvars(0, sim_top); // 0 表示记录该模块及其所有子模块的所有信号。也可以指定特定层级或信号。
        // #200 $finish;
    end

    localparam memory_len = 1 << 27; // 128M
    reg [7:0] memory [0:memory_len-1];
    reg [128*8-1:0] mem_file;

    // MEM_FILE define in makefile
    initial begin
        // for(int i = 0; i < memory_len; i++)
        //     memory[i] = 'b0;

        // $display("show : %s", `MEM_FILE);
        mem_file = "";
        if ($value$plusargs("MEM_FILE=%s", mem_file)) begin
            $display("[INFO] Loading memory from: %s", mem_file);
        end else begin
            $display("[WARN] No +MEM_FILE= specified, using default: %s", mem_file);
        end
        $readmemh(mem_file, memory);
    end


    wire io_interrupt;

    reg io_master_arready;
        // AR
    wire io_master_arvalid;
    wire [31:0] io_master_araddr;
    wire [3:0] io_master_arid;
    wire [7:0] io_master_arlen;
    wire [2:0] io_master_arsize;
    wire [1:0] io_master_arburst;
        // R
    wire io_master_rready;
    reg io_master_rvalid;
    reg [1:0] io_master_rresp;
    reg [31:0] io_master_rdata;
    reg io_master_rlast;
    reg [3:0] io_master_rid;
        // AW
    reg io_master_awready;
    wire io_master_awvalid;
    wire [31:0] io_master_awaddr;
    wire [3:0] io_master_awid;
    wire [7:0] io_master_awlen;
    wire [2:0] io_master_awsize;
    wire [1:0] io_master_awburst;
        // W
    reg io_master_wready;
    wire io_master_wvalid;
    wire [31:0] io_master_wdata;
    wire [3:0] io_master_wstrb;
    wire io_master_wlast;
        // B
    wire io_master_bready;
    reg io_master_bvalid;
    reg [1:0] io_master_bresp;
    reg [3:0] io_master_bid;

        // slave
        // AR
    wire io_slave_arready;
    wire io_slave_arvalid;
    wire [31:0] io_slave_araddr;
    wire [3:0] io_slave_arid;
    wire [7:0] io_slave_arlen;
    wire [2:0] io_slave_arsize;
    wire [1:0] io_slave_arburst;
        // R
    wire io_slave_rready;
    wire io_slave_rvalid;
    wire [1:0] io_slave_rresp;
    wire [31:0] io_slave_rdata;
    wire io_slave_rlast;
    wire [3:0] io_slave_rid;
        // AW
    wire io_slave_awready;
    wire io_slave_awvalid;
    wire [31:0] io_slave_awaddr;
    wire [3:0] io_slave_awid;
    wire [7:0] io_slave_awlen;
    wire [2:0] io_slave_awsize;
    wire [1:0] io_slave_awburst;
        // W
    wire io_slave_wready;
    wire io_slave_wvalid;
    wire [31:0] io_slave_wdata;
    wire [3:0] io_slave_wstrb;
    wire io_slave_wlast;
        // B
    wire io_slave_bready;
    wire io_slave_bvalid;
    wire [1:0] io_slave_bresp;
    wire [3:0] io_slave_bid;

    // encapsulation to change pins' name
    ysyx_24080020 u_cpu(
        .clock(clock),
        .reset(reset),

        .io_interrupt(io_interrupt),
        // master
        // AR
        .io_master_arready(io_master_arready),
        .io_master_arvalid(io_master_arvalid),
        .io_master_araddr(io_master_araddr),
        .io_master_arid(io_master_arid),
        .io_master_arlen(io_master_arlen),
        .io_master_arsize(io_master_arsize),
        .io_master_arburst(io_master_arburst),
        // R
        .io_master_rready(io_master_rready),
        .io_master_rvalid(io_master_rvalid),
        .io_master_rresp(io_master_rresp),
        .io_master_rdata(io_master_rdata),
        .io_master_rlast(io_master_rlast),
        .io_master_rid(io_master_rid),
        // AW
        .io_master_awready(io_master_awready),
        .io_master_awvalid(io_master_awvalid),
        .io_master_awaddr(io_master_awaddr),
        .io_master_awid(io_master_awid),
        .io_master_awlen(io_master_awlen),
        .io_master_awsize(io_master_awsize),
        .io_master_awburst(io_master_awburst),
        // W
        .io_master_wready(io_master_wready),
        .io_master_wvalid(io_master_wvalid),
        .io_master_wdata(io_master_wdata),
        .io_master_wstrb(io_master_wstrb),
        .io_master_wlast(io_master_wlast),
        // B
        .io_master_bready(io_master_bready),
        .io_master_bvalid(io_master_bvalid),
        .io_master_bresp(io_master_bresp),
        .io_master_bid(io_master_bid),

        // slave
        // AR
        .io_slave_arready(io_slave_arready),
        .io_slave_arvalid(io_slave_arvalid),
        .io_slave_araddr(io_slave_araddr),
        .io_slave_arid(io_slave_arid),
        .io_slave_arlen(io_slave_arlen),
        .io_slave_arsize(io_slave_arsize),
        .io_slave_arburst(io_slave_arburst),
        // R
        .io_slave_rready(io_slave_rready),
        .io_slave_rvalid(io_slave_rvalid),
        .io_slave_rresp(io_slave_rresp),
        .io_slave_rdata(io_slave_rdata),
        .io_slave_rlast(io_slave_rlast),
        .io_slave_rid(io_slave_rid),
        // AW
        .io_slave_awready(io_slave_awready),
        .io_slave_awvalid(io_slave_awvalid),
        .io_slave_awaddr(io_slave_awaddr),
        .io_slave_awid(io_slave_awid),
        .io_slave_awlen(io_slave_awlen),
        .io_slave_awsize(io_slave_awsize),
        .io_slave_awburst(io_slave_awburst),
        // W
        .io_slave_wready(io_slave_wready),
        .io_slave_wvalid(io_slave_wvalid),
        .io_slave_wdata(io_slave_wdata),
        .io_slave_wstrb(io_slave_wstrb),
        .io_slave_wlast(io_slave_wlast),
        // B
        .io_slave_bready(io_slave_bready),
        .io_slave_bvalid(io_slave_bvalid),
        .io_slave_bresp(io_slave_bresp),
        .io_slave_bid(io_slave_bid)
    );


    reg [31:0] paddr_r_base, paddr_r, paddr_w;
    reg [31:0] write_data;
    reg read_en, write_en, b_en;

    reg [5:0] ar_cnt, aw_cnt, w_cnt;
    reg [5:0] r_cnt, b_cnt;

    reg [7:0] arlen_cnt;
    reg [31:0] w_rdata;



    wire [31:0] wstrb_full;
    wire [5:0] lfsr;    // the number of delay cycle

    assign wstrb_full = {{8{io_master_wstrb[3]}}, {8{io_master_wstrb[2]}}, {8{io_master_wstrb[1]}}, {8{io_master_wstrb[0]}}};
    assign lfsr = 6'd32;

    // AR
    always @(posedge clock) begin
        if(reset) begin
            io_master_arready <= 1'b0;
            read_en <= 1'b0;
            ar_cnt <= 6'b0;
            paddr_r_base <= 'b0;
        end
        else if(io_master_rready && io_master_rvalid && io_master_rlast) begin
            read_en <= 1'b0;
        end
        else if(io_master_arvalid && io_master_arready) begin
            io_master_arready <= 'b0;
        end
        else if(io_master_arvalid) begin
            if(ar_cnt < lfsr) begin
                ar_cnt <= ar_cnt + 6'b1;
            end
            else begin
                paddr_r_base <= {io_master_araddr[31:2],2'b0};
                read_en <= 1'b1;
                io_master_arready <= 1'b1;

                ar_cnt <= 6'b0;
            end
        end
    end

    // R
    always @(posedge clock) begin
        if(reset) begin
            io_master_rvalid <= 1'b0;
            io_master_rresp <= 2'b0;
            io_master_rdata <= 32'b0;
            arlen_cnt <= 'b0;
            paddr_r <= 'b0;
            r_cnt <= 'b0;
            io_master_rlast <= 'b0;
        end
        else if(io_master_arvalid && io_master_arready) begin
            paddr_r <= paddr_r_base;
        end
        else if(read_en) begin
            if(r_cnt < lfsr) begin
                r_cnt <= r_cnt + 6'b1;
            end
            else if(io_master_rready && io_master_rvalid) begin
                io_master_rvalid <= 1'b0;
                io_master_rresp <= 2'b0;
                if(io_master_rlast) begin
                    r_cnt <= 'b0;
                    arlen_cnt <= 'b0;
                    io_master_rlast <= 'b0;
                end
                else begin
                    arlen_cnt <= arlen_cnt + 'b1;
                    if(io_master_arburst == 'b00) begin
                        paddr_r <= paddr_r;
                    end
                    else if(io_master_arburst == 'b01) begin
                        paddr_r <= paddr_r + (1<<io_master_arsize);
                    end
                end
            end
            else if(arlen_cnt <= io_master_arlen) begin
                // printf_info();
                // io_master_rdata <= read_memory(paddr_r, 32'd4);
                io_master_rdata <= read_mem_by_bytes(paddr_r, 2'd2);

                io_master_rvalid <= 1'b1;
                io_master_rresp <= 2'b0;
                if(arlen_cnt == io_master_arlen) begin
                    io_master_rlast <= 1'b1;
                end
            end
        end
    end


    // AW
    always @(posedge clock) begin
        if(reset) begin
            io_master_awready <= 1'b0;
            paddr_w <= 'b0;
            aw_cnt <= 'b0;
        end
        else if(io_master_awvalid && io_master_awready) begin
            io_master_awready <= 1'b0;
        end
        else if(io_master_awvalid) begin
            if(aw_cnt < lfsr) begin
                aw_cnt <= aw_cnt + 6'b1;
            end
            else begin
                paddr_w <= {io_master_awaddr[31:2], 2'b0};
                io_master_awready <= 1'b1;

                aw_cnt <= 6'b0;
            end
        end
    end

    // W
    always @(posedge clock) begin
        if(reset) begin
            w_cnt <= 6'b0;
            io_master_wready <= 1'b0;
            write_en <= 1'b0;
            w_rdata <= 'b0;

            b_en <= 1'b0;
            write_data <= 'b0;
        end
        else if(b_en && b_cnt >= lfsr) begin
            b_en <= 'b0;
        end
        else if(io_master_wvalid && io_master_wready) begin
            io_master_wready <= 'b0;
            w_cnt <= 6'b0;
            write_en <= 1'b0;
        end
        else if(io_master_wvalid) begin
            if(w_cnt < lfsr) begin
                w_cnt <= w_cnt + 6'b1;
                if(w_cnt == lfsr - 'b1) begin
                    // printf_info();
                    // w_rdata <= read_memory({awaddr[31:2], 2'b0}, 32'd4);
                    w_rdata <= read_mem_by_bytes({io_master_awaddr[31:2], 2'b0}, 2'd2);
                end
            end
            else begin
                if(!write_en) begin
                    write_data <= io_master_wdata & wstrb_full | (w_rdata & ~wstrb_full);
                    write_en <= 1'b1;
                end
                else if(!io_master_wready) begin
                    // write_memory(paddr_w, 32'd4, write_data);
                    write_mem_by_bytes(paddr_w, 2'b10, write_data);
                    b_en <= 1'b1;

                    io_master_wready <= 1'b1;
                end
            end
        end
    end

    // B
    always @(posedge clock) begin
        if(reset) begin
            io_master_bvalid <= 1'b0;
            io_master_bresp <= 2'b0;
            b_cnt <= 'b0;
        end
        else if(b_en) begin
            if(b_cnt < lfsr) begin
                b_cnt <= b_cnt + 6'b1;
            end
            else begin
                io_master_bvalid <= 1'b1;
                io_master_bresp <= 2'b0;

                b_cnt <= 6'b0;
            end
        end
        else if(io_master_bready && io_master_bvalid) begin
            io_master_bvalid <= 1'b0;
            io_master_bresp <= 2'b0;
        end
    end


    function void write_mem_by_bytes;
        input [31:0] addr;   // 地址（0 ~ 32MB-1）
        input [1:0]  len;    // 长度：1,2,4 字节（len=0 视为1）
        input [31:0] data;   // 要写入的数据

        integer i;
        begin
            for (i = 0; i < (1<<len); i = i + 1) begin
                if ({4'b0, addr[27:0]} + i < memory_len) begin  // 边界检查
                    memory[{4'b0, addr[27:0]} + i] = data[8*i +: 8];  // 小端序：bit[7:0] → {4'b0, addr[27:0]}+0
                end
                else begin
                    $display(" out of range! at: 0x%h", {4'b0, addr[27:0]} + i);
                end
            end
        end
    endfunction

    function [31:0] read_mem_by_bytes;
        input [31:0] addr;  // 地址范围 0 ~ 32MB-1
        input [1:0]  len;   // 0=>1B, 1=>2B, 2=>4B（通常这样编码）

        begin
            case (len)
                2'd0: begin  // 读1字节
                    read_mem_by_bytes = {24'h0, memory[{4'b0, addr[27:0]}]};
                end
                2'd1: begin  // 读2字节（小端序）
                    read_mem_by_bytes = {16'h0, memory[{4'b0, addr[27:0]} + 1], memory[{4'b0, addr[27:0]}]};
                end
                2'd2: begin  // 读4字节（小端序）
                    read_mem_by_bytes = {memory[{4'b0, addr[27:0]} + 3], memory[{4'b0, addr[27:0]} + 2],
                                        memory[{4'b0, addr[27:0]} + 1], memory[{4'b0, addr[27:0]}]};
                end
                default: begin
                    read_mem_by_bytes = 32'h0;
                end
            endcase
        end
        // $display("Get data: 0x%h from: 0x%h", read_mem_by_bytes, addr);
    endfunction


    reg [31:0] pc_delay_cnt;

    always @(posedge clock) begin
        if(reset) begin
            pc_delay_cnt <= 32'h0;
        end
        else if(u_cpu.u_npc.exu.exu_mem_valid && u_cpu.u_npc.exu.mem_exu_ready) begin
            pc_delay_cnt <= 'h0;
        end
        else begin
            pc_delay_cnt <= pc_delay_cnt + 1'b1;
            if(pc_delay_cnt > 32'h200) begin
                $display("EXU lag at pc: 0x%h", u_cpu.u_npc.exu.pc_exu);
                $display("PC delay count exceeded");
                $finish;
            end
        end
    end

endmodule

`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_SRAM(
    input clk,
    input rst,

    // AXI-lite
    input arvalid,
    input [`ysyx_24080020_WIDTH-1:0] araddr,
    output reg arready,

    input rready,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,

    input [`ysyx_24080020_WIDTH-1:0] awaddr,
    input awvalid,
    output reg awready,

    input [`ysyx_24080020_WIDTH-1:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    output reg wready,

    output reg [1:0] bresp,
    output reg bvalid,
    input bready
);
    // import "DPI-C" function void printf_info();
    // import "DPI-C" function int read_memory(input int addr, input int len);
    // import "DPI-C" function void write_memory(input int addr, input int len, input int data);
    reg [31:0] sram [511:0];

    reg [`ysyx_24080020_WIDTH-1:0] paddr;
    reg [`ysyx_24080020_WIDTH-1:0] write_data;
    reg read_en, write_en, b_en;
    reg read_before_write;

    reg [5:0] ar_cnt, aw_cnt, w_cnt;
    reg [5:0] r_cnt, b_cnt;

    integer i;


    wire [`ysyx_24080020_WIDTH-1:0] wstrb_full;
    wire [5:0] lfsr;    // the number of delay cycle

    assign wstrb_full = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};
    assign lfsr = 6'd5;

    always @(posedge clk) begin
        if(!rst) begin
            for(i=32'd0; i<32'd512; i=i+1) begin
                sram[i] <= i;
            end
        end

    end

    // AR
    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
            read_en <= 1'b0;
            ar_cnt <= 6'b0;
        end
        else if(arvalid) begin
            if(ar_cnt < lfsr) begin
                ar_cnt <= ar_cnt + 6'b1;
            end
            else begin
                paddr <= araddr;
                read_en <= 1'b1;
                arready <= 1'b1;

                ar_cnt <= 6'b0;
            end
        end
        else begin
            arready <= 1'b0;
        end

    end

    // R
    always @(posedge clk) begin
        if(!rst) begin
            rvalid <= 1'b0;
            rresp <= 2'b0;
            rdata <= 32'b0;
        end
        else if(read_en) begin
            if(r_cnt < lfsr) begin
                r_cnt <= r_cnt + 6'b1;
            end
            else begin
                // printf_info();
                // rdata <= read_memory(paddr, 32'd4);
                rdata <= sram[paddr];
                if(wvalid) begin
                    read_before_write <= 1'b1;
                    rvalid <= 1'b0;
                    rresp <= 2'b0;
                end
                else begin
                    rvalid <= 1'b1;
                    rresp <= 2'b0;
                    read_en <= 1'b0;
                end
                r_cnt <= 6'b0;
            end
        end
        else if(rready) begin
            rvalid <= 1'b0;
            rresp <= 2'b0;
        end
        else begin
            rvalid <= 1'b0;
            rresp <= rresp;
        end
    end


    // AW
    always @(posedge clk) begin
        if(!rst) begin
            awready <= 1'b0;
        end
        else if(awvalid) begin
            if(aw_cnt < lfsr) begin
                aw_cnt <= aw_cnt + 6'b1;
            end
            else begin
                paddr <= awaddr;
                awready <= 1'b1;

                aw_cnt <= 6'b0;
            end
        end
        else begin
            awready <= 1'b0;
        end
    end

    // W
    always @(posedge clk) begin
        if(!rst) begin
            w_cnt <= 6'b0;
            wready <= 1'b0;
            read_before_write <= 1'b0;
            write_en <= 1'b0;
        end
        else if(wvalid) begin
            if(w_cnt < lfsr) begin
                w_cnt <= w_cnt + 6'b1;
            end
            else begin
                if(!read_before_write) begin
                    read_en <= 1'b1;
                end
                else if(!write_en) begin
                    read_en <= 1'b0;

                    write_data <= wdata & wstrb_full | (rdata & ~wstrb_full);
                    write_en <= 1'b1;
                end
                else if(!wready) begin
                    // write_memory(paddr, 32'd4, write_data);
                    sram[paddr] <= write_data;
                    b_en <= 1'b1;

                    wready <= 1'b1;
                end
                else begin

                    w_cnt <= 6'b0;
                    write_en <= 1'b0;
                    read_before_write <= 1'b0;
                end

            end
        end
        else begin
            wready <= 1'b0;
        end
    end

    // B
    always @(posedge clk) begin
        if(!rst) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
            b_en <= 1'b0;
            w_cnt <= 6'b0;
        end
        else if(b_en) begin
            if(b_cnt < lfsr) begin
                b_cnt <= b_cnt + 6'b1;
            end
            else begin
                bvalid <= 1'b1;
                bresp <= 2'b0;

                b_en <= 1'b0;
                b_cnt <= 6'b0;
            end
        end
        else if(bready) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
        end
        else begin
            bvalid <= 1'b0;
            bresp <= bresp;
        end

    end

endmodule

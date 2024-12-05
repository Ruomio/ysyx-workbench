`include "/home/papillon/Documents/All_codes/ysyx-workbench/npc/vsrc/define.v"
module ysyx_24080020_SRAN(
    input clk,
    input rst,

    input [5:0] lfsr, // the number of delay cycle
    // AXI-lite
    input arvalid,
    input [`ysyx_24080020_WIDTH-1:0] araddr,
    output reg arready,

    input rready,
    output reg [`ysyx_24080020_WIDTH-1:0] rdata,
    output reg [1:0] rresp,
    output reg rvalid,

    input [`ysyx_24080020_WIDTH-1:0] awaddr,
    input awvalid.
    output reg awready,

    input [`ysyx_24080020_WIDTH-1:0] wdata,
    input [3:0] wstrb,
    input wvalid,
    output reg wready,

    output reg [1:0] bresp,
    output reg bvalid,
    input bready,
);

    import "DPI-C" function int read_memory(input int addr, input int len);
    import "DPI-C" function void write_memory(input int addr, input int len, input int data);

    reg [`ysyx_24080020_WIDTH-1:0] paddr;
    reg [`ysyx_24080020_WIDTH-1:0] write_data;
    reg read_en, write_en;
    reg read_before_write;

    reg [5:0] r_cnt;
    reg [5:0] w_cnt;


    wire [`ysyx_24080020_WIDTH-1:0] wstrb_full;

    assign wstrb_full = {{8{wstrb[3]}}, {8{wstrb[2]}}, {8{wstrb[1]}}, {8{wstrb[0]}}};

    // AR
    always @(posedge clk) begin
        if(!rst) begin
            arready <= 1'b0;
            read_en <= 1'b0;
        end
        else if(arvalid) begin
            paddr <= araddr;
            read_en <= 1'b1;
            arready <= 1'b1;
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
                rdata <= read_memory(paddr, 32'd4);
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
            rresp <= 1'b0;
        end
        else begin
            rvalid <= rvalid;
            rresp <= rresp;
        end
    end


    // AW
    always @(posedge clk) begin
        if(!rst) begin
            awready <= 1'b0;
        end
        else if(awvalid) begin
            paddr <= awaddr;
            awready <= 1'b1;
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
                    write_memory(paddr, write_data, 32'd4);

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
        end
        else if(bready) begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
        end
        else if(wready) begin
            bvalid <= 1'b1;
            bresp <= 2'b0;
        end
        else begin
            bvalid <= 1'b0;
            bresp <= 2'b0;
        end

    end


endmodule
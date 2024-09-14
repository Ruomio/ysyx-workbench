`include "vsrc/define.v"
module ysyx_24080020_PC (
    input [`ysyx_24080020_WIDTH-1:0] snpc,
    input is_dnpc,
    input [`ysyx_24080020_WIDTH-1:0] dnpc,

    output reg [`ysyx_24080020_WIDTH-1:0] pc,
    output [`ysyx_24080020_WIDTH-1:0] maddr,
    output [3:0] mlen
);

    // assign pc = !rst ? `ysyx_24080020_WIDTH : (is_dnpc ? dnpc : snpc);
    assign maddr = pc;
    assign mlen = 4'b100;

    always @(*) begin
        // pc = `ysyx_24080020_MBASE;
        if(is_dnpc) begin
            mren = 1'b1;
        end
        else if(snpc != pc) begin
            pc = snpc;
        end
        else begin
            pc = pc;
        end
    end


endmodule
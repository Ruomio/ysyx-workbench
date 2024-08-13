module top
(
    input rst,
    input clk,
    input [7:0] x,
    output [2:0] f,
    output reg [6:0] bcd,
    output reg flag
);

    // reg [31:0] cnt = 32'b0;

    // always @(posedge clk or negedge clk) begin
    //     if(!rst) begin
    //         cnt <= 32'b0;
    //     end
    //     else begin
    //         if(cnt == 32'b1111_1111) begin
    //             cnt <=  32'b0;
    //             
    //         end
    //         else begin
    //             cnt <= cnt + 1'b1;
    //             
    //         end
    //     end
    // end

    encode83 u_encode83(.x(x), .en(rst), .y(f));
    always @(f) begin
        if(f > 0)
            flag <= 1'b1;

    end

    bcd7seg u_bcd7sed(.b({1'b0,f}), .h(bcd));
endmodule

module top 
    #(parameter n=8, parameter OP_WID=4)
(
    input clk,
    input rst,
    input [n-1:0] din,
    output reg [6:0] seg1,
    output reg [6:0] seg2,
    output reg [n-1:0] dout
);



    linear_feedback_shifter u_linear_feedback_shifter(.clk(clk), .rst(rst), .in(din), .out(dout));
    bcd7seg u_bcdseg_0(dout[3:0], seg1);
    bcd7seg u_bcdseg_1(dout[7:4], seg2);

    
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
endmodule

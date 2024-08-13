module top 
    #(parameter n=4, parameter OP_WID=4)
(
    input [OP_WID-1:0] op_code,
    input [n-1:0] imm1,
    input [n-1:0] imm2,
    input cin,
    output [n-1:0] res,
    output is_overflow,
    output is_carry,
    output is_zero
);

    
    alu u_alu(.op_code(op_code), .imm1(imm1), .imm2(imm2), .cin(cin), .res(res), .is_overflow(is_overflow), .is_carry(is_carry), .is_zero(is_zero));
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

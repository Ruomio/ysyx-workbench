/** 
* op_code:
 * 000 : +
 * 001 : -
 * 010 : ~ , just imm1 valuable
 * 011 : &
 * 100 : |
 * 101 : ^
 * 110 : <
 * 111 : ==

* input:
    imm1 and imm2 are already complement code
    cin is carry bit, default = 0
 */
module alu
    #(parameter n = 4, parameter OP_WID = 4)
(
    input [OP_WID-1:0] op_code,
    input [n-1:0] imm1,
    input [n-1:0] imm2,
    input cin,
    output reg [n-1:0] res,
    output reg is_overflow,
    output reg is_carry,
    output reg is_zero
);
    wire [n-1:0] imm2_temp = ({n{1'b1}}^imm2) + 1 ;

    always @(*) begin
        case(op_code)
            // add
            4'b0000 : begin
                {is_carry, res} = imm1 + imm2 + {{(n-1){1'b0}}, cin};
                is_overflow = (imm1[n-1] == imm2[n-1]) && (res[n-1] != imm1[n-1]);
                is_zero = ~(| res);
            end

            // sub
            4'b0001 : begin
                {is_carry, res} = imm1 + imm2_temp + {{(n-1){1'b0}}, cin};
                is_overflow = (imm1[n-1] == imm2_temp[n-1]) && (res[n-1] != imm1[n-1]);
                is_zero = ~(| res);

            end

            // ~
            4'b0010 : begin
                res = ~imm1;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end

            // &
            4'b0011 : begin
                res = imm1 & imm2;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end

            // |
            4'b0100 : begin
                res = imm1 | imm2;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end

            // ^
            4'b0101 : begin
                res = imm1 & imm2;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end

            // <
            4'b0110 : begin
                res = imm1 < imm2 ? 1 : 0;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end
            
            // ==
            4'b0111 : begin
                res = imm1 == imm2 ? 1 : 0;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end

            default : begin
                res = 0;
                is_carry = 0;
                is_overflow = 0;
                is_zero = ~(|res);
            end
        endcase
    end

endmodule

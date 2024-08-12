module barrel_shifter #(
    parameter n=8
)
(
    input [n-1:0] din,
    input [$clog2(n)-1:0] shamt,
    input l_r,
    input a_l,
    output [n-1:0] dout
);

    reg [n-1:0] dout_reg;

    assign dout = dout_reg;

    always @(*) begin
        case({a_l, l_r})
            2'b00: 
                dout_reg = din >> shamt;
            2'b01:
                dout_reg = din << shamt;
            2'b10:
                dout_reg = $signed(din) >>> shamt;
            2'b11:
                dout_reg = $signed(din) <<< shamt;
            default:
                dout_reg = dout_reg;
        endcase
    end



endmodule

module top(
    input a,
    input b,
    output f
);
    assign f = a ^ b;

    initial begin
        $display("Hello Verilator");
        //$finish;
    end

endmodule

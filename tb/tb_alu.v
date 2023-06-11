`timescale 1ns / 1ps
module tb_alu(); 
    
    parameter PERIOD = 10;

    reg [2:0]  f = 0 ;
    reg [31:0] a = -1;
    reg [31:0] b = 5;


    wire [31:0] y;     //运算结果
    wire [2:0] t;     //比较标志


    initial
    begin
        repeat(8) #(PERIOD)  f=f+1;
    end

    initial
    begin
        #80  a=-2;b=1;
        #10  a=1;b=-2;
        #10  a=1;b=2;
        #10  a=2;b=1;
        #10  a=1;b=1;
        #10  a=-2;b=-2;
    end


    
    alu alu_u0 (
        .a(a), 
        .b(b), 
        .f(f),     
        .y(y),
        .t(t) //比较标志
    );

endmodule
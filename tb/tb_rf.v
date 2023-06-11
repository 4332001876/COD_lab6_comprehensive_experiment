`timescale 1ns / 1ps
module tb_rf(); 
    
    parameter PERIOD = 10;

    reg   clk = 1 ;
    reg   we = 0 ;

    reg [31:0] wdata=0;
    reg [4:0] rs1=0;
    reg [4:0] rs2=0;
    wire [31:0] a,b,debug_rf;
        
    initial
    begin
        forever #(PERIOD/2)  clk=~clk;
    end

    initial
    begin
        #(PERIOD*1.75)  we=1;
        #(PERIOD*2)    we=0;
    end

    initial
    begin
        #(PERIOD*1.75)  wdata=16'h1111;
        #(PERIOD)    wdata=16'h2222;
    end

    initial
    begin
        #(PERIOD*0.75)  rs1=1;
        forever #(PERIOD)  rs1=rs1+1;

    end

    initial
    begin
        #(PERIOD*0.75)  rs2=0;
        forever #(PERIOD)  rs2=rs2+1;
    end





    rf rf1 (
        .rs1(rs1),
        .rs2(rs2),
        .rs_debug(rs1),
        .rd(rs1),
        .clk(clk),  // input wire clk
        .we(we),    // input wire we
        .wdata(wdata),
        .a(a),  // output wire [31 : 0] spo
        .b(b),
        .debug_rf(debug_rf)
    );
    


endmodule
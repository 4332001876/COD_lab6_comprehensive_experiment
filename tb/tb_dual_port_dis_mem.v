`timescale 1ns / 1ps
module tb_dual_port_dis_mem(); 
    parameter PERIOD = 10;

    reg   clk = 1 ;
    reg   we = 0 ;

    reg [31:0] wdata=0;
    reg [5:0] rs1=0;
    reg [5:0] rs2=0;
    wire [31:0] spo,dpo;
        
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






    dist_mem_gen_test your_instance_name (
        .a(rs1),        // input wire [5 : 0] a
        .d(wdata),        // input wire [31 : 0] d
        .dpra(rs2),  // input wire [5 : 0] dpra
        .clk(clk),    // input wire clk
        .we(we),      // input wire we
        .spo(spo),    // output wire [31 : 0] spo
        .dpo(dpo)    // output wire [31 : 0] dpo
    );





endmodule
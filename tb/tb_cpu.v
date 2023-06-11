`timescale 1ns / 1ps
module tb_cpu(); 
    
    parameter PERIOD = 10;

    reg   clk = 1 ;
    reg   we = 0 ;
    reg   rstn = 0;

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
        #(PERIOD*1)  rstn=1;
    end







    cpu_top cpu_u0(
        .clk(clk),
        .rstn(rstn),
        .pc_chk(), //用于SDU进行断点检查，在单周期cpu中，pc_chk = pc
        .npc(),    //next_pc
        .pc(),
        .IR(),     //当前指令
        .IMM(),    //立即数
        .CTL(),    //控制信号，你可以将所有控制信号集成一根bus输出
        .A(),      //ALU的输入A
        .B(),      //ALU的输入B
        .Y(),      //ALU的输出
        .MDR(),    //数据存储器的输出
        .addr(0),   
        .dout_rf(),
        .dout_dm(),
        .dout_im(),
        .din(0),
        .we_dm(0),
        .we_im(0),
        .clk_ld(0),
        .debug(0),
        .led()
);
    


endmodule
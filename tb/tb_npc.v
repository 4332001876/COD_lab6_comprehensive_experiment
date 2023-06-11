`timescale 1ns / 1ps
module tb_npc(); 
    
    parameter PERIOD = 10;


    reg [31:0] pc=32'h3000,imm=32'h48;
    wire [31:0] npc;
    reg Branch=1,condition=0;

    initial begin
        #(PERIOD) condition=1;
    end
        

    npc npc_u0(
        .pc(pc),//it can be x[rs1]
        .is_jump((Branch&condition)),
        .is_jalr(0),
        .imm(imm),
        .npc(npc)
    );






    
    


endmodule
`timescale 1ns / 1ps
module tb_forwarding();

    reg [4:0] IDEX_rs1;
    reg [4:0] IDEX_rs2;
    reg [4:0] EXMEM_rd;
    reg [4:0] MEMWB_rd;
    reg EXMEM_RegWrite;
    reg MEMWB_RegWrite;

    wire [1:0] afwd,bfwd;

    initial
    begin
        IDEX_rs1=1;
        IDEX_rs2=0;
        EXMEM_RegWrite=1;
        MEMWB_RegWrite=1;
        EXMEM_rd=1;
        MEMWB_rd=1;
        #20 
        EXMEM_rd=0;
        MEMWB_rd=1;
        #20
        EXMEM_rd=0;
        MEMWB_rd=0;
    end

    forwarding_unit fwd_u0(
        .IDEX_rs1(IDEX_rs1),
        .IDEX_rs2(IDEX_rs2),
        .EXMEM_rd(EXMEM_rd),
        .MEMWB_rd(MEMWB_rd),
        .EXMEM_RegWrite(EXMEM_RegWrite),
        .MEMWB_RegWrite(MEMWB_RegWrite),
        .afwd(afwd),
        .bfwd(bfwd)
    );





endmodule
module forwarding_unit(
    input [4:0] IDEX_rs1,
    input [4:0] IDEX_rs2,
    input [4:0] EXMEM_rd,
    input [4:0] MEMWB_rd,
    input EXMEM_RegWrite,
    input MEMWB_RegWrite,
    output reg [1:0] afwd,
    output reg [1:0] bfwd
);
    always@(*) begin
        if(EXMEM_RegWrite&(|EXMEM_rd)&(EXMEM_rd==IDEX_rs1))
            afwd=2'b10;
        else if(MEMWB_RegWrite&(|MEMWB_rd)&(MEMWB_rd==IDEX_rs1))
            afwd=2'b01;
        else
            afwd=2'b00;
    end

    always@(*) begin
        if(EXMEM_RegWrite&(|EXMEM_rd)&(EXMEM_rd==IDEX_rs2))
            bfwd=2'b10;
        else if(MEMWB_RegWrite&(|MEMWB_rd)&(MEMWB_rd==IDEX_rs2))
            bfwd=2'b01;
        else
            bfwd=2'b00;
    end



endmodule
module npc #(
    parameter WIDTH = 32     //数据宽度
)(
    input [WIDTH-1:0] pc,//it can be x[rs1]
    input is_jump,
    input is_jalr,
    input [WIDTH-1:0] imm,
    output reg [WIDTH-1:0] npc
);
    always@(*) begin
        if(is_jalr)
            npc=(is_jump)?(pc+imm):(pc+4);
        else
            npc=(is_jump)?((pc+imm)&32'hffff_fffe):(pc+4);
    end

endmodule
module condition(
    input [2:0] funct3,
    input [2:0] ALUt, 
    output reg condition


);

    wire ltu,lt,eq;
    assign {ltu,lt,eq}=ALUt;

    always@(*) begin
        //ALUt={ltu, lt, eq}
        case(funct3)//00:add 01:sub  10:R-type & I-type
            3'b000:condition=eq;//beq
            3'b001:condition=!eq;//bne
            3'b100:condition=lt;//blt
            3'b101:condition=!lt;//bge
            3'b110:condition=ltu;//bltu
            3'b111:condition=!ltu;//bgeu
            default:condition=0;
        endcase

    end


endmodule
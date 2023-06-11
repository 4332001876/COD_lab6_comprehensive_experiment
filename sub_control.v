module sub_control(
    input [2:0] funct3,
    input [6:0] funct7,
    input funct7_en,
    input [1:0] ALUOp,
    input [2:0] ALUt, 
    output reg [2:0] ALUf,
    output reg condition


);
     //ALUf
    always@(*) begin
        case(ALUOp)//00:add 01:sub  10:R-type & I-type
            2'b00:ALUf=3'b010;
            2'b01:ALUf=3'b000;
            2'b10:begin
                if(!funct3) begin
                    if(funct7_en) begin
                        if(!funct7)
                            ALUf=3'b010;
                        else
                            ALUf=3'b000;
                    end
                    else ALUf=3'b010;//addi
                end
                else if(funct3==3'b101) begin//funct7 always enable
                    if(funct7)//sra
                        ALUf=3'b011;
                    else
                        ALUf=3'b101;
                end
                else
                    ALUf=funct3;

            end
            default:ALUf=3'b010;
        endcase

    end

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
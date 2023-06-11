module control(
    input [31:0] IR,
    output reg Branch,
    output reg MemRead,
    output reg MemtoReg,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite,
    output reg is_jalr,
    output reg RegWriteSrc,
    output reg is_jump,
    output reg [2:0] ALUf,
    output reg [1:0] ALUSrc_a//00:reg  01:0  10:pc  

);
    wire [6:0] opcode,funct7;
    wire [2:0] funct3;

    assign opcode=IR[6:0];
    assign funct3=IR[14:12];
    assign funct7=IR[31:25];

    //base on opcode
    reg funct7_en;
    //RegWriteSrc=1:pc+4
    reg [1:0] ALUOp;//00:add 01:sub  10:R-type & I-type
    
    always@(*) begin
        Branch=0;
        MemRead=0;
        MemtoReg=0;//0:alu_result  1:mem_read
        ALUOp=0;
        MemWrite=0;
        ALUSrc=0;//0:reg  1:imm
        RegWrite=0;
        ALUSrc_a=0;
        is_jalr=0;
        is_jump=0;
        RegWriteSrc=0;
        funct7_en=0;
        case(opcode) 
            7'b0110011:begin//R-type,add
                ALUOp=2'b10;
                RegWrite=1;
                funct7_en=1;


            end
            7'b0010011:begin//I-type,addi
                ALUOp=2'b10;
                ALUSrc=1;
                RegWrite=1;

            end
            7'b0110111:begin//lui
                //rf input rs1=0 or ALU input a=0
                ALUSrc=1;
                RegWrite=1;
                ALUSrc_a=1;

            end
            7'b0010111:begin//auipc
                //ALU input a=pc

                ALUSrc=1;
                RegWrite=1;
                ALUSrc_a=2;
            end

            7'b1100011:begin//B-type
                Branch=1;
                ALUOp=2'b01;
            end

            7'b1101111:begin//jal
            //ALUresult=pc+4
                RegWriteSrc=1;
                ALUSrc=1;
                RegWrite=1;
                is_jump=1;

            end
            7'b1100111:begin//jalr
            //ALUresult=pc+4
                RegWriteSrc=1;
                ALUSrc=1;
                is_jalr=1;
                RegWrite=1;
                is_jump=1;


            end

            7'b0000011:begin//load
                MemRead=1;
                RegWrite=1;
                MemtoReg=1;
                ALUSrc=1;

            end
            7'b0100011:begin//save
                MemWrite=1;
                MemtoReg=1;
                ALUSrc=1;

            end








            default:;
        endcase



    end


    //assign ctl={18'h0, funct7_en,RegWriteSrc,is_jalr,is_jump,ALUSrc_a, ALUOp,Branch,MemRead,MemtoReg, MemWrite,ALUSrc,RegWrite};
    
    
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



endmodule
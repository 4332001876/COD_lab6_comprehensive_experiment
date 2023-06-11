module immgen(
input 	    [31:0] inst,
output reg	[31:0] out
);
    wire	[6:0] opcode;
    wire    [2:0] funct3;
    assign  funct3=inst[14:12];
    assign	opcode= inst[6:0];
    //立即数扩展
    always@(*)
    begin
        case(opcode)
            7'b0010111:out={inst[31:12],12'h0};//auipc
            7'b0110111:out={inst[31:12],12'h0};//lui
            7'b1100011:out={{20{inst[31]}},inst[7],inst[30:25],inst[11:8],1'h0};//B
            7'b1101111:out={{12{inst[31]}},inst[19:12],inst[20],inst[30:21],1'h0};//jal
            7'b1100111:out={{21{inst[31]}},inst[30:20]};//jalr
            7'b0000011:out={{21{inst[31]}},inst[30:20]};//I(load)
            7'b0100011:out={{21{inst[31]}},inst[30:25],inst[11:7]};//S
            7'b0010011:begin
                if(funct3[1:0]==2'b01)
                    out={27'h0,inst[24:20]};//I(sli,sri)
                else
                    out={{21{inst[31]}},inst[30:20]};//I(calculate)
            end
            default:out=32'h0;
        endcase
    end 
endmodule
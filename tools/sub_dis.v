module sub_dis  (
    input [3:0] d,
    output reg [6:0] cn
);
    always@(*)begin
        //高位到低位
        case(d)
            4'b0000:cn = 7'b1000000;
            4'b0001:cn = 7'b1111001;
            4'b0010:cn = 7'b0100100;
            4'b0011:cn = 7'b0110000;

            4'b0100:cn = 7'b0011001;
            4'b0101:cn = 7'b0010010;
            4'b0110:cn = 7'b0000010;
            4'b0111:cn = 7'b1111000;

            4'b1000:cn = 7'b0000000;
            4'b1001:cn = 7'b0010000;
            4'b1010:cn = 7'b0001000;//a
            4'b1011:cn = 7'b0000011;//b

            4'b1100:cn = 7'b1000110;//c
            4'b1101:cn = 7'b0100001;//d
            4'b1110:cn = 7'b0000110;//e
            4'b1111:cn = 7'b0001110;//f
            default:cn = 7'bxxxxxxx;
            
        endcase
    end
    





    
endmodule
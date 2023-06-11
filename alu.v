module alu #(
    parameter WIDTH = 32     //数据宽度
)(
    input signed [WIDTH-1:0] a, b,       //两操作数
    input [2:0] f,                      //功能选择
    output reg signed [WIDTH-1:0] y,     //运算结果
    output [2:0] t                     //比较标志
);
/* 
@params:
f：功能选择，减、加、与、或、异或、逻辑右移、逻辑左移、算术右移等运算
a, b：两个操作数
y：运算结果，和、差 …… 
t：比较标志，相等(eq)，小于(lt, ltu), t={ltu, lt, eq}, lt:a<b
*/
    reg ltu, lt, eq;

    always@(*)//y
    begin
        case(f)
            3'b000: y=a-b;//add,sub
            3'b001: y=a<<b;//sll
            3'b010: y=a+b;
            3'b011: y=a>>>b;
            3'b100: y=a^b;//xor
            3'b101: y=a>>b;//srl,sra
            3'b110: y=a|b;//or
            3'b111: y=a&b;//and
            default: y=32'b0;
        endcase
    end

    always@(*)//t：比较标志，相等(eq)，小于(lt, ltu), t={ltu, lt, eq}
    begin
        ltu=0;
        lt=0;
        eq=0;
        if(!f) //f=0
            begin
                if(y) //a!=b
                begin
                    if(a[WIDTH-1]^b[WIDTH-1])//异号
                    begin
                        if(a[WIDTH-1])//a负b正
                            lt=1;
                        else
                            ltu=1;
                    end
                    else//同号
                    begin
                        if(y[WIDTH-1]) //y为负（同号时y作为减法结果不会溢出）
                        begin
                            lt=1;
                            ltu=1;
                        end
                    end
                end
                else //y=a-b=0
                    eq=1;
            end
    end


    assign t={ltu, lt, eq};







endmodule
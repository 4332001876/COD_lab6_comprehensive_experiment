module dis  (
    input clk,rstn,
    input [31:0] d,
    output reg [7:0] an,
    output [6:0] cn
);
    wire clkd;//分频后时钟
    frequency_divider fd_u0(
        .clk(clk),
        .rstn(rstn),
        .k(100000),//T=1ms
        .y(clkd)
    );
    

    reg [3:0] num;
    wire [2:0] which_a;

    reg pe;
    counter #(.WIDTH(3),.RST_VLU(7)) counter_u0
    (
        .clk(clkd), 
        .rstn(rstn), 
        .pe(0), //同步置数使能
        .ce(1), //计数使能
        .d(7),
        .q(which_a)

    );

    always @(*) begin
        case(which_a)
        3'b000:begin
            num=d[3:0];
            an=8'b1111_1110;
        end
        3'b001:begin
            num=d[7:4];
            an=8'b1111_1101;
        end
        3'b010:begin
            num=d[11:8];
            an=8'b1111_1011;
        end
        3'b011:begin
            num=d[15:12];
            an=8'b1111_0111;
        end
        3'b100:begin
            num=d[19:16];
            an=8'b1110_1111;
        end
        3'b101:begin
            num=d[23:20];
            an=8'b1101_1111;
        end
        3'b110:begin
            num=d[27:24];
            an=8'b1011_1111;
        end
        3'b111:begin
            num=d[31:28];
            an=8'b0111_1111;            
        end
        default:begin
            num=d[3:0];
            an=8'b1111_1110;
        end
        endcase
    end

    sub_dis sub_dis_u0
    (
        .d(num),
        .cn(cn)
    );



    
endmodule
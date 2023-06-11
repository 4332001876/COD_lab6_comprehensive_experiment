module rf(
    input wire [4 : 0] rs1,
    input wire [4 : 0] rs2,
    input wire [4 : 0] rs_debug,
    input wire [4 : 0] rd,
    input wire [31 : 0] wdata,
    input wire clk,
    input wire we,
    output wire [31 : 0] a,
    output wire [31 : 0] b,
    output wire [31 : 0] debug_rf
);
// 寄存器堆的写优先的读操作模式
    reg [31:0] rf[0:31];
    wire [31 : 0] temp_a;
    wire [31 : 0] temp_b;
    wire [31 : 0] temp_debug_rdata;
    assign temp_a=rf[rs1];
    assign temp_b=rf[rs2];
    assign temp_debug_rdata=rf[rs_debug];

    always@ (posedge clk) 
    begin
        if (we)  rf[rd] <= wdata;
    end

//若读取即将被写入的寄存器，将读出即将写入的内容
    assign a=(rs1)?((we&(rs1==rd))?wdata:temp_a):0;//寄存器堆的0号寄存器内容恒定为零
    assign b=(rs2)?((we&(rs2==rd))?wdata:temp_b):0;//寄存器堆的0号寄存器内容恒定为零
    assign debug_rf=(rs_debug)?((we&(rs_debug==rd))?wdata:temp_debug_rdata):0;

endmodule
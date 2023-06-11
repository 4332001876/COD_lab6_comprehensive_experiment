module counter #(
parameter WIDTH = 16, 
RST_VLU = 0//reset_value
)(
input clk, rstn, pe, ce, 
input [WIDTH-1:0] d,
output reg [WIDTH-1:0] q
);
/*
@params:
– d, q：输入和输出数据
– pe：同步置数使能
– ce：计数使能
– clk, rstn：时钟, 复位
*/
always @(posedge clk, negedge
rstn) begin
if (!rstn) q <= RST_VLU;
else if (pe) q <= d;
else if (ce) q <= q - 1;
end
endmodule
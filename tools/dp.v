module dp #(
    parameter WIDTH = 1
) (
    input clk, rstn,
    input [WIDTH-1:0] x, 
    output [WIDTH-1:0] y
);
    wire [WIDTH-1:0] debounce_y;
    debounce #(
        .WIDTH(WIDTH)
    )debounce_u0(
        .clk(clk), 
        .rstn(rstn), 
        .x(x), 
        .y(debounce_y)
    );

    ps #(
        .WIDTH(WIDTH)
    )ps_u0(
        .clk(clk), 
        .rstn(rstn), 
        .x(debounce_y), 
        .y(y)
    );





endmodule
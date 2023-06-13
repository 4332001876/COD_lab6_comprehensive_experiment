module bram #(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    INIT_FILE = ""
)(
    input clk, // Clock
    input [ADDR_WIDTH-1:0] addr, // Address
    input [DATA_WIDTH-1:0] din, // Data Input
    input we, // Write Enable
    output [DATA_WIDTH-1:0] dout // Data Output
    //debug
    input [ADDR_WIDTH-1:0] debug_addr,
    output reg [DATA_WIDTH-1:0] debug_dout
); 
    //在时钟周期边沿读写数据
    reg [ADDR_WIDTH-1:0] addr_r, debug_addr_r; // Address Register
    reg [DATA_WIDTH-1:0] ram [0:(1 << ADDR_WIDTH)-1];//这么写会例化为BRAM
    initial $readmemh(INIT_FILE, ram); // initialize memory
    assign dout = ram[addr_r]; 
    assign debug_dout = ram[debug_addr_r];
    always @(posedge clk) begin
    addr_r <= addr;
    debug_addr_r <= debug_addr;
    if (we) ram[addr] <= din;
end
endmodule
module cache_direct_mapped#(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    INDEX_WIDTH = 5,
    TAG_WIDTH = 2,
    BLOCK_OFFSET_WIDTH = 3
)(
    input clk, // Clock
    input rstn,
    input [ADDR_WIDTH-1:0] addr, // Address
    input [DATA_WIDTH-1:0] din, // Data Input
    input we, // Write Enable
    output hit,
    output [DATA_WIDTH-1:0] dout // Data Output
);
    //容量1KB，256个字
    parameter BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;
    parameter NUM_OF_LINES = 1<<INDEX_WIDTH;

    wire [TAG_WIDTH-1:0] tag;
    wire [INDEX_WIDTH-1:0] index;
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset;
    assign tag=addr[ADDR_WIDTH-1:ADDR_WIDTH-TAG_WIDTH];
    assign index=addr[BLOCK_OFFSET_WIDTH+INDEX_WIDTH-1:BLOCK_OFFSET_WIDTH];
    assign block_offset=addr[BLOCK_OFFSET_WIDTH-1:0];

    reg [(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:0] cache [NUM_OF_LINES-1:0]; //cache_content

    wire [(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:0] cache_line;
    assign cache_line=cache[index];

    wire line_valid;
    wire [TAG_WIDTH-1:0] line_tag;
    wire [DATA_WIDTH*BLOCK_SIZE-1:0] line_data;
    assign line_valid=cache_line[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE];
    assign line_tag=cache_line[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE-1:DATA_WIDTH*BLOCK_SIZE];
    assign line_data=cache_line[DATA_WIDTH*BLOCK_SIZE-1:0];

    assign hit=line_valid&(line_tag==tag);



    wire valid; // Valid/Ready






endmodule
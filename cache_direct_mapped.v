module cache_direct_mapped#(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    INDEX_WIDTH = 5,
    TAG_WIDTH = 2,
    BLOCK_OFFSET_WIDTH = 3
)(
    input clk, // Clock
    input rstn,
    input [ADDR_WIDTH-1:0] addr, // Address，要保证Miss后读写BRAM时长时间稳定
    input [DATA_WIDTH-1:0] din, // Data Input
    input we, // Write Enable
    input mem_en, // Memory Enable，用于控制是否读写BRAM，从而控制命中/缺失判断与换页
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
    assign dout=line_data[(block_offset*DATA_WIDTH)+:DATA_WIDTH];

    assign hit=line_valid&(line_tag==tag);

    //cache的主要活动
    always@(posedge clk) begin
        if(mem_en&hit&we) begin//写缓存
            cache[index][(block_offset*DATA_WIDTH)+:DATA_WIDTH]<=din;
        end
        else if(mem_en&!hit) begin//换页
            if(valid_bram) begin
                cache[index]<={1'b1,tag,dout_bram};//设置完这个后，下回合hit会自动变成1
            end
        end
    end


    wire valid_bram; // Valid/Ready
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset_zero;//用于给出宽为BLOCK_OFFSET_WIDTH的0
    wire [BLOCK_SIZE*DATA_WIDTH-1:0] dout_bram;
    delayed_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH),
        .INIT_FILE("D:\\Verilog\\2023_cod_lab\\lab_6\\labH6_resources\\coe\\array_sort_data_v3 hex.txt")
    ) delayed_memory_u0(
        .clk(clk),
        .rstn(rstn),
        .addr({addr[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH],block_offset_zero}),
        .block_din(line_data),
        .dout_valid(),
        .dout(),
        .block_valid(valid_bram),
        .we(!hit),//未命中则需要写入当前行
        .block_dout(dout_bram)
        .debug_addr(debug_addr),
        .debug_dout(debug_dout)
    );



    






endmodule
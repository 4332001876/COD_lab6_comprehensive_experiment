module cache_set_associative#(    
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    INDEX_WIDTH = 4,
    TAG_WIDTH = 3,
    BLOCK_OFFSET_WIDTH = 3
)(
    input clk, // Clock
    input rstn,
    input [ADDR_WIDTH-1:0] addr, // Address，要保证Miss后读写BRAM时长时间稳定
    input [DATA_WIDTH-1:0] din, // Data Input
    input we, // Write Enable
    input mem_en, // Memory Enable，用于控制是否读写BRAM，从而控制命中/缺失判断与换页
    output hit,
    output [DATA_WIDTH-1:0] dout, // Data Output
    input [ADDR_WIDTH-1:0] debug_addr,//debug时保证debug_addr和addr相同
    output [DATA_WIDTH-1:0] debug_dout
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

    reg [2*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:0] cache [NUM_OF_LINES-1:0]; //cache_content

    integer i;
    initial begin//cache初始化内容默认为0（其实不加initial块也会默认初始化为0）
        for(i=0;i<NUM_OF_LINES;i=i+1) begin
            cache[i]=0;
        end
    end

    //0表示低位的块，1表示高位的
    wire [(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:0] cache_line_0, cache_line_1, cache_line;
    assign cache_line_0=cache[index][(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:0];
    assign cache_line_1=cache[index][2*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)-1:(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)];
    assign cache_line=hit_0?cache_line_0:cache_line_1;

    wire line_valid_0;
    wire [TAG_WIDTH-1:0] line_tag_0;
    wire [DATA_WIDTH*BLOCK_SIZE-1:0] line_data_0;
    wire line_valid_1;
    wire [TAG_WIDTH-1:0] line_tag_1;
    wire [DATA_WIDTH*BLOCK_SIZE-1:0] line_data_1;
    wire [DATA_WIDTH-1:0] dout_0,dout_1;
    assign line_valid_0=cache_line_0[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE];
    assign line_tag_0=cache_line_0[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE-1:DATA_WIDTH*BLOCK_SIZE];
    assign line_data_0=cache_line_0[DATA_WIDTH*BLOCK_SIZE-1:0];
    assign dout_0=line_data_0[(block_offset*DATA_WIDTH)+:DATA_WIDTH];
    assign line_valid_1=cache_line_1[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE];
    assign line_tag_1=cache_line_1[TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE-1:DATA_WIDTH*BLOCK_SIZE];
    assign line_data_1=cache_line_1[DATA_WIDTH*BLOCK_SIZE-1:0];
    assign dout_1=line_data_1[(block_offset*DATA_WIDTH)+:DATA_WIDTH];

    wire hit_0,hit_1;
    assign hit_0=line_valid_0&(line_tag_0==tag);
    assign hit_1=line_valid_1&(line_tag_1==tag);
    assign hit=hit_0|hit_1;

    assign dout=hit_0?dout_0:dout_1;

    wire line_valid;
    wire [TAG_WIDTH-1:0] line_tag;
    wire [DATA_WIDTH*BLOCK_SIZE-1:0] line_data;

    assign line_valid=hit_0?line_valid_0:line_valid_1;
    assign line_tag=hit_0?line_tag_0:line_tag_1;
    assign line_data=hit_0?line_data_0:line_data_1;

    //assign hit=line_valid&(line_tag==tag);



    /*//cache的主要活动
    always@(posedge clk) begin
        if(mem_en&hit&we) begin//写缓存
            cache[index][(hit_1*(block_offset*DATA_WIDTH)+(block_offset*DATA_WIDTH))+:DATA_WIDTH]<=din;
        end
        else if(mem_en&!hit) begin//换页读
            if(is_write_back)
                cache[index][(hit_1*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE))+:(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)]<={1'b0,line_tag,line_data};//设置这个来使is_write_back在写回后变为0
            else if(valid_bram&(!is_write_back)) 
                cache[index][(hit_1*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE))+:(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)]<={1'b1,tag,dout_bram};//设置完这个后，下回合hit会自动变成1
        end
    end

    
    reg is_write_back;//实际上是一个状态信号，控制读或写
    always@(posedge clk,negedge rstn) begin
        if(!rstn)
            is_write_back<=0;
        else begin
            if(mem_en&(!hit)) begin//未命中且当前行有效则需要将当前行写内存
                if(!is_write_back&line_valid)
                    is_write_back<=1;
                else if(valid_bram) //（读完的时候写也会完成，因此可以用这时候的valid_bram来判断是否写完）
                    is_write_back<=0;
            end
            else
                is_write_back<=0;
        end
    end

    reg [ADDR_WIDTH-1:0] addr_bram;
    always@(*) begin
        if(is_write_back)
            addr_bram={line_tag,index,block_offset_zero};
        else
            addr_bram={addr[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH],block_offset_zero};
    end*/

    //cache的主要活动
    always@(posedge clk) begin
        if(mem_en&hit&we) //写缓存
            cache[index][(hit_1*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)+block_offset*DATA_WIDTH)+:DATA_WIDTH]<=din;
        else if(CS==READ_MEM&valid_bram) //换页读
            cache[index][(hit_1*(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE))+:(1+TAG_WIDTH+DATA_WIDTH*BLOCK_SIZE)]<={1'b1,tag,dout_bram};//设置完这个后，下回合hit会自动变成1
    end

    reg [2:0] CS,NS;
    parameter WAITING=3'b000,WRITE_BACK=3'b001,READ_MEM=3'b010;
    always@(posedge clk,negedge rstn) begin
        if(!rstn)
            CS<=WAITING;
        else
            CS<=NS;
    end
    always@(*)begin
        case(CS)
            WAITING:begin//命中或mem_en=0
                if(mem_en&(!hit)) begin
                    if(line_valid)//未命中且当前行有效则需要将当前行写内存
                        NS=WRITE_BACK;
                    else
                        NS=READ_MEM;
                end
                else
                    NS=WAITING;
            end
            WRITE_BACK:begin
                if(valid_bram)
                    NS=READ_MEM;
                else
                    NS=WRITE_BACK;
            end
            READ_MEM:begin
                if(hit)
                    NS=WAITING;
                else
                    NS=READ_MEM;
            end
            default:NS=WAITING;
        endcase
    end

    //保证debug_addr与addr一致
    reg debug_hit;
    wire [DATA_WIDTH-1:0] debug_dout_bram;
    reg [DATA_WIDTH-1:0] debug_dout_cache;//由于从内存中读出的内容是缓存了一个周期的，所以为了debug时读出的数据延迟的一致性，这里也需要将debug_dout_cache缓存一个周期
    always@(posedge clk) begin
        debug_dout_cache<=dout;
        debug_hit<=hit;
    end
    //assign debug_dout=debug_hit?debug_dout_cache:debug_dout_bram;
    assign debug_dout=hit?dout:0;


    wire valid_bram; // Valid/Ready
    wire [BLOCK_OFFSET_WIDTH-1:0] block_offset_zero;//用于给出宽为BLOCK_OFFSET_WIDTH的0
    assign block_offset_zero=0;
    wire [BLOCK_SIZE*DATA_WIDTH-1:0] dout_bram;
    delayed_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH),
        .INIT_FILE("D:/Verilog/2023_cod_lab/lab_6/labH6_resources/coe/array_sort_data_v3_hex.txt")
        //"D:/Verilog/2023_cod_lab/lab_6/labH6_resources/coe/array_sort_data_v3_hex.txt"
    ) delayed_memory_u0(
        .clk(clk),
        .rstn(rstn),
        .addr(addr_bram),
        .block_din(line_data),
        .dout_valid(),
        .dout(),
        .block_valid(valid_bram),
        .we(CS==WRITE_BACK),//未命中且行有效则需要写入当前行
        .block_dout(dout_bram),
        .debug_addr(debug_addr),
        .debug_dout(debug_dout_bram)
    );



    






endmodule



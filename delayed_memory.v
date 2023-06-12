module delayed_memory#(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    BLOCK_OFFSET_WIDTH = 3,
    INIT_FILE = ""
)(
    input clk, // Clock
    input rstn,
    input [ADDR_WIDTH-1:0] addr, // Address
    input [BLOCK_SIZE*DATA_WIDTH-1:0] block_din, // Data Input，从低位到高位排下地址低位到高位的字
    output reg valid, // Valid/Ready
    input we, // Write Enable
    output reg [BLOCK_SIZE*DATA_WIDTH-1:0] block_dout // Data Output，从低位到高位排下地址低位到高位的字
);
    //只有地址变化才会触发读写
    //读需要地址稳定延迟的周期数加上数据块的字数
    //写同样需要地址稳定这么长时间，且保证写入块数据稳定不变
    //读写都在READING状态进行
    //靠valid/ready信号发送数据

    parameter BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;

    reg [ADDR_WIDTH-1:0] last_addr; // Last Address

    reg [ADDR_WIDTH-1:0] addr_bram; // Address Register for BRAM
    reg [DATA_WIDTH-1:0] din_bram;
    reg we_bram;

    always@(posedge clk) begin
        last_addr<=addr;
    end

    reg [2:0] NS,CS;
    parameter WAITING=3'b000,READING=3'b001,VALID=3'b010;
    always@(posedge clk, negedge rstn) begin
        if(!rstn)
            CS<=WAITING;
        else
            CS<=NS;
    end
    reg [3:0] waiting_countdown;
    //ns
    always@(*) begin
        case(CS) 
            WAITING:begin
                if(last_addr!=addr) 
                    NS=WAITING;
                else if(waiting_countdown==0) begin
                    NS=READING;
                end
                else begin
                    NS=WAITING;
                end
            end
            READING:begin
                if(addr_bram[BLOCK_OFFSET_WIDTH-1:0]==BLOCK_SIZE-1) begin
                    NS=VALID;
                end
                else begin
                    NS=READING;
                end
            end            
            VALID:begin
                if(last_addr!=addr) 
                    NS=WAITING;
                else NS=VALID;
            end
            default:begin
                NS=WAITING;
            end
        endcase
    end

    //waiting_countdown
    always@(posedge clk) begin
        case(CS) 
            VALID:begin
                waiting_countdown<=15;
            end
            WAITING:begin
                waiting_countdown<=waiting_countdown-1;
            end
            READING:begin
                waiting_countdown<=15;
            end
            default:begin
               waiting_countdown<=15;
            end
        endcase
    end

    //block_buffer
    reg [BLOCK_SIZE*DATA_WIDTH-1:0] block_buffer;//仅用来实现移位操作
    always@(posedge clk) begin
        case(CS) 
            VALID:begin
                block_buffer<=block_din;
            end
            WAITING:begin
                block_buffer<=block_din;
            end
            READING:begin
                block_buffer<=block_buffer[BLOCK_SIZE*DATA_WIDTH-1:DATA_WIDTH];//右移一位数据
            end
            default:begin
                block_buffer<=block_din;
            end
        endcase
    end
    //din_bram, we_bram
    always@(*) begin
        case(CS) 
            VALID:begin
                din_bram=0;
                we_bram=0;
            end
            WAITING:begin
                din_bram=0;
                we_bram=0;               
            end
            READING:begin
                //READING前几个周期内地址分别为0,1,2,3..,BLOCK_SIZE-1
                //READING前几个周期内写入的数据分别为[0],[1],[2]..
                din_bram=block_buffer[DATA_WIDTH-1:0];//block_buffer的低位数据是最新数据
                we_bram=we;
            end
            default:begin
                din_bram=0;
                we_bram=0;  
            end
        endcase
    end
    //addr_bram, dout_valid
    reg dout_valid;
    always@(posedge clk) begin
        case(CS) 
            VALID:begin
                addr_bram[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH]<=addr[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH];
                addr_bram[BLOCK_OFFSET_WIDTH-1:0]<=0;
                dout_valid<=0;
            end
            WAITING:begin
                addr_bram[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH]<=addr[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH];
                addr_bram[BLOCK_OFFSET_WIDTH-1:0]<=0;    
                dout_valid<=0;            
            end
            READING:begin
                //READING前几个周期内地址分别为0,1,2,3..,BLOCK_SIZE-1
                //READING前几个周期内读出的数据分别为not valid,[0],[1],[2]..
                addr_bram[BLOCK_OFFSET_WIDTH-1:0]<=addr_bram[BLOCK_OFFSET_WIDTH-1:0]+1;
                dout_valid<=1;//这样与读数据变为有效同步
            end
            default:begin
                addr_bram[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH]<=addr[ADDR_WIDTH-1:BLOCK_OFFSET_WIDTH];
                addr_bram[BLOCK_OFFSET_WIDTH-1:0]<=0;
                dout_valid<=0;
            end
        endcase
    end

    always@(posedge clk) begin
        if(dout_valid) begin
            block_dout<={dout,block_dout[DATA_WIDTH*BLOCK_SIZE-1:DATA_WIDTH]};//左边入队
        end
    end

    always@(posedge clk) begin
        if(dout_valid&&CS==VALID) begin//读入数据的最后一回合
            valid<=1;
        end else if(CS!=VALID) begin
            valid<=0;
        end
    end




    wire [DATA_WIDTH-1:0] dout; // Data Output
    bram #( // 1 cycle delay
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .INIT_FILE(INIT_FILE)
    ) bram_u0
    (
        .clk(clk), // Clock
        .addr(addr_bram), // Address
        .din(din_bram), // Data Input
        .we(we_bram), // Write Enable
        .dout(dout) // Data Output
    );




endmodule
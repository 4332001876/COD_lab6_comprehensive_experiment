module tb_delayed_memory();
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 3;
    parameter BLOCK_OFFSET_WIDTH = 2;

    parameter BLOCK_SIZE = 1<<BLOCK_OFFSET_WIDTH;

    wire valid;
    wire [DATA_WIDTH-1:0] dout;
    wire [BLOCK_SIZE*DATA_WIDTH-1:0] block_dout;

    reg [ADDR_WIDTH-1:0] debug_addr=0;
    wire [DATA_WIDTH-1:0] debug_dout;

    parameter PERIOD = 10;

    reg   clk = 1 ;
    reg   we = 0 ;
    reg   rstn = 0;
        
    initial
    begin
        forever #(PERIOD/2)  clk=~clk;
    end
    initial
    begin
        #(PERIOD*1)  rstn=1;
    end

    initial
    begin
        forever #(PERIOD*2)  debug_addr=debug_addr+1;
    end
    initial begin
        addr=0;
        block_din=128'h11112222333344441122334455667788;
        #(PERIOD*30)  
        addr=5;
        we=1;
        #(PERIOD*60) 
        addr=6; 
        we=0;
        #(PERIOD*90)
        addr=0;
    end

    

    reg [ADDR_WIDTH-1:0] addr; // Address
    reg [BLOCK_SIZE*DATA_WIDTH-1:0] block_din; // Data Input，从低位到高位排下地址低位到高位的字


    delayed_memory #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .BLOCK_OFFSET_WIDTH(BLOCK_OFFSET_WIDTH),
        .INIT_FILE("D:\\Verilog\\2023_cod_lab\\lab_6\\labH6_resources\\coe\\array_sort_data_v3_hex.txt")
    ) delayed_memory_u0(
        .clk(clk),
        .rstn(rstn),
        .addr(addr),
        .block_din(block_din),
        .block_valid(valid),
        .dout_valid(),
        .we(we),
        .dout(dout),
        .block_dout(block_dout),
        .debug_addr(debug_addr),
        .debug_dout(debug_dout)
    );


















endmodule
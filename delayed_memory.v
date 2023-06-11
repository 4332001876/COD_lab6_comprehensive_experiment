module delayed_memory#(
    parameter DATA_WIDTH = 32,
    ADDR_WIDTH = 10,
    INIT_FILE = ""
)(
    input clk, // Clock
    input [ADDR_WIDTH-1:0] addr, // Address
    input [DATA_WIDTH-1:0] din, // Data Input
    input valid, // Valid/Ready
    input we, // Write Enable
    output [DATA_WIDTH-1:0] dout // Data Output
);
    reg [ADDR_WIDTH-1:0] last_addr; // Last Address
    reg [ADDR_WIDTH-1:0] addr_bram; // Address Register for BRAM
    wire [DATA_WIDTH-1:0] dout_bram;
    wire [DATA_WIDTH-1:0] din_bram;
    wire we_bram;

    always@(posedge clk) begin
        last_addr<=addr;
    end

    reg [2:0] NS,CS;
    parameter IDLE=3'b000,WAITING=3'b001,READING=3'b010;
    always@(posedge clk) begin
        CS<=NS;
    end
    always@(*) begin
        case(CS) 
            IDLE:begin
                if(last_addr!=addr) 
                    NS=WAITING;
                else NS=IDLE;
            end
            WAITING:begin
                if(last_addr!=addr) 
                    NS=WAITING;
                else
            end
            READING:begin
                if(last_addr!=addr) 
                    NS=WAITING;
                else

            end
        endcase
    end


    always@(posedge clk) begin
        if(CS==IDLE) begin
            addr_bram;
            din_bram;
            we_bram;
        end
        else if(CS==WAITING) begin

        end
        else if(CS==READING) begin

        end
    end


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
        .dout(dout_bram) // Data Output
    );




endmodule
module debounce #(
parameter TIME_LENGTH = 1000000,//t=10ms
WIDTH = 1
) (
    input clk, rstn,
    input [WIDTH-1:0] x, 
    output reg [WIDTH-1:0] y
);

    reg pe,ce;
    wire [19:0] counter_output;
    reg [WIDTH-1:0] last_signal;

    wire [WIDTH-1:0] is_change;
    assign is_change=last_signal^x;

    counter #(.WIDTH(20),.RST_VLU(TIME_LENGTH)) counter_u0
    (
        .clk(clk), 
        .rstn(rstn), 
        .pe(pe), //同步置数使能
        .ce(ce), //计数使能
        .d(TIME_LENGTH),
        .q(counter_output)

    );
    always @(posedge clk, negedge rstn) begin
        if (!rstn) 
        begin
            pe<=1'b1;
            ce<=1'b0;
            last_signal<=x;
            y<=x;
        end
        else 
        begin
            if(!counter_output)
            begin 
                pe<=1'b1;
                ce<=1'b0;
                last_signal<=x;
                y<=x;
            end
            
            if(is_change)
            begin
                pe<=1'b1;
                ce<=1'b0;
            end
            else
            begin 
                pe<=1'b0;
                ce<=1'b1;
            end
            last_signal<=x;
        end
    end
    
    
endmodule
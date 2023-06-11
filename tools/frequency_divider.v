module frequency_divider  (
    input clk,rstn,
    input [31:0] k,//k要保证小于2^32-1
    output reg y
);
    reg pe,ce;
    wire [31:0] counter_output;
    counter #(.WIDTH(32),.RST_VLU(0)) counter_u0
    (
        .clk(clk), 
        .rstn(rstn), 
        .pe(pe), //同步置数使能
        .ce(ce), //计数使能
        .d(k-1),
        .q(counter_output)
    );


    always @(*) begin
        if (!rstn) 
        begin
            pe=1'b1;
            ce=1'b0;
        end
        else
        begin
            if(!counter_output)//0
            begin 
                pe=1'b1;
                ce=1'b0;
            end
            else
            begin
                pe=1'b0;
                ce=1'b1;
            end
        end
    end
    always @(posedge clk, negedge rstn) begin//这段奇偶都能正确处理
        if (!rstn) 
            y<=1'b0;
        else
        begin
            if(counter_output=={1'b0,k[31:1]})//过半
                y<=1;
            else
            begin
                if(!counter_output)//0          
                    y<=0;
            end
        end
    end
endmodule
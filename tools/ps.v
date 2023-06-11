module ps(
    input rstn,clk,x,
    output y
);//两级同步再取上升沿
    reg r1,r2,r3;
    always@(posedge clk)
    begin
        r1<=x;
        r2<=r1;
        r3<=r2;
    end
    assign y=r2 & ~r3;
endmodule

















/*module ps  (
    input clk, rstn, x, 
    output reg y
);
    reg last_signal;

    wire is_pos;
    assign is_pos=(!last_signal)&x;
    always @(posedge clk, negedge rstn) begin
        if (!rstn) 
        begin
            last_signal<=x;
            y<=0;
        end
        else 
        begin
            last_signal<=x;
            y<=is_pos;

        end
    end
endmodule*/
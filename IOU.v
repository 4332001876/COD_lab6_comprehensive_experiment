module IOU#(
    DATA_WIDTH = 32
)
(
    input clk,
    input rstn,
    //io_bus
    input [7:0] io_addr,//输入，8位，外设地址
    input [DATA_WIDTH-1:0] io_dout,//输入，也是CPU的输出，32位，输入外设的数据
    output [DATA_WIDTH-1:0] io_din,//输出，也是CPU的输入，32位，外设输出数据
    input io_we,//输入，1位，写外设控制信号
    input io_rd,//输入，1位，读外设控制信号
    //device
    output [15:0] led,
    input [15:0] sw,
    input btnr,
    input btnc,
    output [7:0] an,
    output [6:0] cn,
    output reg [DATA_WIDTH-1:0] cnt_data,swx_data

);


    /*
    序号 偏移地址 名称 读写类型 外设说明
    0 0x00 led_data W(写) led15-0
    1 0x04 swt_data R(读) btn, sw15-0
    2 0x08 seg_rdy R 数码管准备好
    3 0x0C seg_data W 数码管输出数据
    4 0x10 swx_vld R 开关输入有效
    5 0x14 swx_data R 开关输入数据
    6 0x18 cnt_data RW(读写) 计数器数据
    */
    reg [DATA_WIDTH-1:0] led_data,swt_data,seg_rdy,seg_data,swx_vld;
    assign led=led_data[15:0];
    //io_din
    always@(*) begin
        case(io_addr) 
            8'h04: io_din = swt_data;
            8'h08: io_din = seg_rdy;
            8'h10: io_din = swx_vld;
            8'h14: io_din = swx_data;
            8'h18: io_din = cnt_data;
            default: io_din = 0;
        endcase
    end

    wire btnc_p,btnr_p;
    dp #(
        .WIDTH(1)
    )dp_u0(
        .clk(clk),
        .rstn(rstn),
        .x(btnc),
        .y(btnc_p)
    );
    dp #(
        .WIDTH(1)
    )dp_u0(
        .clk(clk),
        .rstn(rstn),
        .x(btnr),
        .y(btnr_p)
    );

    wire [15:0] sw_p;
    dp #(
        .WIDTH(16)
    )dp_u0(
        .clk(clk),
        .rstn(rstn),
        .x(sw),
        .y(sw_p)
    );
    wire p;
    assign p=|sw_p;
    wire [3:0] h;//sw_number in hex
    always@(*) begin
        //对开关输入进行优先编码
        //拆成两段提高效率
        if(|sw_p[7:0]) begin
            if(sw_p[0])
                h = 4'h0;
            else if(sw_p[1])
                h = 4'h1;
            else if(sw_p[2])
                h = 4'h2;
            else if(sw_p[3])
                h = 4'h3;
            else if(sw_p[4])
                h = 4'h4;
            else if(sw_p[5])
                h = 4'h5;
            else if(sw_p[6])
                h = 4'h6;
            else if(sw_p[7])
                h = 4'h7;
            else
                h = 4'h0;
        end
        else begin
            if(sw_p[8])
                h = 4'h8;
            else if(sw_p[9])
                h = 4'h9;
            else if(sw_p[10])
                h = 4'ha;
            else if(sw_p[11])
                h = 4'hb;
            else if(sw_p[12])
                h = 4'hc;
            else if(sw_p[13])
                h = 4'hd;
            else if(sw_p[14])
                h = 4'he;
            else if(sw_p[15])
                h = 4'hf;
            else
                h = 4'h0;
        end
    end


        




    dis dis_u0  (
        .clk(clk),
        .rstn(rstn),
        .d(seg_data),
        .an(an),
        .cn(cn)
    );


















endmodule
module hazard_detection(
    input [4:0] rs1,//in IFID
    input [4:0] rs2,//in IFID
    input [4:0] IDEX_rd,
    input IDEX_MemRead,
    input Branch,
    input is_jump,
    input condition,
    output reg control_flush,//清空控制信号
    output reg instrution_flush,//清空指令，优先级大于IFID_we
    output reg pc_we,
    output reg IFID_we
);
    always@(*) begin 
        //其实可以把第一个if内内容看作是不修改后续执行指令的阻塞，而把第二个if内内容看作是修改后续执行指令的阻塞
        if((IDEX_MemRead&((IDEX_rd==rs1)|(IDEX_rd==rs2)))) begin //load-use hazard
            control_flush=1;
            pc_we=0;//保留紧跟着的第二条指令
            IFID_we=0;//保留紧跟着的第一条指令
            instrution_flush=0;
        end
        else if(is_jump|(Branch&condition)) begin //若跳转：B-type, jal, jalr，则清空IFID中指令及IDEX中控制信号，并将pc改为跳转后地址
            control_flush=1;
            pc_we=1;//pc改为跳转后地址
            IFID_we=0;
            instrution_flush=1;
        end
        else begin //normal
            control_flush=0;
            pc_we=1;
            IFID_we=1;
            instrution_flush=0;
        end

    end
    

    



















endmodule
module hazard_detection(
    input [4:0] rs1,//in IFID
    input [4:0] rs2,//in IFID
    input [4:0] IDEX_rd,
    input IDEX_MemRead,
    input Branch,
    input is_jump,
    input condition,
    input cache_miss,//(!hit)&mem_en
    output reg control_flush,//清空控制信号
    output reg instrution_flush,//清空指令，优先级大于IFID_we
    output reg pc_we,
    output reg IFID_we,
    //以下三个仅用于缓存未命中的情况
    output reg IDEX_we,
    output reg EXMEM_we,
    output reg MEMWB_we
);
    always@(*) begin 
        //其实可以把第一个if内内容看作是不修改后续执行指令的阻塞，而把第二个if内内容看作是修改后续执行指令的阻塞
        IDEX_we=1;
        EXMEM_we=1;
        MEMWB_we=1;
        if(cache_miss) begin //cache未命中，则停下所有的流水线阶段
            control_flush=0;
            pc_we=0;
            IFID_we=0;
            instrution_flush=0;

            IDEX_we=0;
            EXMEM_we=0;
            MEMWB_we=0;
        end
        else if((IDEX_MemRead&((IDEX_rd==rs1)|(IDEX_rd==rs2)))) begin //load-use hazard
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
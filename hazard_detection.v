module hazard_detection(
    input [31:0] src_IR,
    input [4:0] rs1,//in IFID
    input [4:0] rs2,//in IFID
    input [4:0] IDEX_rd,
    input IDEX_MemRead,
    input Branch,
    input is_jump,
    input EXMEM_Branch, 
    input EXMEM_is_jump,
    output reg control_flush,
    output reg pc_we,
    output reg IFID_we
);
    wire [6:0] opcode;
    assign opcode=src_IR[6:0];
    always@(*) begin 
        if((IDEX_MemRead&((IDEX_rd==rs1)|(IDEX_rd==rs2)))) begin //load-use hazard
            control_flush=1;
            pc_we=0;//保留紧跟着的第二条指令
            IFID_we=0;//保留紧跟着的第一条指令
        end
        else if(opcode==7'b1100011|((opcode[6:4]==3'b110)&(opcode[2:0]==3'b111))) begin //跳转：B-type, jal, jalr  cycle#1
            if(Branch|is_jump) begin //next IR
                control_flush=1;
                pc_we=1;//设为pc可跳转，下回合opcode就变了，这个if分支将退出（除非又来一条跳转，程序进入下面的if分支）
                IFID_we=1;
            end
            else if (EXMEM_Branch|EXMEM_is_jump) begin //B-type, jal, jalr  cycle#2  且下一条指令为跳转
                control_flush=1;
                pc_we=0;//把pc定死在跳转语句
                IFID_we=1;
            end
            else begin
                control_flush=0;
                pc_we=0;//把pc定死在跳转语句
                IFID_we=1;//第一次必须把跳转指令写进IFID
            end
        end
        else if (EXMEM_Branch|EXMEM_is_jump) begin //跳转：B-type, jal, jalr  cycle#2  且下一条指令非跳转
            control_flush=1;
            pc_we=1;//必须是1
            IFID_we=1;//必须是1
        end
        else begin //normal
            control_flush=0;
            pc_we=1;
            IFID_we=1;

        end

    end
    

    



















endmodule
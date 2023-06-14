module cpu_top #(
    parameter WORD_WIDTH = 32,     //字长
    parameter ADDR_WIDTH = 32      //地址宽度
)(
        input clk,
        input rstn,
        output [31:0] pc_chk, //用于SDU进行断点检查，在单周期cpu中，pc_chk = pc
        output [31:0] npc,    //next_pc
        output reg [31:0] pc,
        output [31:0] IR,     //当前指令
        output [31:0] IMM,    //立即数
        output [31:0] CTL,    //控制信号，你可以将所有控制信号集成一根bus输出
        output reg [31:0] A,      //ALU的输入A
        output [31:0] B,      //ALU的输入B
        output [31:0] Y,      //ALU的输出
        output [31:0] MDR,    //数据存储器的输出
    /*
        addr是SDU输出给cpu的地址，
        cpu根据这个地址从ins_mem/reg_file/data_mem中读取数据，三者共用一个地址！
        注意，这个地址是你在串口输入的地址，不需要进行任何处理，直接接入cpu中的对应模块即可
        dout_rf 是从reg_file中读取的addr地址的数据
        dout_dm 是从data_mem中读取的addr地址的数据
        dout_im 是从ins_mem中读取的addr地址的数据
        din 是SDU输出给cpu的数据，cpu需要将这个数据写入到addr地址对应的存储器中
        we_dm 是数据存储器写使能信号，当we_dm为1时，cpu将din中的数据写入到addr地址对应的存储器中
        we_im 是指令存储器写使能信号，当we_im为1时，cpu将din中的数据写入到addr地址对应的存储器中
        clk_ld 是SDU输出的用于调试时写入ins_mem/data_mem的时钟，要跟clk_cpu区分开，这两个clk同时只会有一个在工作
        debug 是调试信号，当debug为1时，cpu的ins_mem和data_mem应使用clk_ld时钟，否则使用clk时钟
        */
        input [31:0] addr,   
        output [31:0] dout_rf,
        output [31:0] dout_dm,
        output [31:0] dout_im,
        input [31:0] din,
        input we_dm,
        input we_im,
        input clk_ld,
        input debug,
        //io_bus
        output [7:0] io_addr,//输入，8位，外设地址
        output [31:0] io_dout,//输入，也是CPU的输出，32位，输入外设的数据
        input [31:0] io_din,//输出，也是CPU的输入，32位，外设输出数据
        output io_we,//输入，1位，写外设控制信号
        output io_rd//输入，1位，读外设控制信号
);
    parameter NOP=32'h0;
//pipeline register
    // =====pipeline data
    reg [31:0] IFID_IR; // pipeline ir
    reg [31:0] IFID_pc, IDEX_pc,EXMEM_pc,MEMWB_pc;//pipeline pc
    reg [31:0] IDEX_temp_a, IDEX_temp_b,IDEX_IMM,EXMEM_Y;//pipeline alu
    reg [2:0] IDEX_funct3;
    reg [4:0] IDEX_rs1, IDEX_rs2, IDEX_rd, EXMEM_rd, MEMWB_rd;//pipeline reg_addr
    reg [31:0] EXMEM_wdata;
    reg [31:0] MEMWB_Y, MEMWB_MDR;//pipeline wback result

    always@(posedge clk) begin
        if(!rstn) begin
            IFID_IR<=0;
            IFID_pc<=0;
            IDEX_pc<=0;
            EXMEM_pc<=0;
            MEMWB_pc<=0;
        end
        else begin
            if(instrution_flush) begin
                IFID_IR<=NOP;
            end
            else begin
                if(IFID_we)
                    IFID_IR<=src_IR;
            end
            if(IFID_we) begin
                IFID_pc<=pc;
            end
            if(IDEX_we) begin
                IDEX_pc<=IFID_pc;
            end
            if(EXMEM_we) begin
                EXMEM_pc<=IDEX_pc;
            end
            if(MEMWB_we) begin
                MEMWB_pc<=EXMEM_pc;
            end
        end
    end//*done

    always@(posedge clk) begin
        if(IDEX_we) begin
            IDEX_temp_a<=src_temp_a;
            IDEX_temp_b<=src_temp_b;
            IDEX_IMM<=src_IMM;
        end
        if(EXMEM_we) begin
            EXMEM_Y<=src_Y;
        end      
    end//*done

    always@(posedge clk) begin
        if(IDEX_we) begin
            IDEX_funct3<=IFID_IR[14:12];
            IDEX_rs1<=IFID_IR[19:15];
            IDEX_rs2<=IFID_IR[24:20];
            IDEX_rd<=IFID_IR[11:7];
        end
        if(EXMEM_we) begin
            EXMEM_rd<=IDEX_rd;
        end
        if(MEMWB_we) begin
            MEMWB_rd<=EXMEM_rd;
        end
    end//*done

    always@(posedge clk) begin
        if(EXMEM_we) begin
            EXMEM_wdata<=temp_b;
        end
        if(MEMWB_we) begin
            MEMWB_Y<=EXMEM_Y;
            MEMWB_MDR<=src_MDR;
        end
    end//*done



    // =====pipeline_ctrl //*done
    //IDEX: 
    reg IDEX_MemRead,IDEX_MemtoReg,IDEX_MemWrite,IDEX_ALUSrc,IDEX_RegWrite,IDEX_RegWriteSrc;
    //RegWriteSrc=1:pc+4
    reg IDEX_Branch,IDEX_is_jalr,IDEX_is_jump;
    reg [1:0] IDEX_ALUSrc_a;//00:reg  01:0  10:pc  
    reg [2:0] IDEX_ALUf; 
    //EXMEM: eliminate is_jalr,is_jump,Branch(for npc)
    reg EXMEM_MemRead,EXMEM_MemtoReg,EXMEM_MemWrite,EXMEM_RegWrite,EXMEM_RegWriteSrc;//RegWriteSrc=1:pc+4
    //MEMWB: 
    reg MEMWB_MemtoReg,MEMWB_RegWrite,MEMWB_RegWriteSrc;//RegWriteSrc=1:pc+4

    // =====pipeline_ctrl_assignment
    //IDEX:
    wire src_MemRead,src_MemtoReg,src_MemWrite,src_ALUSrc,src_RegWrite,src_RegWriteSrc;
    wire src_Branch,src_is_jalr,src_is_jump;
    //RegWriteSrc=1:pc+4
    wire [1:0] src_ALUSrc_a;//00:reg  01:0  10:pc 
    wire [2:0] src_ALUf; 
    always@(posedge clk) begin
        if(!rstn) begin
            IDEX_MemRead<=0;
            IDEX_MemtoReg<=0;
            IDEX_MemWrite<=0;
            IDEX_ALUSrc<=0;
            IDEX_RegWrite<=0;
            IDEX_RegWriteSrc<=0;
            IDEX_ALUSrc_a<=0;
            IDEX_ALUf<=2;
            IDEX_Branch<=0;
            IDEX_is_jalr<=0;
            IDEX_is_jump<=0;
        end
        else begin
            if(control_flush) begin
                IDEX_MemRead<=0;
                IDEX_MemtoReg<=0;
                IDEX_MemWrite<=0;
                IDEX_ALUSrc<=0;
                IDEX_RegWrite<=0;
                IDEX_RegWriteSrc<=0;
                IDEX_ALUSrc_a<=0;
                IDEX_ALUf<=2;
                IDEX_Branch<=0;
                IDEX_is_jalr<=0;
                IDEX_is_jump<=0;

            end
            else if(IDEX_we) begin
                IDEX_MemRead<=src_MemRead;
                IDEX_MemtoReg<=src_MemtoReg;
                IDEX_MemWrite<=src_MemWrite;
                IDEX_ALUSrc<=src_ALUSrc;
                IDEX_RegWrite<=src_RegWrite;
                IDEX_RegWriteSrc<=src_RegWriteSrc;
                IDEX_ALUSrc_a<=src_ALUSrc_a;
                IDEX_ALUf<=src_ALUf;
                IDEX_Branch<=src_Branch;
                IDEX_is_jalr<=src_is_jalr;
                IDEX_is_jump<=src_is_jump;
            end
        end
    end//*done

    always@(posedge clk) begin
        if(!rstn) begin
            EXMEM_MemRead<=0;
            EXMEM_MemtoReg<=0;
            EXMEM_MemWrite<=0;
            EXMEM_RegWrite<=0;
            EXMEM_RegWriteSrc<=0;
        end
        else if(EXMEM_we) begin
            EXMEM_MemRead<=IDEX_MemRead;
            EXMEM_MemtoReg<=IDEX_MemtoReg;
            EXMEM_MemWrite<=IDEX_MemWrite;
            EXMEM_RegWrite<=IDEX_RegWrite;
            EXMEM_RegWriteSrc<=IDEX_RegWriteSrc;
        end
    end//*done

    always@(posedge clk) begin
        if(!rstn) begin
            MEMWB_MemtoReg<=0;
            MEMWB_RegWrite<=0;
            MEMWB_RegWriteSrc<=0;
        end
        else begin
            if(MEMWB_we) begin
                MEMWB_MemtoReg<=EXMEM_MemtoReg;
                MEMWB_RegWrite<=EXMEM_RegWrite;
                MEMWB_RegWriteSrc<=EXMEM_RegWriteSrc;
            end
        end
    end//*done

//========== forwarding
    wire [1:0] afwd,bfwd;
    forwarding_unit fwd_u0(
        .IDEX_rs1(IDEX_rs1),
        .IDEX_rs2(IDEX_rs2),
        .EXMEM_rd(EXMEM_rd),
        .MEMWB_rd(MEMWB_rd),
        .EXMEM_RegWrite(EXMEM_RegWrite),
        .MEMWB_RegWrite(MEMWB_RegWrite),
        .afwd(afwd),
        .bfwd(bfwd)
    );


//========== hazard
    wire control_flush,instrution_flush,pc_we,IFID_we;
    wire IDEX_we,EXMEM_we,MEMWB_we;//for cache_miss
    hazard_detection hazard_u0(
        .rs1(IR[19:15]),//in IFID
        .rs2(IR[24:20]),//in IFID
        .IDEX_rd(IDEX_rd),
        .IDEX_MemRead(IDEX_MemRead),
        .Branch(Branch),
        .is_jump(is_jump),
        .condition(condition),
        .cache_miss((!hit)&mem_en),
        .control_flush(control_flush),
        .instrution_flush(instrution_flush),
        .pc_we(pc_we),
        .IFID_we(IFID_we),
        .IDEX_we(IDEX_we),
        .EXMEM_we(EXMEM_we),
        .MEMWB_we(MEMWB_we)
    );

//========== stage1
//========== ctrl
    wire [31:0] src_IR;
    
    assign CTL={18'h0, ALUf, RegWriteSrc,is_jalr,is_jump,ALUSrc_a, Branch,MemRead,MemtoReg, MemWrite,ALUSrc,RegWrite};

    reg [31:0] npc_pc_src;
    always@(*) begin
        if(is_jalr)
            npc_pc_src=temp_a;
        else if(is_jump|(Branch&condition))
            npc_pc_src=IDEX_pc;
        else
            npc_pc_src=pc;
    end
    npc npc_u0(
        .pc(npc_pc_src),//it can be x[rs1]
        .is_jump(is_jump|(Branch&condition)),
        .is_jalr(is_jalr),
        .imm(IMM),
        .npc(npc)
    ); 

    always@(posedge clk, negedge rstn) begin
        if(!rstn)
            pc<=0;
        else if(pc_we)
            pc<=npc;
    end

    assign pc_chk=pc;//在单周期cpu中，pc_chk = pc

/*
    always@(posedge clk, negedge rstn) begin
        if(!rstn)
            pc_chk<=0;
        else
            pc_chk<=pc_chk+1;
    end*/
    wire mem_clk;
    assign mem_clk=debug?clk_ld:clk;
    //pc>>2
    //not debug input:pc,IR
    //debug input:debug,addr,din,clk_ld,we_im,dout_im
    dist_mem_gen_inst ir(
        .a(debug?addr[9:0]:pc[11:2]),        // input wire [9 : 0] a
        .d(din),        // input wire [31 : 0] d
        .dpra(addr[9:0]),  // input wire [9 : 0] dpra
        .clk(mem_clk),    // input wire clk
        .we(debug&we_im),      // input wire we
        .spo(src_IR),    // output wire [31 : 0] spo
        .dpo(dout_im)    // output wire [31 : 0] dpo
    );//read-only //*done

//========== stage2(&stage5)
    assign IR=IFID_IR;

    wire MemtoReg,RegWrite,RegWriteSrc;
    assign MemtoReg=MEMWB_MemtoReg;
    assign RegWrite=MEMWB_RegWrite;
    assign RegWriteSrc=MEMWB_RegWriteSrc;//RegWriteSrc=1:pc+4

    assign MDR=MEMWB_MDR;

    control ctrl_u0(
        .IR(IR),
        .Branch(src_Branch),
        .MemRead(src_MemRead),
        .MemtoReg(src_MemtoReg),
        .MemWrite(src_MemWrite),
        .ALUSrc(src_ALUSrc),
        .RegWrite(src_RegWrite),
        .is_jalr(src_is_jalr),
        .RegWriteSrc(src_RegWriteSrc),
        .is_jump(src_is_jump),
        .ALUf(src_ALUf),//[2:0]
        .ALUSrc_a(src_ALUSrc_a)//00:reg  01:0  10:pc  //[1:0]
    );//*done

//===== rf
    wire [31:0] src_temp_a,src_temp_b;
    reg [31:0] reg_wdata;

    always@(*) begin 
        if(RegWriteSrc)
            reg_wdata=MEMWB_pc+4;//jal, jalr
        else if(MemtoReg)
            reg_wdata=MDR;
        else
            reg_wdata=MEMWB_Y;
    end
    //rs1, rs2, rd, RegWrite, reg_wdata, src_temp_a, src_temp_b
    rf rf_u0(
        .rs1(IR[19:15]),
        .rs2(IR[24:20]),
        .rs_debug(addr[4:0]),
        .rd(MEMWB_rd),
        .wdata(reg_wdata),
        .clk(clk),
        .we(RegWrite),
        .a(src_temp_a),
        .b(src_temp_b),
        .debug_rf(dout_rf)
    );

    wire [31:0] src_IMM;
    immgen immgen_u0(
        .inst(IR),
        .out(src_IMM)
    ); //*done
//========== stage3
    wire Branch,is_jalr,is_jump;
    assign Branch=IDEX_Branch;
    assign is_jalr=IDEX_is_jalr;
    assign is_jump=IDEX_is_jump;

    wire [1:0] ALUSrc_a;//00:reg  01:0  10:pc 
    wire [2:0] ALUf; 
    wire ALUSrc;
    assign ALUSrc_a=IDEX_ALUSrc_a;
    assign ALUf=IDEX_ALUf;
    assign ALUSrc=IDEX_ALUSrc;

    reg [31:0] temp_a,temp_b;
    always@(*) begin
        case(afwd) 
            2'b00:temp_a=IDEX_temp_a;
            2'b01:temp_a=reg_wdata;
            2'b10:temp_a=EXMEM_Y;
            default:temp_a=IDEX_temp_a;
        endcase
    end
    always@(*) begin
        case(bfwd) 
            2'b00:temp_b=IDEX_temp_b;
            2'b01:temp_b=reg_wdata;
            2'b10:temp_b=EXMEM_Y;
            default:temp_b=IDEX_temp_b;
        endcase
    end
    assign IMM=IDEX_IMM;

    wire [2:0] ALUt;
    wire condition;
    condition condition_u0(
        .funct3(IDEX_funct3),
        .ALUt(ALUt), 
        .condition(condition)
    );
//===== ALU
    always @(*) begin
        case(ALUSrc_a)
            2'b00:A=temp_a;
            2'b01:A=0;
            2'b10:A=IDEX_pc;
            default:A=temp_a;
        endcase
    end
    assign B=(ALUSrc)?IMM:temp_b;

    wire [31:0] src_Y;
    alu alu_u0(
        .a(A), 
        .b(B),       //两操作数
        .f(ALUf),                      //功能选择
        .y(src_Y),     //运算结果
        .t(ALUt)                     //比较标志
    );


//========== stage4
//===== mem
    wire MemRead,MemWrite;
    assign MemRead=EXMEM_MemRead;
    assign MemWrite=EXMEM_MemWrite;

    assign Y=EXMEM_Y;
    
    reg [31:0] src_MDR;
    //EXMEM_wdata is temp_b;

    //addr>>2
    //base addr=0x2000
    wire [31:0] temp_mdr;
    /*dist_mem_gen_data dr(
        .a(debug?addr[9:0]:Y[11:2]),        // input wire [9 : 0] a
        .d(debug?din:EXMEM_wdata),        // input wire [31 : 0] d
        .dpra(addr[9:0]),  // input wire [9 : 0] dpra
        .clk(mem_clk),    // input wire clk
        .we(debug?we_dm:((Y>=32'h3000)?1'h0:MemWrite)),      // input wire we
        .spo(temp_mdr),    // output wire [31 : 0] spo
        .dpo(dout_dm)    // output wire [31 : 0] dpo
    );*/
    wire hit;
    wire mem_en;
    assign mem_en=(Y>=32'h3000)?1'h0:(MemRead|MemWrite);
    cache_direct_mapped #(
        .DATA_WIDTH(32),
        .ADDR_WIDTH(10),
        .INDEX_WIDTH(5),
        .TAG_WIDTH(2),
        .BLOCK_OFFSET_WIDTH(3)
    ) cache_direct_mapped_u0(
        .clk(mem_clk), // Clock
        .rstn(rstn),
        .addr(debug?addr[9:0]:Y[11:2]), // Address，要保证Miss后读写BRAM时长时间稳定
        .din(debug?din:EXMEM_wdata), // Data Input
        .we(debug?we_dm:((Y>=32'h3000)?1'h0:MemWrite)), // Write Enable
        .mem_en(mem_en), // Memory Enable，用于控制是否读写BRAM，从而控制命中/缺失判断与换页
        .hit(hit),
        .dout(temp_mdr), // Data Output
        .debug_addr(addr[9:0]),
        .debug_dout(dout_dm)
    );





//===== mmio
    //Y>=32'h3000为mmio地址，偏移量为低八位
    assign io_addr=Y[7:0];
    assign io_dout=debug?din:EXMEM_wdata;
    always@(*) begin
        if(Y>=32'h3000)
            src_MDR=io_din;
        else
            src_MDR=temp_mdr;
    end
    assign io_rd=(Y>=32'h3000)?MemRead:1'h0;
    assign io_we=(Y>=32'h3000)?MemWrite:1'h0;




endmodule
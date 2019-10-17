`include "mycpu.h"

//666
module id_stage(
	input                          clk           ,
	input                          reset         ,
	//allowin
	input                          es_allowin    ,
	output                         ds_allowin    ,
	//from fs
	input                          fs_to_ds_valid,
	input  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus  ,
	//to es
	output                         ds_to_es_valid,
	output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
	//to fs
	output [`BR_BUS_WD       -1:0] br_bus        ,
	//to rf: for write back
	input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus  ,

	input [4:0] es_real_dest,
	input [4:0] ws_real_dest,
	input [4:0] ms_real_dest,

	input [31:0] exe_forward_data,//lab5
	input [31:0] mem_forward_data,//lab5
	input [31:0] wb_forward_data,//lab5

	input es_res_from_mem,//lab5
	input ms_res_from_mem,//lab5

	input [31:0] exe_forward_data_HI,//lab6
	input [31:0] exe_forward_data_LO,//lab6
	input [31:0] mem_forward_data_HI,//lab6
	input [31:0] mem_forward_data_LO,//lab6
	input [31:0] wb_forward_data_HI,//lab6
	input [31:0] wb_forward_data_LO,//lab6
	input        es_mt_op,
	input        es_mult_multu_div_divu_op,
	input [`SPECIAL_REG_ADDR_WD -1:0] es_dest_special,
	input        ms_mt_op,
	input        ms_mult_multu_div_divu_op,
	input [`SPECIAL_REG_ADDR_WD -1:0] ms_dest_special,
	input        ws_mt_op,
	input        ws_mult_multu_div_divu_op,
	input [`SPECIAL_REG_ADDR_WD -1:0] ws_dest_special
);

reg         ds_valid   ;
wire        ds_ready_go;

wire [31                 :0] fs_pc;
reg  [`FS_TO_DS_BUS_WD -1:0] fs_to_ds_bus_r;
assign fs_pc = fs_to_ds_bus[31:0];

wire [31:0] ds_inst;
wire [31:0] ds_pc  ;
assign {ds_inst,
		ds_pc  } = fs_to_ds_bus_r;

wire        rf_we   ;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;
wire [`SPECIAL_REG_ADDR_WD -1:0] rf_waddr_special;//lab6
wire [31:0] rf_wdata_HI;
wire [31:0] rf_wdata_LO;
assign {rf_wdata_HI, //103:72 lab6
		rf_wdata_LO, //71:40 lab6
		rf_waddr_special, //39:38 lab6
		rf_we   ,  //37:37
		rf_waddr,  //36:32
		rf_wdata   //31:0
	   } = ws_to_rf_bus;

wire        br_taken;
wire [31:0] br_target;

wire [15:0] alu_op;
wire        load_op;
wire        mf_op;//lab6
wire        mt_op;//lab6
wire        mult_multu_div_divu_op;//lab6
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm_signextend;//lab6, changed name
wire        src2_is_imm_zeroextend;//lab6, new
wire        src2_is_8;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [`define SPECIAL_REG_ADDR_WD:0] dest_special;//lab6
wire [15:0] imm;
wire [31:0] rs_value;
wire [31:0] rt_value;
wire [31:0] special_value;//lab6

wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;

wire		inst_addu;
wire		inst_subu;
wire		inst_slt;
wire		inst_sltu;
wire		inst_and;
wire		inst_or;
wire		inst_xor;
wire		inst_nor;
wire		inst_sll;
wire		inst_srl;
wire		inst_sra;
wire		inst_addiu;
wire		inst_lui;
wire		inst_lw;
wire		inst_sw;
wire		inst_beq;
wire		inst_bne;
wire		inst_jal;
wire		inst_jr;
//lab6
wire		inst_add;
wire		inst_addi;
wire		inst_sub;
wire		inst_slti;
wire		inst_sltiu;
wire		inst_andi;
wire		inst_ori;
wire		inst_xori;
wire		inst_sllv;
wire		inst_srav;
wire		inst_srlv;
wire		inst_mult;
wire		inst_multu;
wire		inst_div;
wire		inst_divu;
wire		inst_mfhi;
wire		inst_mflo;
wire		inst_mthi;
wire		inst_mtlo;

/* lab 7, branch */
wire		inst_bgez;
wire		inst_bgtz;
wire		inst_blez;
wire		inst_bltz;
wire		inst_j;
wire		inst_bltzal;
wire		inst_bgezal;
wire		inst_jalr;

/* lab 7, load/store */
wire		inst_lb;
wire		inst_lbu;
wire		inst_lh;
wire		inst_lhu;
wire		inst_lwl;
wire		inst_lwr;
wire		inst_sb;
wire		inst_sh;
wire		inst_swl;
wire		inst_swr;

wire        dst_is_r31;  
wire        dst_is_rt;
wire        dst_special_HI;//lab6
wire        dst_special_LO;//lab6

wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire [`SPECIAL_REG_ADDR_WD -1:0] rf_raddr_special;//lab6
wire [31:0] rf_rdata_special;//lab6

wire        rs_eq_rt;

assign br_bus       = {br_taken,br_target};

assign ds_to_es_bus = {
						mult_multu_div_divu_op  ,	//177:177 lab6
						mt_op                   ,	//176:176 lab6
						special_value           ,	//175:144 lab6
						mf_op                   ,	//143:143 lab6
						dest_special            ,	//142:141 lab6
						src2_is_imm_zeroextend  ,	//140:140
						alu_op                  ,	//139:124
						load_op                 ,	//123:123
						src1_is_sa              ,	//122:122
						src1_is_pc              ,	//121:121
						src2_is_imm_signextend  ,	//120:120
						src2_is_8               ,	//119:119
						gr_we                   ,	//118:118
						mem_we                  ,	//117:117
						dest                    ,	//116:112
						imm                     ,	//111:96
						rs_value                ,	//95 :64
						rt_value                ,	//63 :32
						ds_pc                    	//31 :0
						};

assign ds_ready_go    =
	BlockOrNot ? 1'b0 : 1'b1;//lab5, just lw

assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go;
always @(posedge clk) begin
	if (fs_to_ds_valid && ds_allowin) begin
		fs_to_ds_bus_r <= fs_to_ds_bus;
	end
end
always @(posedge clk) begin
	if(reset) begin
		ds_valid <= 1'b0;
	end
	else if(ds_allowin) begin
		ds_valid <= fs_to_ds_valid;
	end
end

assign op   = ds_inst[31:26];
assign rs   = ds_inst[25:21];
assign rt   = ds_inst[20:16];
assign rd   = ds_inst[15:11];
assign sa   = ds_inst[10: 6];
assign func = ds_inst[ 5: 0];
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_addiu  = op_d[6'h09];
assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw     = op_d[6'h23];
assign inst_sw     = op_d[6'h2b];
assign inst_beq    = op_d[6'h04];
assign inst_bne    = op_d[6'h05];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];
/* lab 6 */
assign inst_add   = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_addi  = op_d[6'h08];
assign inst_sub   = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_slti  = op_d[6'h0a];
assign inst_sltiu = op_d[6'h0b];
assign inst_andi  = op_d[6'h0c];
assign inst_ori   = op_d[6'h0d];
assign inst_xori  = op_d[6'h0e];
assign inst_sllv  = op_d[6'h00] & func_d[6'h04] & sa_d[5'h00];
assign inst_srav  = op_d[6'h00] & func_d[6'h07] & sa_d[5'h00];
assign inst_srlv  = op_d[6'h00] & func_d[6'h06] & sa_d[5'h00];
assign inst_mult  = op_d[6'h00] & func_d[6'h18] & sa_d[5'h00] & rd_d[5'h00];
assign inst_multu = op_d[6'h00] & func_d[6'h19] & sa_d[5'h00] & rd_d[5'h00];
assign inst_div   = op_d[6'h00] & func_d[6'h1a] & sa_d[5'h00] & rd_d[5'h00];
assign inst_divu  = op_d[6'h00] & func_d[6'h1b] & sa_d[5'h00] & rd_d[5'h00];
assign inst_mfhi  = op_d[6'h00] & func_d[6'h10] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mflo  = op_d[6'h00] & func_d[6'h12] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mthi  = op_d[6'h00] & func_d[6'h11] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mtlo  = op_d[6'h00] & func_d[6'h13] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];

assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal | inst_add | inst_addi;
assign alu_op[ 1] = inst_subu | inst_sub;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltiu;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_sll | inst_sllv;
assign alu_op[ 9] = inst_srl | inst_srlv;
assign alu_op[10] = inst_sra | inst_srav;
assign alu_op[11] = inst_lui;
assign alu_op[12] = inst_mult;//lab6
assign alu_op[13] = inst_multu;//lab6
assign alu_op[14] = inst_div;//lab6
assign alu_op[15] = inst_divu;//lab6

assign load_op = inst_lw;
assign mf_op = inst_mfhi | inst_mflo;//lab6
assign mt_op = inst_mthi | inst_mtlo;//lab6
assign mult_multu_div_divu_op = inst_mult |inst_multu |inst_div | inst_divu;//lab6

assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal;
assign src2_is_imm_signextend =
	inst_addiu | inst_lui | inst_lw | inst_sw |
	inst_addi | inst_slti | inst_sltiu;//lab6
assign src2_is_imm_zeroextend =
	inst_andi | inst_ori | inst_xori;//lab6
assign src2_is_8    = inst_jal;
assign res_from_mem = inst_lw;
assign dst_is_r31   = inst_jal;
assign dst_is_rt    =
	inst_addiu | inst_lui | inst_lw |
	inst_addi | inst_slti | inst_sltiu | inst_andi | inst_ori | inst_xori;//lab6
assign dst_special_HI =
	inst_mult | inst_multu |inst_div | inst_divu | inst_mthi;//lab6
assign dst_special_LO =
	inst_mult | inst_multu |inst_div | inst_divu | inst_mtlo;//lab6
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr;//???????????
assign mem_we       = inst_sw;
assign dest         = dst_is_r31 ? 5'd31 :
					  dst_is_rt  ? rt    : 
								   rd;
assign dest_special = {dst_special_LO, dst_special_HI};//lab6

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
assign rf_raddr_special = {inst_mflo,inst_mfhi};//lab6
wire [31:0] rf_rdata_special;//lab6
regfile u_regfile(
	.clk    (clk      ),
	.raddr1 (rf_raddr1),
	.rdata1 (rf_rdata1),
	.raddr2 (rf_raddr2),
	.rdata2 (rf_rdata2),
	.raddr_special (rf_raddr_special),//lab6
	.rdata_special (rf_rdata_special),//lab6
	.we     (rf_we    ),
	.waddr  (rf_waddr ),
	.wdata  (rf_wdata ),
	.waddr_special (rf_waddr_special),//lab6
	.wdata_HI (rf_wdata_HI),//lab6
	.wdata_LO (rf_wdata_LO)//lab6
	);

assign rs_value =//select from: exe_forward_data, mem_forward_data, wb_forward_data, rf_rdata1
	(read_rs_or_not & (es_real_dest==rs) & rs_notzero) ? exe_forward_data :
	(read_rs_or_not & (ms_real_dest==rs) & rs_notzero) ? mem_forward_data :
	(read_rs_or_not & (ws_real_dest==rs) & rs_notzero) ? wb_forward_data :
	rf_rdata1;
assign rt_value =//select from: exe_forward_data, mem_forward_data, wb_forward_data, rf_rdata2
	(read_rt_or_not & (es_real_dest==rt) & rt_notzero) ? exe_forward_data :
	(read_rt_or_not & (ms_real_dest==rt) & rt_notzero) ? mem_forward_data :
	(read_rt_or_not & (ws_real_dest==rt) & rt_notzero) ? wb_forward_data :
	rf_rdata2;
assign special_value =//lab6 mfhi/mflo after mult/multu/div/divu/mthi/mtlo
	(es_mult_multu_div_divu_op | (es_mt_op&(es_dest_special==rf_raddr_special))) ? (inst_mfhi ? exe_forward_data_HI : exe_forward_data_LO) :
	(ms_mult_multu_div_divu_op | (ms_mt_op&(ms_dest_special==rf_raddr_special))) ? (inst_mfhi ? mem_forward_data_HI : mem_forward_data_LO) :
	(ws_mult_multu_div_divu_op | (ws_mt_op&(ws_dest_special==rf_raddr_special))) ? (inst_mfhi ? wb_forward_data_HI : wb_forward_data_LO) :
	rf_rdata_special;

assign rs_eq_rt = (rs_value == rt_value);
assign br_taken = (   inst_beq  &&  rs_eq_rt
				   || inst_bne  && !rs_eq_rt
				   || inst_jal
				   || inst_jr
				  ) && ds_valid;
assign br_target = (inst_beq || inst_bne) ? (fs_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
				   (inst_jr)              ? rs_value :
				  /*inst_jal*/              {fs_pc[31:28], jidx[25:0], 2'b0};

//LUI,ADDU,ADDIU,SUBU,SLT,SLTU,AND,OR,XOR,NOR,SLL,SRL,SRA,LW,SW,BEQ,BNE,JAL,JR
wire rs_notzero;//if rs != 0, rs_notzero = 1
wire rt_notzero;
wire BlockOrNot;
wire read_rs_or_not;
wire read_rt_or_not;
assign rs_notzero = |rs;
assign rt_notzero = |rt;
assign BlockOrNot =//lab5, 1 situation: lw before read reg, same addr(not zero)
	es_res_from_mem & ((read_rs_or_not&(rs==es_real_dest)&rs_notzero) | (read_rt_or_not&(rt==es_real_dest)&rt_notzero));//load inst in exe stage
assign read_rs_or_not =
	inst_addu|inst_addiu|inst_subu|inst_slt|inst_sltu|inst_and|inst_or|inst_xor|inst_nor|inst_lw|inst_sw|inst_beq|inst_bne|inst_jr|
	inst_add|inst_addi|inst_sub|inst_slti|inst_sltiu|inst_andi|inst_ori|inst_xori|inst_sllv|inst_srav|inst_srlv|inst_mult|inst_multu|inst_div|inst_divu|inst_mthi|inst_mtlo;//lab6
assign read_rt_or_not =
	inst_addu|inst_subu|inst_slt|inst_sltu|inst_and|inst_or|inst_xor|inst_nor|inst_sll|inst_srl|inst_sra|inst_sw|inst_beq|inst_bne|
	inst_add|inst_sub|inst_sllv|inst_srav|inst_srlv|inst_mult|inst_multu|inst_div|inst_divu;//lab6

endmodule

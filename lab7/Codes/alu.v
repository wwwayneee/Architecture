module alu(
  input         clk,
  input         reset,
  output        signed_dout_tvalid,
  output        unsigned_dout_tvalid,
  input  [15:0] alu_op,
  input  [31:0] alu_src1,
  input  [31:0] alu_src2,
  output [31:0] alu_result,
  output [31:0] alu_result_HI
);

wire op_add;   //¼Ó·¨²Ù×÷
wire op_sub;   //¼õ·¨²Ù×÷
wire op_slt;   //ÓÐ·ûºÅ±È½Ï£¬Ð¡ÓÚÖÃÎ»
wire op_sltu;  //ÎÞ·ûºÅ±È½Ï£¬Ð¡ÓÚÖÃÎ»
wire op_and;   //°´Î»Óë
wire op_nor;   //°´Î»»ò·Ç
wire op_or;    //°´Î»»ò
wire op_xor;   //°´Î»Òì»ò
wire op_sll;   //Âß¼­×óÒÆ
wire op_srl;   //Âß¼­ÓÒÒÆ
wire op_sra;   //ËãÊõÓÒÒÆ
wire op_lui;   //Á¢¼´ÊýÖÃÓÚ¸ß°ë²¿·Ö
wire op_mult;   //lab6 ³Ë·¨
wire op_multu;  //lab6 ÎÞ·ûºÅ³Ë·¨ 
wire op_div;    //lab6 ³ý·¨
wire op_divu;   //lab6 ÎÞ·ûºÅ³ý·¨

// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];
assign op_mult = alu_op[12];//lab6
assign op_multu= alu_op[13];//lab6
assign op_div  = alu_op[14];//lab6
assign op_divu = alu_op[15];//lab6

wire [31:0] add_sub_result; 
wire [31:0] slt_result; 
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result; 
wire [63:0] sr64_result; 
wire [31:0] sr_result;
wire [63:0] mult_result;
wire [63:0] multu_result;
wire [63:0] div_result;
wire [63:0] divu_result;

/*
wire [63:0] div_result_LO;
wire [63:0] div_result_HI;
wire [63:0] divu_result_LO;
wire [63:0] divu_result_HI;
*/

/* Hand Shake signals for Division */
reg   signed_divisor_tvalid;
reg   signed_dividend_tvalid;
wire  signed_divisor_tready;
wire  signed_dividend_tready;

reg   unsigned_divisor_tvalid;
reg   unsigned_dividend_tvalid;
wire  unsigned_divisor_tready;
wire  unsigned_dividend_tready;



// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = {alu_src2[15:0], 16'b0};

// SLL result 
assign sll_result = alu_src2 << alu_src1[4:0];

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2[31]}}, alu_src2[31:0]} >> alu_src1[4:0];
assign sr_result   = sr64_result[31:0];

//lab6
assign mult_result = $signed(alu_src1) * $signed(alu_src2);
assign multu_result = alu_src1 * alu_src2;

/* may be not used, needs to be commented */
/*
assign div_result_LO = $signed(alu_src1) / $signed(alu_src2);
assign div_result_HI = $signed(alu_src1) % $signed(alu_src2);
assign divu_result_LO = alu_src1 / alu_src2;
assign divu_result_HI = alu_src1 % alu_src2;
*/

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result)
                  | ({32{op_mult}}       & mult_result[31:0])//lab6
                  | ({32{op_multu}}      & multu_result[31:0])//lab6
                  | ({32{op_div}}        & div_result_LO[31:0])//lab6
                  | ({32{op_divu}}       & divu_result_LO[31:0]);//lab6

assign alu_result_HI= ({32{op_mult}}     & mult_result[63:32])
                    | ({32{op_multu}}    & multu_result[63:32])
                    | ({32{op_div}}      & div_result_HI[63:32])
                    | ({32{op_divu}}     & divu_result_HI[63:32]);

/* Signed Division */
always @(posedge clk) begin
  if (reset) begin
    signed_divisor_tvalid <= 1'b0;
    signed_dividend_tvalid <= 1'b0;
  end
  else begin
    if (op_div && !signed_divisor_tvalid && !signed_dividend_tvalid) begin
      signed_divisor_tvalid <= 1'b1;
      signed_dividend_tvalid <= 1'b1;
    end
    else if (signed_divisor_tvalid && signed_dividend_tvalid && signed_divisor_tready && signed_dividend_tready) begin
      signed_divisor_tvalid <= 1'b0;
      signed_dividend_tvalid <= 1'b0;
    end
  end
end

/* Unsigned Division */
always @(posedge clk) begin
  if (reset) begin
    unsigned_divisor_tvalid <= 1'b0;
    unsigned_dividend_tvalid <= 1'b0;
  end
  else begin
    if (op_divu && !unsigned_divisor_tvalid && !unsigned_dividend_tvalid) begin
      unsigned_divisor_tvalid <= 1'b1;
      unsigned_dividend_tvalid <= 1'b1;
    end
    else if (unsigned_divisor_tvalid && unsigned_dividend_tvalid && unsigned_divisor_tready && unsigned_dividend_tready) begin
      unsigned_divisor_tvalid <= 1'b0;
      unsigned_dividend_tvalid <= 1'b0;
    end
  end
end


//调用 signed 除法IP
div_signed u_div_signed(
    .aclk                   (clk),

    .s_axis_divisor_tdata   (alu_src1),                 //除数
    .s_axis_divisor_tready  (signed_divisor_tready),   //除数通道
    .s_axis_divisor_tvalid  (signed_divisor_tvalid),   //除数通道


    .s_axis_dividend_tdata  (alu_src2),                 //被除数
    .s_axis_dividend_tready (signed_dividend_tready),   //被除数通道
    .s_axis_dividend_tvalid (signed_dividend_tvalid),   //被除数通道

    .m_axis_dout_tdata      (div_result),               //结果
    .m_axis_dout_tvalid     (signed_dout_tvalid)        //商和余数通道
    );

//调用 unsigned 除法IP
div_unsigned u_div_unsigned(
    .aclk                   (clk),

    .s_axis_divisor_tdata   (alu_src1),                   //除数
    .s_axis_divisor_tready  (unsigned_divisor_tready),    //除数通道
    .s_axis_divisor_tvalid  (unsigned_divisor_tvalid),    //除数通道


    .s_axis_dividend_tdata  (alu_src2),                   //被除数
    .s_axis_dividend_tready (unsigned_dividend_tready),   //被除数通道
    .s_axis_dividend_tvalid (unsigned_dividend_tvalid),   //被除数通道

    .m_axis_dout_tdata      (divu_result),                //结果
    .m_axis_dout_tvalid     (unsigned_dout_tvalid)        //商和余数通道
    );

endmodule
`include "mycpu.h"

module mem_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         ms_allowin    ,
    //from es
    input                          es_to_ms_valid,
    input  [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus  ,
    //to ws
    output                         ms_to_ws_valid,
    output [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus  ,
    //from data-sram
    input  [31                 :0] data_sram_rdata,
    output [4:0] ms_real_dest,
    output [31:0] mem_forward_data,
    output ms_res_from_mem,//lab5

    output [31:0] mem_forward_data_HI,//lab6
    output [31:0] mem_forward_data_LO,//lab6
    output        ms_mt_op,
    output        ms_mult_multu_div_divu_op,
    output [`SPECIAL_REG_ADDR_WD -1:0] ms_dest_special
);

reg         ms_valid;
wire        ms_ready_go;

reg [`ES_TO_MS_BUS_WD -1:0] es_to_ms_bus_r;
//wire        ms_res_from_mem;
wire        ms_res_from_special;//lab6
wire        ms_res_from_rs;//lab6
//wire        ms_mult_multu_div_divu_op;//lab6
wire        ms_gr_we;
wire [ 4:0] ms_dest;
//wire [`SPECIAL_REG_ADDR_WD -1:0] ms_dest_special;//lab6
wire [31:0] ms_special_value;//lab6
wire [31:0] ms_alu_result;
wire [31:0] ms_alu_result_HI; //lab6
wire [31:0] ms_rs_value; //lab6
wire [31:0] ms_pc;
assign {
        ms_mult_multu_div_divu_op, //171:171 lab6
        ms_rs_value             ,  //170:139 lab6
        ms_res_from_rs          ,  //138:138 lab6
        ms_alu_result_HI        ,  //137:106 lab6
        ms_special_value        ,  //105:74 lab6
        ms_res_from_special     ,  //73:73 lab6
        ms_dest_special         ,  //72:71 lab6
        ms_res_from_mem         ,  //70:70
        ms_gr_we                ,  //69:69
        ms_dest                 ,  //68:64
        ms_alu_result           ,  //63:32
        ms_pc                      //31:0
       } = es_to_ms_bus_r;

wire [31:0] mem_result;
wire [31:0] ms_final_result;
wire [31:0] ms_final_result_HI;//lab6

assign ms_to_ws_bus = { ms_res_from_rs      ,  //105:105 lab6
                        ms_mult_multu_div_divu_op, //104:104 lab6
                        ms_final_result_HI  ,  //103:72 lab6
                        ms_dest_special     ,  //71:70 lab6
                        ms_gr_we            ,  //69:69
                        ms_dest             ,  //68:64
                        ms_final_result     ,  //63:32
                        ms_pc                  //31:0
                        };

assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        es_to_ms_bus_r  = es_to_ms_bus;
    end
end

assign mem_result = data_sram_rdata;

assign ms_final_result =ms_res_from_mem ?       mem_result :
                        ms_res_from_special ?   ms_special_value : //lab6
                        ms_res_from_rs ?        ms_rs_value : //lab6
                                                ms_alu_result;
assign ms_final_result_HI = ms_res_from_rs ?    ms_rs_value ://lab6
                                                ms_alu_result_HI;//lab6

assign ms_real_dest = (ms_valid & ms_gr_we) ? ms_dest : 5'b00000;

assign mem_forward_data = ms_final_result;
assign mem_forward_data_HI = ms_res_from_rs ? ms_rs_value : ms_alu_result_HI;//lab6
assign mem_forward_data_LO = ms_res_from_rs ? ms_rs_value : ms_alu_result;//lab6
assign ms_mt_op = ms_res_from_rs;//lab6

endmodule
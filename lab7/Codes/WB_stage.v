`include "mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from ms
    input                           ms_to_ws_valid,
    input  [`MS_TO_WS_BUS_WD -1:0]  ms_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,
    output [ 4:0] ws_real_dest,
    output [31:0] wb_forward_data,
    output [31:0] wb_forward_data_HI,//lab6
    output [31:0] wb_forward_data_LO,//lab6
    output        ws_mt_op,
    output        ws_mult_multu_div_divu_op,
    output [`SPECIAL_REG_ADDR_WD -1:0] ws_dest_special
);

reg         ws_valid;
wire        ws_ready_go;

reg [`MS_TO_WS_BUS_WD -1:0] ms_to_ws_bus_r;
wire        ws_gr_we;
wire [ 4:0] ws_dest;
//wire [`SPECIAL_REG_ADDR_WD -1:0] ws_dest_special;//lab6
wire [31:0] ws_final_result;
wire [31:0] ws_final_result_HI;//lab6
//wire        ws_mult_multu_div_divu_op;//lab6
//wire        ws_mt_op;//lab6
wire [31:0] ws_pc;
assign {ws_mt_op            , //105:105 lab6
        ws_mult_multu_div_divu_op,//104:104 lab6
        ws_final_result_HI  ,  //103:72
        ws_dest_special     ,  //71:70
        ws_gr_we            ,  //69:69
        ws_dest             ,  //68:64
        ws_final_result     ,  //63:32
        ws_pc                  //31:0
       } = ms_to_ws_bus_r;

wire        rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
wire [`SPECIAL_REG_ADDR_WD -1:0] rf_waddr_special;
wire [31:0] rf_wdata_HI;
wire [31:0] rf_wdata_LO;
assign ws_to_rf_bus = { rf_wdata_HI, //103:72 lab6
                        rf_wdata_LO, //71:40 lab6
                        rf_waddr_special,  //39:38
                        rf_we   ,  //37:37
                        rf_waddr,  //36:32
                        rf_wdata   //31:0
                        };

assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ms_to_ws_bus_r <= ms_to_ws_bus;
    end
end

assign rf_wdata_HI = ws_final_result_HI;//lab6
assign rf_wdata_LO = ws_final_result;//lab6
assign rf_waddr_special = ws_dest_special;//lab6
assign rf_we    = ws_gr_we&&ws_valid;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_final_result;

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = ws_final_result;
assign ws_real_dest = rf_we ? ws_dest : 5'b00000;
assign wb_forward_data = ws_final_result;
assign wb_forward_data_HI = ws_mt_op ? ws_final_result : ws_final_result_HI;//lab6
assign wb_forward_data_LO = ws_final_result;//lab6

endmodule
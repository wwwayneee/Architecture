module regfile(
    input         clk,
    // READ PORT 1
    input  [ 4:0] raddr1,
    output [31:0] rdata1,
    // READ PORT 2
    input  [ 4:0] raddr2,
    output [31:0] rdata2,
    // READ OTHER REG
    input  [`SPECIAL_REG_ADDR_WD -1:0] raddr_special,//lab6
    output [31:0] rdata_special,//lab6
    // WRITE PORT
    input         we,       //write enable, HIGH valid
    input  [ 4:0] waddr,
    input  [31:0] wdata,
    input  [`SPECIAL_REG_ADDR_WD -1:0] waddr_special,//lab6
    input  [31:0] wdata_HI,//lab6
    input  [31:0] wdata_LO//lab6
);

reg [31:0] rf[31:0];
reg [31:0] HI;//lab6
reg [31:0] LO;//lab6

wire write_HI;//lab6
wire write_LO;//lab6

assign write_HI = waddr_special[0];//lab6
assign write_LO = waddr_special[1];//lab6

//WRITE
always @(posedge clk) begin
    if (we) begin
        rf[waddr]<= wdata;
    end
    if(write_HI) begin
        HI <= wdata_HI;
    end
    if(write_LO) begin
        LO <= wdata_LO;
    end
end

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];

//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];

//READ OUT SPECIAL
assign rdata_special =
    ({32{raddr_special[0]}} & HI) |
    ({32{raddr_special[1]}} & LO);

endmodule
`timescale 1ns/1ns

module cpu_68k(
	input CLK_68KCLK,
	input nRESET,
	input IPL1, IPL0,
	input nDTACK,
	output [23:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	output nLDS, nUDS,
	output nAS,
	output M68K_RW
);

wire [15:0] TG68K_DATAIN;
wire [15:0] TG68K_DATAOUT;
wire [31:0] TG68K_ADDR;
wire [24:0] DEBUG_ADDR;							// TODO: Remove
wire [15:0] REG_D6;								// TODO: Remove

assign M68K_DATA = M68K_RW ? 16'bzzzzzzzzzzzzzzzz : TG68K_DATAOUT;
assign TG68K_DATAIN = M68K_RW ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;

assign M68K_ADDR = TG68K_ADDR[23:1];

assign DEBUG_ADDR = {M68K_ADDR, 1'b0};		// TODO: Remove

tg68 TG68K(
		.clk(CLK_68KCLK),
		.reset(nRESET),
		.clkena_in(1'b1),
		.data_in(TG68K_DATAIN),
		.IPL({1'b1, IPL1, IPL0}),
		.dtack(nDTACK),
		.addr(TG68K_ADDR),
		.data_out(TG68K_DATAOUT),
		.as(nAS),
		.uds(nUDS),
		.lds(nLDS),
		.rw(M68K_RW),
		.REG_D6(REG_D6)
		);
	
endmodule

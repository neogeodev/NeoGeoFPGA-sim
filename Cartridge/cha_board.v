`timescale 1ns/1ns

module cha_board(
	input [15:0] SDA,
	
	input nSLOTCS,
	
	output [31:0] CR,
	input CA4, S2H1,
	input PCK2B, PCK1B,
	input [23:0] PBUS,
	
	input CLK_24M, CLK_12M, CLK_8M,
	input nRESET,
	
	output [7:0] FIXD,

	input SDRD0, SDRD1, nSDROM, nSDMRD,
	
	inout [7:0] SDD
);

	wire [19:0] C_LATCH;
	wire [15:0] S_LATCH;
	wire [20:0] C_ADDR;
	wire [16:0] S_ADDR;
	wire [15:0] C1DATA;
	wire [15:0] C2DATA;
	wire [21:11] MA;
	
	assign C_ADDR = {C_LATCH[19:4], CA4, C_LATCH[3:0]};
	assign S_ADDR = {S_LATCH[15:3], S2H1, S_LATCH[2:0]};
	
	assign CR = {C1DATA, C2DATA};		// Other way around ?
	
	rom_c1 C1(C_ADDR[17:0], C1DATA);
	rom_c2 C2(C_ADDR[17:0], C2DATA);
	rom_s1 S1(S_ADDR[16:0], FIXD);
	
	// Todo: Plug in M ROM
	rom_m1 M1({MA[16:11], SDA[10:0]}, SDD, nSDROM);

	zmc ZMC(SDRD0, SDA[1:0], SDA[15:8], MA);
	neo_273 N273(PBUS[19:0], PCK1B, PCK2B, C_LATCH, S_LATCH);

endmodule

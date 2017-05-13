`timescale 1ns/1ns

	aes_cha CHA(CLK_24M, nSDROM, nSDMRD, SDA, SDRD1, SDRD0, PBUS, CA4, LOAD, H, EVEN, S2H1, CLK_12M,
					PCK2B, PCK1B, FIXD, DOTA, DOTB, GAD, GBD, SDD, CLK_8M);

module aes_cha(
	input CLK_24M,
	input nSDROM, nSDMRD,
	input [15:0] SDA,
	input SDRD1, SDRD0, 
	input [23:0] PBUS,
	input CA4, LOAD, H, EVEN, S2H1,
	input CLK_12M,
	input PCK2B, PCK1B,
	output [7:0] FIXD,
	output DOTA, DOTB,
	output [3:0] GAD,
	output [3:0] GBD,
	inout [7:0] SDD,
	input CLK_8M
);

	wire [19:0] C_LATCH;
	wire [15:0] S_LATCH;
	wire [20:0] C_ADDR;
	wire [16:0] S_ADDR;
	wire [15:0] C1DATA;
	wire [15:0] C2DATA;
	wire [21:11] MA;
	wire [31:0] CR;
	
	assign C_ADDR = {C_LATCH[19:4], CA4, C_LATCH[3:0]};
	assign S_ADDR = {S_LATCH[15:3], S2H1, S_LATCH[2:0]};
	
	assign CR = {C1DATA, C2DATA};		// Other way around ?
	
	rom_c1 C1(C_ADDR[17:0], C1DATA);
	rom_c2 C2(C_ADDR[17:0], C2DATA);
	rom_s1 S1(S_ADDR[16:0], FIXD);
	
	rom_m1 M1(SDA, SDD, nSDROM, nSDMRD);
	
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);
	
	// Joyjoy doesn't use ZMC
	//rom_m1 M1({MA[16:11], SDA[10:0]}, SDD, nSDROM, nSDMRD);
	//zmc ZMC(SDRD0, SDA[1:0], SDA[15:8], MA);
	
	neo_273 N273(PBUS[19:0], PCK1B, PCK2B, C_LATCH, S_LATCH);

endmodule

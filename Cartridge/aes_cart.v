`timescale 1ns/1ns

// TODO: Check if all pins are listed OK

module aes_cart(
	// PROG top
	input nPORTADRS,
	input nSDPOE, SDPMPX,
	input [11:8] SDPA,
	inout [7:0] SDPAD,
	input nRESET,
	input CLK_68KCLKB,
	input nPORTWEL, nPORTWEU, nPORTOEL, nPORTOEU,
	input nROMOEL, nROMOEU,
	input nAS, M68K_RW,
	inout [15:0] M68K_DATA,
	
	// PROG bottom
	input [19:1] M68K_ADDR,
	input nROMOE,
	output nROMWAIT, nPWAIT1, nPWAIT0, PDTACK,
	inout [7:0] SDRAD,
	input [9:8] SDRA_L,
	input [23:20] SDRA_U,
	input SDRMPX, nSDROE,
	input CLK_4MB,
	
	// CHA top
	input CLK_24M,
	input nSDROM, nSDMRD,
	input [15:0] SDA,
	input SDRD1, SDRD0,
	input [23:0] PBUS,
	input CA4, LOAD, H, EVEN, S2H1,
	input CLK_12M,
	input PCK2B, PCK1B,
	
	// CHA bottom
	output [7:0] FIXD,
	output DOTA, DOTB,
	output [3:0] GAD,
	output [3:0] GBD,
	inout [7:0] SDD,
	input CLK_8M
);
	
	aes_prog PROG(nPORTADRS, nSDPOE, SDPMPX, SDPA, SDPAD, nRESET, CLK_68KCLKB, nPORTWEL, nPORTWEU,
					nPORTOEL, nPORTOEU, nROMOEL, nROMOEU, nAS, M68K_RW, M68K_DATA, M68K_ADDR, nROMOE,
					nROMWAIT, nPWAIT1, nPWAIT0, PDTACK, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE, CLK_4MB);
					
	aes_cha CHA(CLK_24M, nSDROM, nSDMRD, SDA, SDRD1, SDRD0, PBUS, CA4, LOAD, H, EVEN, S2H1, CLK_12M,
					PCK2B, PCK1B, FIXD, DOTA, DOTB, GAD, GBD, SDD, CLK_8M);

endmodule

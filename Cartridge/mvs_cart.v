`timescale 1ns/1ns

module mvs_cart(
	input [23:0] PBUS,
	input CA4,
	input S2H1,
	input PCK1B,
	input PCK2B,
	output [31:0] CR,
	output [7:0] FIXD,
	
	input [18:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nROMOE,
	input nPORTOEL,
	input nPORTOEU,
	input nSLOTCS,
	output nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	
	inout [7:0] SDRAD,
	input [9:8] SDRA_L,
	input [23:20] SDRA_U,
	input SDRMPX, nSDROE,
	
	inout [7:0] SDPAD,
	input [11:8] SDPA,
	input SDPMPX, nSDPOE,
	
	input nSDROM,
	input [15:0] SDA,
	inout [7:0] SDD
);
	
	cha_board CHA(PBUS, CA4, S2H1, PCK1B, PCK2B, SDA, nSDROM, SDD, CR, FIXD, SDRD0);
	prog_board PROG(M68K_ADDR, M68K_DATA, nROMOE, nPORTOEL, nPORTOEU, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
						SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE);

endmodule

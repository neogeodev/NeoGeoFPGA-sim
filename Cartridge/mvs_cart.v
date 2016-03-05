`timescale 10ns/10ns

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
	output nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK,
	
	inout [7:0] RAD,
	input [9:8] RA_L,
	input [23:20] RA_U,
	input RMPX, nROE,
	
	inout [7:0] PAD,
	input [11:8] PA,
	input PMPX, nPOE
);

	cha_board CHA(PBUS, CA4, S2H1, PCK1B, PCK2B, SDA, nSDROM, SDD, CR, FIXD);
	prog_board PROG(M68K_ADDR, M68K_DATA, nROMOE, nPORTOEL, nPORTOEU, nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK,
						RAD, RA_L, RA_U, RMPX, nROE, PAD, PA, PMPX, nPOE);

endmodule

`timescale 10ns/10ns

module mvs_cart(
	input [19:0] PBUS,
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
	input nPORTOEU
);

	cha_board CHA(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD);
	prog_board PROG(M68K_ADDR, M68K_DATA, nROMOE, nPORTOEL, nPORTOEU);

endmodule

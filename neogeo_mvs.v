`timescale 10ns/10ns

module neogeo_mvs(
	input RESET_BTN,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	output [2:0] P1_OUT,
	output [2:0] P2_OUT,
	output [6:0] VIDEO_R,
	output [6:0] VIDEO_G,
	output [6:0] VIDEO_B,
	output VIDEO_SYNC
);

	wire [3:0] GAD, GBD;
	wire [11:0] PA;
	wire [23:0] PBUS;
	wire [7:0] FIXD;
	wire [31:0] CR;
	wire [15:0] PC;
	wire M68K_RW;
	wire nPAL, nPALWE;

	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	
	// NEO-D0 clock gen
	// VRAMs
	// LSPC

	mvs_cart CART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD, M68K_ADDR, M68K_DATA, nROMOE, nPORTOEL, nPORTOEU);

	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);

	neo_b1 B1(PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, PA);

	palram PRAMU({PALBNK, PA}, PC[15:8], nPALWE, 0, 0);
	palram PRAML({PALBNK, PA}, PC[7:0], nPALWE, 0, 0);
	
	assign nPALWE = M68K_RW & nPAL;
	
	// Palette data bidir buffer from/to 68k
	assign M68K_DATA = (M68K_RW | ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	assign PC = nPALWE ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;

endmodule

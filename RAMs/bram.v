`timescale 1ns/1ns

// 64K backup RAM (2x 120ns 32768*8bit RAM)

module bram(
	inout [15:0] M68K_DATA,
	input [14:0] M68K_ADDR,
	input nWEL,
	input nWEU,
	input nOEL,
	input nOEU,
	input nCE
);

	bram_l (M68K_ADDR, M68K_DATA[7:0], nWEL, nOEL, nCE);
	bram_u (M68K_ADDR, M68K_DATA[15:8], nWEU, nOEU, nCE);

endmodule

`timescale 1ns/1ns

// 64K 68000 work RAM (2x 120ns 32768*8bit RAM)

module ram_68k(
	inout [15:0] M68K_DATA,
	input [14:0] M68K_ADDR,
	input nWEL,
	input nWEU,
	input nOEL,
	input nOEU,
	input nCE
);

	ram68k_l RAM68KL(M68K_ADDR, M68K_DATA[7:0], nWEL, nOEL, nCE);
	ram68k_u RAM68KU(M68K_ADDR, M68K_DATA[15:8], nWEU, nOEU, nCE);

endmodule

`timescale 1ns/1ns

// 64K 68000 work RAM (2x 120ns 32768*8bit RAM)

module ram_68k(
	input [14:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nWEL,
	input nWEU,
	input nOEL,
	input nOEU
);

	ram68k_l RAM68KL(M68K_ADDR, M68K_DATA[7:0], nWEL, nOEL, 1'b0);
	ram68k_u RAM68KU(M68K_ADDR, M68K_DATA[15:8], nWEU, nOEU, 1'b0);

endmodule

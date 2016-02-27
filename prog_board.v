`timescale 10ns/10ns

module prog_board(
	input [18:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nROMOE,
	input nPORTOEL,
	input nPORTOEU
);

	wire nPORTOE;
	
	assign nPORTOE = nPORTOEL & nPORTOEU;
	
	rom_p1 P1(M68K_ADDR[16:0], M68K_ADDR, nROMOE);

endmodule

`timescale 10ns/10ns

module prog_board(
	input [18:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nROMOE,
	input nPORTOEL,
	input nPORTOEU,
	output nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK
);

	wire nPORTOE;
	
	assign nPORTOE = nPORTOEL & nPORTOEU;
	
	assign nROMWAIT = 1'b1;
	assign nPWAIT0 = 1'b1;
	assign nPWAIT1 = 1'b1;
	assign nPDTACK = 1'b0;
	
	rom_p1 P1(M68K_ADDR[16:0], M68K_DATA, nROMOE);
	
	//rom_p2 P2(M68K_ADDR[16:0], M68K_DATA, nPORTOE);

endmodule

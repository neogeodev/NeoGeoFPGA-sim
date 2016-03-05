`timescale 10ns/10ns

module prog_board(
	input [18:0] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nROMOE,
	input nPORTOEL,
	input nPORTOEU,
	output nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK,

	inout [7:0] RAD,
	input [9:8] RA_L,
	input [23:20] RA_U,
	input RMPX, nROE,
	
	inout [7:0] PAD,
	input [11:8] PA,
	input PMPX, nPOE
);

	wire nPORTOE;
	wire [18:0] V1_ADDR;
	wire [18:0] V2_ADDR;
	
	assign nPORTOE = nPORTOEL & nPORTOEU;
	
	assign nROMWAIT = 1'b1;
	assign nPWAIT0 = 1'b1;
	assign nPWAIT1 = 1'b1;
	assign nPDTACK = 1'b0;
	
	pcm PCM(RAD, RA_L, RA_U, RMPX, PAD, PA, PMPX, V1_ADDR, V2_ADDR);
	
	rom_p1 P1(M68K_ADDR[16:0], M68K_DATA, nROMOE);
	//rom_p2 P2(M68K_ADDR[16:0], M68K_DATA, nPORTOE);
	
	rom_v1 V1(V1_ADDR[18:0], RAD, nROE);
	rom_v2 V2(V2_ADDR[18:0], PAD, nPOE);

endmodule

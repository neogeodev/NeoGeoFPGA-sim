`timescale 1ns/1ns

module aes_prog(
	input nPORTADRS,
	input PMPX, nSDPOE,
	input [11:8] PA,
	inout [7:0] PAD,
	input nRESET,
	input CLK_68KCLKB,
	input nPORTWEL, nPORTWEU,
	input nPORTOEL, nPORTOEU,
	input nROMOEL, nROMOEU,
	input nAS, M68K_RW,
	inout [15:0] M68K_DATA,
	input [19:1] M68K_ADDR,
	input nROMOE,
	output nROMWAIT, nPWAIT1, nPWAIT0, PDTACK,
	inout [7:0] RAD,
	input [9:8] RA_L,
	input [23:20] RA_U,
	input RMPX, nSDROE,
	input CLK_4MB
);

	//wire nPORTOE;
	reg [23:0] V1_ADDR;
	reg [23:0] V2_ADDR;
	
	//assign nPORTOE = nPORTOEL & nPORTOEU;
	
	assign nROMWAIT = 1'b1;		// Waitstate configuration
	assign nPWAIT0 = 1'b1;
	assign nPWAIT1 = 1'b1;
	assign PDTACK = 1'b1;
	
	// Joy Joy Kid doesn't use PCM
	//pcm PCM(CLK_68KCLKB, nSDROE, RMPX, nSDPOE, PMPX, RAD, RA_L, RA_U, PAD, PA, V_DATA, V_ADDR);
	
	rom_p1 P1(M68K_ADDR[18:1], M68K_DATA, M68K_ADDR[19], nROMOE);
	
	// Joy Joy Kid doesn't have a P2
	//rom_p2 P2(M68K_ADDR[16:0], M68K_DATA, nPORTOE);
	
	rom_v1 V1(V1_ADDR[18:0], RAD, nROE);
	rom_v2 V2(V2_ADDR[18:0], PAD, nPOE);
	
	
	// V ROMs address latches (discrete)
	always @(posedge RMPX)
		V1_ADDR[9:0] <= {RA_L[9:8], RAD};

	always @(negedge RMPX)
		V1_ADDR[23:10] <= {RA_U[23:20], RA_L[9:8], RAD};

	always @(posedge PMPX)
		V2_ADDR[11:0] <= {PA[11:8], PAD};
		
	always @(negedge PMPX)
		V2_ADDR[23:12] <= {PA[11:8], PAD};
	
endmodule

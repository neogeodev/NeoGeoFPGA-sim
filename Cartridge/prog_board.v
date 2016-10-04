`timescale 1ns/1ns

module prog_board(
	input nSDROE, RMPX,
	input [23:20] RA_U,
	input [9:8] RA_L,
	
	input nSDPOE, PMPX,
	input [11:8] PA,
	
	input nSLOTCS,
	input nPORTADRS, nPORTWEL, nPORTWEU, nPORTOEL, nPORTOEU,
	input nROMOEL, nROMOEU,
	
	input nAS, M68K_RW,
	inout [15:0] M68K_DATA,
	input [19:1] M68K_ADDR,
	input CLK_68KCLKB,
	output nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	input nROMOE,
	
	input CLK_4MB, nRESET,

	inout [7:0] PAD,
	inout [7:0] RAD
);

	//wire nPORTOE;
	reg [23:0] V1_ADDR;
	reg [23:0] V2_ADDR;
	
	//assign nPORTOE = nPORTOEL & nPORTOEU;
	
	assign nROMWAIT = 1'b1;
	assign nPWAIT0 = 1'b1;
	assign nPWAIT1 = 1'b1;
	assign PDTACK = 1'b1;	// ?
	
	// Joy Joy Kid doesn't use PCM
	//pcm PCM(RAD, RA_L, RA_U, RMPX, PAD, PA, PMPX, V1_ADDR, V2_ADDR);
	
	rom_p1 P1(M68K_ADDR[16:0], M68K_DATA, M68K_ADDR[19], nROMOE);
	
	// Joy Joy Kid doesn't have a P2
	//rom_p2 P2(M68K_ADDR[16:0], M68K_DATA, nPORTOE);
	
	rom_v1 V1(V1_ADDR[18:0], RAD, nROE);
	rom_v2 V2(V2_ADDR[18:0], PAD, nPOE);
	
	// V ROMs address latches
	assign nRMPX = ~RMPX;
	assign nPMPX = ~PMPX;
	
	always @(posedge RMPX or posedge nRMPX)
	begin
		if (RMPX)
			V1_ADDR[9:0] <= {RA_L[9:8], RAD[7:0]};
		else
			V1_ADDR[23:10] <= {RA_U[23:20], RA_L[9:8], RAD[7:0]};
	end
	
	always @(posedge PMPX or posedge nPMPX)
	begin
		if (PMPX)
			V2_ADDR[11:0] <= {PA[11:8], PAD[7:0]};
		else
			V2_ADDR[23:12] <= {PA[11:8], PAD[7:0]};
	end
	
endmodule

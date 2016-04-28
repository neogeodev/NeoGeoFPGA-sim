`timescale 1ns/1ns

module testbench_1();
	reg MCLK;
	reg nRESET_BTN;
	
	wire [15:0] M68K_DATA;
	wire [22:0] M68K_ADDR;
	wire nWWL, nWWU, nWRL, nWRU;
	wire nSROMOE, nSYSTEM;
	
	wire [23:0] PBUS;
	
	wire [7:0] FIXD_SFIX;
	
	wire [2:0] P1_OUT;
	wire [2:0] P2_OUT;
	
	wire [23:0] CDA;
	wire [15:0] CDD;
	wire nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP;

	wire [3:0] EL_OUT;
	wire [8:0] LED_OUT1;
	wire [8:0] LED_OUT2;
	
	wire [6:0] VIDEO_R;
	wire [6:0] VIDEO_G;
	wire [6:0] VIDEO_B;
	
	wire [15:0] G;				// SFIX address

	neogeo_mvs NGMVS(
		MCLK,
		nRESET_BTN,
		
		M68K_DATA, M68K_ADDR, nWWL, nWWU, nWRL, nWRU,
		nSROMOE, nSYSTEM,
		
		PBUS,
		nVCS,
		S2H1,
		
		FIXD_SFIX,
		
		10'b1111111111,	// P1 in
		10'b1111111111,	// P2 in
		P1_OUT,
		P2_OUT,
		
		CDA,					// Memcard address
		CDD,					// Memcard data
		nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP,
		
		1'b1,					// TEST_BTN
		8'b11111111,		// DIPSW
		EL_OUT,				// Cab stuff
		LED_OUT1,
		LED_OUT2,
		
		VIDEO_R,
		VIDEO_G,
		VIDEO_B,
		VIDEO_SYNC
	);
	
	// Memory card
	memcard MC(CDA, CDD, nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP);
	
	// 68K RAM is external, not enough BRAM in XC6SLX16
	ram_68k M68KRAM(M68K_ADDR[14:0], M68K_DATA, nWWL, nWWU, nWRL, nWRU);
	// Embedded ROMs (flash)
	rom_sps2 SP(M68K_ADDR[15:0], {M68K_DATA[7:0], M68K_DATA[15:8]}, nSROMOE);
	rom_l0 L0(PBUS[15:0], PBUS[23:16], nVCS);
	rom_sfix SFIX({G[15:3], S2H1, G[2:0]}, FIXD_SFIX, nSYSTEM);
	// SFIX P bus latch (16-bit 273)
	latch_sfix LATCH_SFIX(PBUS[15:0], PCK2B, G);
	
	initial
	begin
		nRESET_BTN = 1;
		MCLK = 0;
	end
	
	always
		#21 MCLK = !MCLK;
		
	initial
	begin
		#500
		nRESET_BTN = 0;
		#500
		nRESET_BTN = 1;
	end
	
endmodule

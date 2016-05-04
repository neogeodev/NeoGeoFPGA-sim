`timescale 1ns/1ns
// `default_nettype none

module testbench_1();
	reg MCLK;
	reg nRESET_BTN;
	reg VCCON;
	reg [9:0] P1_IN;
	reg [9:0] P2_IN;
	reg nTEST_BTN;				// MVS only
	reg [7:0] DIPSW;
	
	wire COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2;		// MVS only
	
	wire [15:0] M68K_DATA;
	wire [19:1] M68K_ADDR;
	wire M68K_RW;
	wire nSRAMCS, nBWL, nBWU, nSWE;
	wire nSRAMWEN, nSRAMWEL, nSRAMWEU, nSRAMOEL, nSRAMOEU;
	
	wire nWWL, nWWU, nWRL, nWRU;
	wire nSLOTCS, nROMOE, nSROMOE, nSYSTEM, nROMWAIT;
	wire nPORTOEL, nPORTOEU, nPWAIT0, nPWAIT1, PDTACK;
	
	wire [23:0] PBUS;
	wire nVCS, S2H1, CA4, PCK1B, PCK2B;
	
	wire [7:0] FIXD;
	wire [7:0] FIXD_SFIX;
	wire [7:0] FIXD_CART;

	wire [2:0] P1_OUT, P2_OUT;
	
	wire [4:0] CDA_U;
	wire [15:0] CDD;			// Memcard data (is this a register ?)
	wire nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP;

	wire [3:0] EL_OUT;
	wire [8:0] LED_OUT1;
	wire [8:0] LED_OUT2;
	
	wire [15:0] G;				// SFIX address

	wire SDRMPX, SDPMPX, nSDROE, nSDPOE;
	wire [7:0] SDRAD;
	wire [9:8] SDRA_L;
	wire [23:20] SDRA_U;
	wire [7:0] SDPAD;
	wire [11:8] SDPA;

	wire [15:0] SDA;			// Z80
	wire [7:0] SDD;
	wire nSDROM;
	
	wire CLK_12M, EVEN, H, LOAD;
	wire [3:0] GAD, GBD;
	wire [31:0] CR;
	
	wire nBITWD0, nDIPRD0;
	wire nCTRL1_ZONE, nCTRL2_ZONE, nSTATUSB_ZONE, nLED_LATCH, nLED_DATA;
	wire VIDEO_R_SER, VIDEO_G_SER, VIDEO_B_SER, VIDEO_CLK_SER, VIDEO_LAT_SER;
	wire I2S_MCLK, I2S_BICK, I2S_SDTI, I2S_LRCK;

	neogeo NG(
		MCLK,															// 2
		nRESET_BTN,
		VCCON,
		
		M68K_DATA, M68K_ADDR[19:1],							// 16 + 20
		M68K_RW,														// 1
		nWWL, nWWU, nWRL, nWRU,									// 4
		nSRAMWEN, nSRAMWEL, nSRAMWEU,							// 5
		nSRAMOEL, nSRAMOEU, 
		nSROMOE, nSYSTEM,											// 2
		nBITWD0, nDIPRD0,											// 2
		nLED_LATCH, nLED_DATA,									// 2

		nROMOE, nPORTOEL, nPORTOEU, nSLOTCS,				// 4
		nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,					// 4
		SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,				// 7 + 2 + 4 + 2
		SDPAD, SDPA, SDPMPX, nSDPOE,							// 7 + 4 + 2
		nSDROM,														// 1
		SDA, SDD,													// 16 + 8
		
		PBUS,															// 24
		nVCS,															// 1
		S2H1, CA4,													// 2
		PCK1B, PCK2B,												// 2
		
		CLK_12M, EVEN, LOAD, H, GAD, GBD, 					// 12		get CLK_12M from MCLK ?
		FIXD,															// 8
		
		CDA_U,														// 5
		nCRDC, nCRDO,												// 2
		CARD_PIN_nWE, CARD_PIN_nREG,							// 2
		nCD1, nCD2, nWP,											// 3
		
		nCTRL1_ZONE, nCTRL2_ZONE, nSTATUSB_ZONE,			// 3
		COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2,			// 4

		VIDEO_R_SER,												// 5
		VIDEO_G_SER,
		VIDEO_B_SER,
		VIDEO_CLK_SER,
		VIDEO_LAT_SER,

		I2S_MCLK,													// 4
		I2S_BICK,
		I2S_SDTI,
		I2S_LRCK
	);																	// Total: 189 :)
	
	// MVS cartridge
	mvs_cart MVSCART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, M68K_ADDR[19:1], M68K_DATA, nROMOE,
					nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK, SDRAD, SDRA_L, SDRA_U, SDRMPX,
					nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE, nSDROM, SDA, SDD);
	
	// AES cartridge
	/*aes_cart AESCART(PBUS, CA4, S2H1, PCK1B, PCK2B, GAD, GBD, EVEN, H, LOAD, FIXD_CART, M68K_ADDR[19:1], M68K_DATA,
					nROMOE, nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK, SDRAD, SDRA_L, SDRA_U,
					SDRMPX, nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE, nSDROM, SDA, SDD);*/

	// Do not use DOTA and DOTB, done in NG from GAD and GBD
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, , );
	
	// Memory card
	memcard MC({CDA_U, M68K_ADDR[19:1]}, CDD, nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP);
	assign M68K_DATA = (M68K_RW & ~nCRDC) ? CDD : 16'bzzzzzzzzzzzzzzzz;
	assign CDD = (~M68K_RW | nCRDC) ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;
	
	// 68K RAM is external, not enough BRAM in XC6SLX16
	ram_68k M68KRAM(M68K_ADDR[15:1], M68K_DATA, nWWL, nWWU, nWRL, nWRU);
	// Embedded ROMs (flash)
	rom_sps2 SP(M68K_ADDR[16:1], {M68K_DATA[7:0], M68K_DATA[15:8]}, nSROMOE);
	rom_l0 L0(PBUS[15:0], PBUS[23:16], nVCS);
	rom_sfix SFIX({G[15:3], S2H1, G[2:0]}, FIXD_SFIX, nSYSTEM);
	
	// SFIX P bus latch (16-bit 273)
	latch_sfix LATCH_SFIX(PBUS[15:0], PCK2B, G);
	// SFIX / Cart FIX switch
	assign FIXD = nSYSTEM ? FIXD_SFIX : FIXD_CART;
	
	// nSRAMCS comes from analog battery backup circuit
	assign nSRAMCS = 1'b0;
	sram SRAM(M68K_DATA, M68K_ADDR[15:1], nBWL, nBWU, nSRAMOEL, nSRAMOEU, nSRAMCS);
	assign nSWE = nSRAMWEN | nSRAMCS;
	assign nBWL = nSRAMWEL | nSWE;
	assign nBWU = nSRAMWEU | nSWE;
	
	// MVS cab I/O
	cab_io CABIO(nBITWD0, nDIPRD0, nLED_LATCH, nLED_DATA, DIPSW, M68K_ADDR[7:4], M68K_DATA[7:0],
						EL_OUT, LED_OUT1, LED_OUT2);
	
	parameter SYSTEM_MODE = 1'b1;		// MVS
	
	// Joypad I/O
	joy_io JOYIO(nCTRL1_ZONE, nCTRL2_ZONE, nSTATUSB_ZONE, M68K_DATA, M68K_ADDR[4],
						P1_IN, P2_IN, nBITWD0, nWP, nCD2, nCD1, SYSTEM_MODE, P1_OUT, P2_OUT);
	
	initial
	begin
		MCLK = 0;
		nRESET_BTN = 1;
		nTEST_BTN = 1;					// MVS only
		DIPSW = 8'b11111111;
		P1_IN = 10'b1111111111;
		P2_IN = 10'b1111111111;
		VCCON = 0;
	end
	
	always
		#21 MCLK = !MCLK;
		
	initial
	begin
		#30
		VCCON = 1;
		#70
		nRESET_BTN = 0;
		#1000
		nRESET_BTN = 1;
	end
	
endmodule

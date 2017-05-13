`timescale 1ns/1ns
// `default_nettype none

// SIMULATION ONLY
// TB = Test Board

// TODO TB: delegate some stuff to CPLD (clock divider for cartridge and SROM, SRAM and WRAM control...)

module testbench_1();
	reg MCLK;
	reg nRESET_BTN;			// Present on AES only
	reg [9:0] P1_IN;			// Joypad
	reg [9:0] P2_IN;
	reg nTEST_BTN;				// Present on MVS only
	reg [7:0] DIPSW;			// Present on MVS only
	
	wire [15:0] M68K_DATA;
	wire [23:1] M68K_ADDR;
	
	wire [2:0] LED_LATCH;	// Present on MVS only
	wire [7:0] LED_DATA;		// Present on MVS only
	
	wire [23:0] PBUS;
	
	wire [7:0] FIXD;
	wire [7:0] FIXD_SFIX;	// Present on MVS only
	wire [7:0] FIXD_CART;

	wire [2:0] P1_OUT;		// Joypad
	wire [2:0] P2_OUT;
	
	wire [4:0] CDA_U;			// Memcard
	wire [15:0] CDD;			// TODO: is this a register ?

	wire [3:0] EL_OUT;		// Present on MVS only
	wire [8:0] LED_OUT1;		// Present on MVS only
	wire [8:0] LED_OUT2;		// Present on MVS only

	wire [7:0] SDRAD;			// ADPCM
	wire [9:8] SDRA_L;
	wire [23:20] SDRA_U;
	wire [7:0] SDPAD;
	wire [11:8] SDPA;

	wire [15:0] SDA;			// Z80
	wire [7:0] SDD;
	
	wire [31:0] CR;			// Present on MVS only
	wire [3:0] GAD, GBD;
	
	wire [6:0] VIDEO_R;		// TB specific
	wire [6:0] VIDEO_G;
	wire [6:0] VIDEO_B;

	neogeo NG(
		MCLK,															// 2
		nRESET_BTN,
		
		P1_IN, P2_IN,
		
		DIPSW,
		
		M68K_DATA, M68K_ADDR,
		M68K_RW,	nAS, nLDS, nUDS,								// 4
		LED_LATCH, LED_DATA,										// 2
		
		CLK_68KCLKB,
		CLK_8M,
		CLK_4MB,

		nROMOE, nSLOTCS,											// 2
		nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,					// 4
		nPORTOEL, nPORTOEU, nPORTWEL, nPORTWEU,
		
		SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,				// 7 + 2 + 4 + 2
		SDPAD, SDPA, SDPMPX, nSDPOE,							// 7 + 4 + 2
		nSDROM, nSDMRD,											// 1
		SDA, SDD,													// 16 + 8
		
		PBUS,															// 24
		nVCS,															// 1
		S2H1, CA4,													// 2
		PCK1B, PCK2B,												// 2
		
		CLK_12M, EVEN, LOAD, H,									// 4		Get CLK_12M from MCLK ? -1
		GAD, GBD, 													// 8
		FIXD,															// 8
		
		CDA_U,														// 5
		nCRDC, nCRDO,												// 2
		CARD_PIN_nWE, CARD_PIN_nREG,							// 2
		nCD1, nCD2, nWP,											// 3		nCD1 | nCD2 in CPLD ? -1

		VIDEO_R,
		VIDEO_G,
		VIDEO_B,
		VIDEO_SYNC
	);
	
	// MVS cartridge
	mvs_cart MVSCART(nRESET, CLK_24M, CLK_12M, CLK_8M, CLK_68KCLKB, CLK_4MB, nAS, M68K_RW, M68K_ADDR[19:1], M68K_DATA,
					nROMOE, nROMOEL, nROMOEU, nPORTADRS, nPORTOEL, nPORTOEU,	nPORTWEL, nPORTWEU, nROMWAIT, nPWAIT0, nPWAIT1,
					PDTACK, nSLOTCS, PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,
					SDPAD, SDPA, SDPMPX, nSDPOE, SDRD0, SDRD1, nSDROM, nSDMRD, SDA, SDD);
	
	// AES cartridge
	/*aes_cart AESCART(PBUS, CA4, S2H1, PCK1B, PCK2B, GAD, GBD, EVEN, H, LOAD, FIXD_CART, M68K_ADDR[19:1], M68K_DATA,
					nROMOE, nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK, SDRAD, SDRA_L, SDRA_U,
					SDRMPX, nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE, nSDROM, SDA, SDD);*/

	// Memory card
	memcard MC({CDA_U, M68K_ADDR[19:1]}, CDD, nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP);
	assign M68K_DATA = (M68K_RW & ~nCRDC) ? CDD : 16'bzzzzzzzzzzzzzzzz;
	assign CDD = (~M68K_RW | nCRDC) ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;
	
	// TODO TB: Put the following in the CPLD
	// DOTA and DOTB are not used, done in NG from GAD and GBD (saves 2 lines)
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, , );
	
	
	initial
	begin
		MCLK = 0;
		nRESET_BTN = 1;
		P1_IN = 10'b1111111111;		// Idle joypads
		P2_IN = 10'b1111111111;
		
		nTEST_BTN = 1;
		DIPSW = 8'b11111111;
		
		// Apply reset
		#30
		nRESET_BTN = 0;		// Press reset button during 1us
		#1000
		nRESET_BTN = 1;
	end
	
	always
		#21 MCLK = !MCLK;		// 24MHz -> 20.8ns half period
	
	always @(posedge MCLK)
	begin
		// These addresses are only valid for the patched SP-S2.SP1 system ROM !
		if ({M68K_ADDR, 1'b0} == 24'hC16ADA)
		begin
			$display("SELF-TEST ERROR: See M68K reg D6:");
			$display("0 WORK RAM ERROR !");
			$display("1 BACKUP RAM ERROR !");
			$display("2 COLOR RAM BANK0 ERROR !");
			$display("3 COLOR RAM BANK1 ERROR !");
			$display("4 VIDEO RAM ERROR !");
			$display("5 CALENDAR ERROR ! (A)");
			$display("6 SYSTEM ROM ERROR !");
			$display("7 MEMORY CARD ERROR !");
			$display("8 Z80 ERROR !");
			$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'hC11D46)
		begin
			$display("SYSTEM ROM ERROR !");
			$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'hC11D8C)
		begin
			$display("CALENDAR ERROR ! (B)");
			$stop;
		end
		
		
		if ({M68K_ADDR, 1'b0} == 24'hC17E26)
		begin
			$display("VICTOLY ! Going to eyecatcher.");
			$stop;
		end
		
		if ({M68K_ADDR, 1'b0} == 24'h000122)
		begin
			$display("VICTOLY ! Jump to game entry point.");
			$stop;
		end
	end
	
endmodule

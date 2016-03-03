`timescale 10ns/10ns

// SNK NeoGeo FPGA hardware definitions (for simulation only)
// furrtek, Charles MacDonald, Kyuusaku and neogeodev contributors ~ 2016
// https://github.com/neogeodev/NeoGeoFPGA-sim

module neogeo_mvs(
	input nRESET_BTN,
	input TEST_BTN,				// Todo
	input CLK_24M,
	input [7:0] DIPSW,
	
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	output [2:0] P1_OUT,
	output [2:0] P2_OUT,
	
	output [23:0] CDA,			// Memcard address
	output [15:0] CDD,			// Memcard data
	
	output [3:0] EL_OUT,			// Clock, 3x data
	output [8:0] LED_OUT1,		// Clock, 8x data
	output [8:0] LED_OUT2,		// Clock, 8x data
	
	output [6:0] VIDEO_R,
	output [6:0] VIDEO_G,
	output [6:0] VIDEO_B,
	output VIDEO_SYNC,
	
	output [22:0] TB_M68K_ADDR
);

	// TODO: Check watchdog timing
	// TODO: VPA (NEO-C1)
	// TODO: ERROR ! BITWD0 should ignore M68K_ADDR[5] (see writes to NEO-F0)
	// TODO: MEMCARD zone has a fixed 2 (6 clks) waitstates (NEO-C1)

	// REG_P1CNT		Read ok, check range
	//	REG_DIPSW		Read ok, Write ok, check range
	// REG_TYPE			Read mapped, check range
	// REG_SOUND		Read ok, write todo, check range
	// REG_STATUS_A	Read mapped, check range
	// REG_P2CNT		Read ok, check range
	// REG_STATUS_B	Read ok, check range
	// REG_POUTPUT		Write ok, check range
	// REG_CRDBANK		Write ok, check range
	// REG_SLOT			Write ok, check range
	// REG_LEDLATCHES	Write ok, check range
	// REG_LEDDATA		Write ok, check range
	// REG_RTCCTRL		Write ok, check range
	
	// Counter/lockout	Ok, check range, neo_i0.v
	
	wire A22Z;
	wire A23Z;
	wire [22:0] M68K_ADDR;	// Really A23~A1
	wire [15:0] M68K_DATA;
	wire M68K_RW;
	wire nDTACK;
	wire nRESET;
	
	assign TB_M68K_ADDR = M68K_ADDR;
	
	wire [7:0] SDD;			// Z80 data bus
	
	wire nPAL, nPALWE;
	wire nSROMOEU, nSROMOEL;
	
	wire nROMOE;
	
	wire [15:0] G;				// SFIX address
	wire [7:0] FIXD;
	wire [7:0] FIXD_CART;
	wire [7:0] FIXD_EMBED;
	wire [11:0] PA;			// Palette RAM address
	wire [3:0] GAD, GBD;		// Pixel pair
	wire [23:0] PBUS;
	wire [31:0] CR;			// Raw sprite data
	wire [15:0] PC;			// Palette RAM data
	wire [3:0] WE;				// LSPC/B1
	wire [3:0] CK;				// LSPC/B1
	
	wire S2H1;
	wire SYSTEMB;
	wire nSYSTEM;
	
	wire nRESETP;
	wire nVEC, SHADOW;
	wire nBNKB;
	
	
	// NEO-C1:nBITW0(38xxxx-39xxxx) -> NEO-F0:nBITWD0(A7~6=0) -> NEO-D0
	assign nBITWD0 = nBITW0 & (M68K_ADDR[6] | M68K_ADDR[5]);
	
	//                     7654 3210
	// NEO-D0 (nBITWD0)
	// 0000 0000 0000 0000 000x 0000
	
	// NEO-F0
	// 0000 0000 0000 0000 0101 xxxx
	// 0000 0000 0000 0000 0100 xxxx
	// 0000 0000 0000 0000 0011 xxxx
	// 0000 0000 0000 0000 0010 xxxx
	// 0000 0000 0000 0000 0001 xxxx
	// 0000 0000 0000 0000 1101 xxxx ?
	
	wire [5:0] SLOT;
	
	// Implementation specific (unique slot)
	assign nSLOTCS = SLOT[0];
	
	// For NEO-I0:
	assign nCOUNTOUT = &{nBITW0, ~M68K_ADDR[5], M68K_ADDR[4:3]};	// nBITW0 or nBITWD0 ?
	// NEO-F0: A6~4 (5~3)
	// xx10 0xxx
	
	wire [31:0] AO68KDATA_OUT;
	wire [31:0] AO68KDATA_IN;
	
	wire [31:2] AO68KADDR;
	
	assign AO68KDATA_IN = 32'b0; //{16'b0, M68K_RW ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz};
	assign M68K_DATA = (~M68K_RW) ? AO68KDATA_OUT[15:0] : 16'bzzzzzzzzzzzzzzzz;
	
	wire CLK_68KCLK;
	
	assign nRESET = nRESET_BTN;
	assign nRESETP = nRESET;	// DEBUG TODO
	
	// 1000: 01 UDS
	// 0100: 01 LDS
	// 0010: 00 UDS
	// 0001: 00 LDS
	// 1100: 01 UDS+LDS
	// 0011: 00 UDS+LDS
	// 1111: 00 ???
	
	wire [3:0] AO68KSIZE;
	
	assign M68K_ADDR = {AO68KADDR[23:2], ~&{AO68KSIZE[1:0]}};
	
	assign nAS = ~AO68KAS;
	assign M68K_RW = ~AO68KWE;
	
	assign nUDS = ~(AO68KSIZE[3] | AO68KSIZE[1]);
	assign nLDS = ~(AO68KSIZE[2] | AO68KSIZE[0]);
	
	ao68000 AO68K(
		.CLK_I(CLK_68KCLK),
		.reset_n(nRESET),

		.CYC_O(),						// ?
		.ADR_O(AO68KADDR),
		.DAT_O(AO68KDATA_OUT),
		.DAT_I(AO68KDATA_IN),
		.SEL_O(AO68KSIZE),			// B1 B2 B3 D4 (0x00000000)
		.STB_O(AO68KAS),
		.WE_O(AO68KWE),

		.ACK_I(1'b1),					// DTACK ?
		.ERR_I(1'b0),					// See a068000 doc
		.RTY_I(1'b0),

		// TAG_TYPE: TGC_O
		.SGL_O(),
		.BLK_O(),
		.RMW_O(),

		// TAG_TYPE: TGA_O
		.CTI_O(),
		.BTE_O(),

		// TAG_TYPE: TGC_O
		.fc_o(),

		//****************** OTHER
		/* interrupt acknowlege:
		* ACK_I: interrupt vector on DAT_I[7:0]
		* ERR_I: spurious interrupt
		* RTY_I: autovector
		*/
		.ipl_i({1'b0, IPL1, IPL0}),
		.reset_o(),
		.blocked_o()
	);
	
	clocks CLK(CLK_24M, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_8M, CLK_6MB, CLK_4M, CLK_4MB, CLK_1MB);

	mvs_cart CART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, M68K_ADDR[18:0], M68K_DATA, nROMOE,
					nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK);

	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);
	
	neo_c1 C1(M68K_ADDR[20:16], M68K_DATA[15:8], A22Z, A23Z, nLDS, nUDS, M68K_RW, nAS, nROMOEL, nROMOEU, nPORTOEL, nPORTOEU,
				nPORTWEL, nPORTWEU, nPORTADRS, nWRL, nWRU, nWWL, nWWU, nSROMOEL, nSROMOEU, nSRAMOEL, nSRAMOEU, nSRAMWEL,
				nSRAMWEU, nLSPOE, nLSPWE, nCRDO, nCRDW, nCRDC, nSDW, P1_IN, P2_IN, nCD1, nCD2, nWP, ROMWAIT, PWAIT0,
				PWAIT1, PDTACK, SDD, CLK_68KCLK, nDTACK, nBITW0, nBITW1, nDIPRD0, nDIPRD1, nPAL);
				
	neo_d0 D0(M68K_ADDR[21:0], nBITWD0, M68K_DATA[5:0], CDA, P1_OUT, P2_OUT);
	
	neo_f0 F0(nDIPRD0, nDIPRD1, nBITWD0, DIPSW, M68K_ADDR[6:3], M68K_DATA[7:0], SYSTEMB, SLOT, SLOTA, SLOTB, SLOTC,
				EL_OUT, LED_OUT1, LED_OUT2);	

	lspc_a2 LSPC(CLK_24M, nRESET, PBUS, M68K_ADDR[2:0], M68K_DATA, nLSPOE, nLSPWE, DOTA, DOTB, CA4, S2H1,
				S1H1, LOAD, H, EVEN1, EVEN2, IPL0, IPL1, CHG, LD1, LD1, PCK1, PCK2, WE[3:0], CK[3:0], SS1,
				SS2, nRESETP, VIDEO_SYNC, CHBL, nBNKB, nVCS, CLK_6M);
				
	neo_b1 B1(PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, A23Z, A22Z, PA, nLDS, M68K_RW,
				M68K_ADDR[20:16], M68K_ADDR[11:0], nHALT, nRESET, VCCON);
	
	neo_i0 I0(nRESET, nCOUNTOUT, M68K_ADDR[2:0], M68K_ADDR[7], COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2);
	
	syslatch SL(M68K_ADDR[3:0], nBITW1, nRESET,
				SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, nSRAMLOCK, nPALBANK);
	
	rom_l0 L0(PBUS[15:0], PBUS[23:16], nVCS);
	rom_sps2 SP(M68K_ADDR[15:0], M68K_DATA, nSROMOE);
	rom_sfix SFIX({G[15:3], S2H1, G[2:0]}, FIXD_EMBED, nSYSTEM);
	
	memcard MC(CDA, CDD, nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP);

	palram PRAML({PALBNK, PA}, PC[7:0], nPALWE, 1'b0, 1'b0);
	palram PRAMU({PALBNK, PA}, PC[15:8], nPALWE, 1'b0, 1'b0);
	
	videout VOUT(CLK_6MB, nBNKB, SHADOW, PC[15:0], VIDEO_R, VIDEO_G, VIDEO_B);
	
	// Gates
	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	assign nSROMOE = nSROMOEU & nSROMOEL;
	assign nPALWE = M68K_RW | nPAL;
	assign SYSTEMB = ~nSYSTEM;
	assign nROMOE = nROMOEU & nROMOEL;
	
	// Memcard stuff
	assign CARD_PIN_nWE = |{nCARDWEN, ~CARDWENB, nCRDW};
	assign CARD_PIN_nREG = nREGEN | nCRDO;
	// In NEO-G0 (AES only)
	assign M68K_DATA = (M68K_RW & ~nCRDC) ? CDD : 16'bzzzzzzzzzzzzzzzz;
	assign CDD = (M68K_RW | nCRDC) ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;
	
	// Good job SNK ! Gates cart FIXD to avoid bus wreck with SFIX
	assign FIXD = nSYSTEM ? FIXD_EMBED : FIXD_CART;
	
	// This is done by NEO-E0:
	// A = 1 if nVEC == 0 and A == 11000000000000000xxxxxxx
	assign {A23Z, A22Z} = M68K_ADDR[22:21] ^ {2{~|{M68K_ADDR[20:6], ^M68K_ADDR[22:21], nVEC}}};
	
	// Palette data bidir buffer from/to 68k
	assign M68K_DATA = (M68K_RW & ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	assign PC = nPALWE ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;

endmodule

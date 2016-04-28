`timescale 1ns/1ns

// SNK NeoGeo FPGA hardware definitions (for simulation only)
// furrtek, Charles MacDonald, Kyuusaku, freem and neogeodev contributors ~ 2016
// https://github.com/neogeodev/NeoGeoFPGA-sim

module neogeo(
	input CLK_24M,
	input nRESET_BTN,				// On AES only
	
	inout [15:0] M68K_DATA,		// 68K
	output [23:1] M68K_ADDR,
	output M68K_RW,
	output nWWL, nWWU, nWRL, nWRU,
	output nSROMOE, nSYSTEM,
	output nBITWD0, nDIPRD0,
	
	output nROMOE, nPORTOEL, nPORTOEU, nSLOTCS,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	
	input [7:0] SDRAD,			// ADPCM
	output [9:8]SDRA_L,
	output [23:20] SDRA_U,
	output SDRMPX, nSDROE,
	input [7:0] SDPAD,
	output [11:8] SDPA,
	output SDPMPX, nSDPOE,
	
	output nSDROM,					// Z80
	output [15:0] SDA,
	inout [7:0] SDD,
	
	inout [23:0] PBUS,			// Gfx
	output nVCS,
	output S2H1, CA4,
	output PCK1B, PCK2B,
	
	input [31:0] CR,				// Raw sprite data, todo: replace with muxed bus from ZMC2 !
	input [7:0] FIXD,
	
	output [23:0] CDA,			// Memcard address
	output nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG,
	output nCD1, nCD2, nWP,
	
	output nCTRL1ZONE, nCTRL2ZONE, nSTATUSBZONE,
	
	output [6:0] VIDEO_R,
	output [6:0] VIDEO_G,
	output [6:0] VIDEO_B,
	output VIDEO_SYNC,
	
	// I2S interface
	output I2S_MCLK, I2S_BICK, I2S_SDTI, I2S_LRCK
);

	// Dev notes:
	// ao68000 loads SSP and PC properly, reads word opcode 4EF9 for JMP at C00402
	// but reads 2x longword after, decoder_micropc is good for JMP but isn't used...

	// Todo: Z80 controller (NEO-D0)
	// Todo: VPA for interrupt ACK (NEO-C1)
	// Todo: Check watchdog timing
	
	wire A22Z, A23Z;
	wire nDTACK;
	wire nRESET, nRESETP;
	wire CLK_68KCLK;
	
	wire CLK_1MB;
	wire CLK_6MB;
	
	wire nPAL, nPALWE;
	wire nSROMOEU, nSROMOEL;
	
	wire [11:0] PA;			// Palette RAM address
	wire [3:0] GAD, GBD;		// Pixel pair
	wire [15:0] PC;			// Palette RAM data
	
	wire [3:0] WE;				// LSPC/B1
	wire [3:0] CK;				// LSPC/B1
	
	wire SYSTEMB;
	
	wire nVEC, SHADOW;
	wire nBNKB;
	
	wire [2:0] BNK;
	
	wire [5:0] nSLOT;
	
	wire [3:0] ANA;		// PSG audio level
	
	// Implementation specific (unique slot)
	assign nSLOTCS = nSLOT[0];
	
	// Are these good ?
	assign nBITWD0 = |{nBITW0, M68K_ADDR[6:5]};
	assign nCOUNTOUT = |{nBITW0, ~M68K_ADDR[6:5]};
	
	// Todo: VCCON ?
	assign nRESET = nRESET_BTN;	// DEBUG TODO
	assign nRESETP = nRESET;		// DEBUG TODO
	
	wire [8:0] HCOUNT;				// Todo: remove
	
	// Renaming :)
	wire CHG;
	wire TMS0;
	assign TMS0 = CHG;
	
	cpu_68k M68KCPU(CLK_68KCLK, nRESET, IPL1, IPL0, M68K_ADDR, M68K_DATA, nLDS, nUDS, nAS, M68K_RW);
	cpu_z80 Z80CPU(CLK_4M, nRESET, SDD, SDA, nIORQ, nMREQ, nRD, nWR, nINT, nNMI);
	
	neo_c1 C1(M68K_ADDR[21:17], M68K_DATA[15:8], A22Z, A23Z, nLDS, nUDS, M68K_RW, nAS, nROMOEL, nROMOEU, nPORTOEL, nPORTOEU,
				nPORTWEL, nPORTWEU, nPORTADRS, nWRL, nWRU, nWWL, nWWU, nSROMOEL, nSROMOEU, nSRAMOEL, nSRAMOEU, nSRAMWEL,
				nSRAMWEU, nLSPOE, nLSPWE, nCRDO, nCRDW, nCRDC, nSDW, nCD1, nCD2, nWP, ROMWAIT, PWAIT0,
				PWAIT1, PDTACK, SDD, CLK_68KCLK, nDTACK, nBITW0, nBITW1, nDIPRD0, nDIPRD1, nPAL,
				nCTRL1ZONE, nCTRL2ZONE, nSTATUSBZONE);
	
	// Todo: nSDZ80R, nSDZ80W, nSDZ80CLR comes from C1
	neo_d0 D0(CLK_24M, nRESET, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_6MB, CLK_1MB,
				M68K_ADDR[4], nBITWD0, M68K_DATA[5:0],
				SDA[15:11], SDA[4:2], nSDRD, nSDWR, nMREQ, nIORQ, nZ80NMI, nSDZ80R, nSDZ80W, nSDZ80CLR,
				nSDROM, nSDMRD, nSDMWR, SDRD0, SDRD1, n2610CS, n2610RD, n2610WR, nZRAMCS, BNK);
	
	neo_e0 E0(M68K_ADDR[23:1], BNK[2:0], nSROMOEU, nSROMOEL, nSROMOE,
				nVEC, A23Z, A22Z, CDA[23:0]);
	
	neo_f0 F0(nDIPRD1, nBITWD0, M68K_ADDR[7:4], M68K_DATA[7:0], SYSTEMB, nSLOT, SLOTA, SLOTB, SLOTC);
	
	neo_i0 I0(nRESET, nCOUNTOUT, M68K_ADDR[3:1], M68K_ADDR[7], COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2);
	
	syslatch SL(M68K_ADDR[4:1], nBITW1, nRESET,
				SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, SRAMWEN, PALBNK);
	
	// Video
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);
	
	// Todo: REMOVE HCOUNT, it's only used for simulation in videout
	lspc_a2 LSPC(CLK_24M, nRESET, PBUS, M68K_ADDR[3:1], M68K_DATA, nLSPOE, nLSPWE, DOTA, DOTB, CA4, S2H1,
				S1H1, LOAD, H, EVEN1, EVEN2, IPL0, IPL1, CHG, LD1, LD1, PCK1, PCK2, WE[3:0], CK[3:0], SS1,
				SS2, nRESETP, VIDEO_SYNC, CHBL, nBNKB, nVCS, CLK_8M, CLK_4M, HCOUNT);
	
	neo_b1 B1(CLK_6MB, CLK_1MB, PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, S1H1,
				A23Z, A22Z, PA, nLDS, M68K_RW, M68K_ADDR[21:17], M68K_ADDR[12:1], nHALT, nRESET, VCCON, HCOUNT);
	
	z80ram ZRAM(SDA[10:0], SDD, nZRAMCS, nSDMRD, nSDMWR);
	palram PALRAM({PALBNK, PA}, PC, nPALWE);
	
	// Todo: Put in testbench
	sram SRAM(M68K_DATA, M68K_ADDR[15:1], nBWL, nBWU, nSRAMOEL, nSRAMOEU, nSRAMCS);
	
	ym2610 YM(CLK_8M, SDD, SDA[1:0], nZ80INT, n2610CS, n2610WR, n2610RD, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,
					SDPAD, SDPA, SDPMPX, nSDPOE, ANA, SH1, SH2, OP0, PHI_M);
	
	ym2i2s YM2I2S(nRESET, CLK_I2S, ANA, SH1, SH2, OP0, PHI_M, I2S_MCLK, I2S_BICK, I2S_SDTI, I2S_LRCK);
	
	// MVS only
	upd4990 RTC(CLK_RTC, RTC_CS, RTC_OE, RTC_CLK, RTC_DATA_IN, TP, RTC_DATA_OUT);

	// Todo: REMOVE HCOUNT, it's only used for simulation file output here:
	videout VOUT(CLK_6MB, nBNKB, SHADOW, PC, VIDEO_R, VIDEO_G, VIDEO_B, HCOUNT);
	
	// Gates
	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	assign nPALWE = M68K_RW | nPAL;
	assign SYSTEMB = ~nSYSTEM;
	assign nROMOE = nROMOEU & nROMOEL;
	
	// nSRAMCS comes from inverter transistor in analog circuit (MVS schematics page 1)
	assign nSRAMCS = 0;	// Todo: For debug only
	assign nSRAMWE = SRAMWEN | nSRAMCS;
	assign nBWU = nSRAMWEU | nSRAMWE;
	assign nBWL = nSRAMWEL | nSRAMWE;
	
	// Memcard stuff
	assign CARD_PIN_nWE = |{nCARDWEN, ~CARDWENB, nCRDW};
	assign CARD_PIN_nREG = nREGEN | nCRDO;
	
	// Todo:
	// Palette data bidir buffer from/to 68k
	//assign M68K_DATA = (M68K_RW & ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	//assign PC = nPALWE ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;

endmodule

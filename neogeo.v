`timescale 1ns/1ns
// `default_nettype none

// SNK NeoGeo FPGA hardware definitions (for simulation only)
// furrtek, Charles MacDonald, Kyuusaku, freem and neogeodev contributors ~ 2016
// https://github.com/neogeodev/NeoGeoFPGA-sim

// Todo: Z80 controller (NEO-D0)
// Todo: VPA for interrupt ACK (NEO-C1)
// Todo: Check watchdog timing

module neogeo(
	input CLK_24M,
	input nRESET_BTN,		// VCCON on MVS
	
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	
	// 68K CPU
	inout [15:0] M68K_DATA,
	output [19:1] M68K_ADDR_OUT,
	output M68K_RW, nAS, nLDS, nUDS,
	output nLED_LATCH, nLED_DATA,
	
	// Cartridge 68K ROMs
	output nROMOE, nSLOTCS,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	
	// Cartridge PCM ROMs
	input [7:0] SDRAD,			// ADPCM
	output [9:8] SDRA_L,
	output [23:20] SDRA_U,
	output SDRMPX, nSDROE,
	input [7:0] SDPAD,
	output [11:8] SDPA,
	output SDPMPX, nSDPOE,
	
	// Cartridge Z80 ROMs
	output nSDROM,					// Z80
	output [15:0] SDA,
	inout [7:0] SDD,
	
	// Cartridge/onboard gfx ROMs
	inout [23:0] PBUS,			// Gfx
	output nVCS,
	output S2H1, CA4,
	output PCK1B, PCK2B,
	
	// Gfx
	output CLK_12M, EVEN, LOAD, H,
	input [3:0] GAD, GBD,
	input [7:0] FIXD,
	
	// Memcard
	output [4:0] CDA_U,			// Memcard upper address lines
	output nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG,
	input nCD1, nCD2, nWP,
	
	// Decodes
	output nSRAMWEL, nSRAMWEU,
	
	output [6:0] VIDEO_R,
	output [6:0] VIDEO_G,
	output [6:0] VIDEO_B,
	output VIDEO_SYNC
	
	// Serial video output
	//output VIDEO_R_SER, VIDEO_G_SER, VIDEO_B_SER, VIDEO_CLK_SER, VIDEO_LAT_SER,
	
	// I2S interface
	//output I2S_MCLK, I2S_BICK, I2S_SDTI, I2S_LRCK
);
	
	wire [23:1] M68K_ADDR;
	
	assign M68K_ADDR_OUT = M68K_ADDR[19:1];
	
	wire [11:0] PA;			// Palette RAM address
	wire [15:0] PC;			// Palette RAM data
	
	wire [3:0] WE;				// LSPC/B1
	wire [3:0] CK;				// LSPC/B1
	
	wire [2:0] BNK;
	
	wire [5:0] nSLOT;
	
	wire [5:0] ANA;			// PSG audio level
/*	wire [6:0] VIDEO_R;
	wire [6:0] VIDEO_G;
	wire [6:0] VIDEO_B;*/
	
	// Implementation specific (unique slot)
	assign nSLOTCS = nSLOT[0];
	
	// Are these good ?
	assign nBITWD0 = |{nBITW0, M68K_ADDR[6:5]};
	assign nCOUNTOUT = |{nBITW0, ~M68K_ADDR[6:5]};
	
	wire [8:0] HCOUNT;		// Todo: remove
	
	cpu_68k M68KCPU(CLK_68KCLK, nRESET, IPL1, IPL0, nDTACK, M68K_ADDR, M68K_DATA, nLDS, nUDS, nAS, M68K_RW);
	cpu_z80 Z80CPU(CLK_4M, nRESET, SDD, SDA, nIORQ, nMREQ, nSDRD, nSDWR, nZ80INT, nNMI);
	
	neo_c1 C1(M68K_ADDR[21:17], M68K_DATA[15:8], A22Z, A23Z, nLDS, nUDS, M68K_RW, nAS, nROMOEL, nROMOEU,
				nPORTOEL, nPORTOEU, nPORTWEL, nPORTWEU, nPORTADRS, nWRL, nWRU, nWWL, nWWU, nSROMOEL, nSROMOEU, 
				nSRAMOEL, nSRAMOEU, nSRAMWEL, nSRAMWEU, nLSPOE, nLSPWE, nCRDO, nCRDW, nCRDC, nSDW, P1_IN, P2_IN,
				nCD1, nCD2, nWP, nROMWAIT, PWAIT0, PWAIT1, PDTACK, SDD, CLK_68KCLK, nDTACK, nBITW0, nBITW1, nDIPRD0,
				nDIPRD1, nPAL);
	
	// Todo: nSDZ80R, nSDZ80W, nSDZ80CLR comes from C1
	neo_d0 D0(CLK_24M, nRESET, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_6MB, CLK_1MB,
				M68K_ADDR[4], nBITWD0, M68K_DATA[5:0],
				SDA[15:11], SDA[4:2], nSDRD, nSDWR, nMREQ, nIORQ, nZ80NMI, nSDZ80R, nSDZ80W, nSDZ80CLR,
				nSDROM, nSDMRD, nSDMWR, SDRD0, SDRD1, n2610CS, n2610RD, n2610WR, nZRAMCS, BNK);
	
	neo_e0 E0(M68K_ADDR[23:7], BNK[2:0], nSROMOEU, nSROMOEL, nSROMOE,
				nVEC, A23Z, A22Z, CDA_U);
	
	neo_f0 F0(nDIPRD1, nBITWD0, M68K_ADDR[7:4], M68K_DATA[7:0], SYSTEMB, nSLOT, SLOTA, SLOTB, SLOTC,
				nLED_LATCH, nLED_DATA);
	
	neo_i0 I0(nRESET, nCOUNTOUT, M68K_ADDR[3:1], M68K_ADDR[7], COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2);
	
	syslatch SL(M68K_ADDR[4:1], nBITW1, nRESET,
				SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, nSRAMWEN, PALBNK);

	// Normally in ZMC2, saves 2 FPGA inputs
	assign {DOTA, DOTB} = {|GAD, |GBD};
	
	// Todo: REMOVE HCOUNT, it's only used for simulation in videout
	lspc_a2 LSPC(CLK_24M, nRESET, PBUS, M68K_ADDR[3:1], M68K_DATA, nLSPOE, nLSPWE, DOTA, DOTB, CA4, S2H1,
				S1H1, LOAD, H, EVEN1, EVEN2, IPL0, IPL1, TMS0, LD1, LD1, PCK1, PCK2, WE[3:0], CK[3:0], SS1,
				SS2, nRESETP, VIDEO_SYNC, CHBL, nBNKB, nVCS, CLK_8M, CLK_4M, HCOUNT);
	
	neo_b1 B1(CLK_6MB, CLK_1MB, PBUS, FIXD, PCK1, PCK2, CHBL, nBNKB, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, S1H1,
				A23Z, A22Z, PA, nLDS, M68K_RW, nAS, M68K_ADDR[21:17], M68K_ADDR[12:1], nHALT, nRESET, nRESET_BTN);
	
	z80ram ZRAM(SDA[10:0], SDD, nZRAMCS, nSDMRD, nSDMWR);
	palram PALRAM({PALBNK, PA}, PC, nPALWE);
	
	ym2610 YM(CLK_8M, SDD, SDA[1:0], nZ80INT, n2610CS, n2610WR, n2610RD, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,
					SDPAD, SDPA, SDPMPX, nSDPOE, ANA, SH1, SH2, OP0, PHI_M);
	
	ym2i2s YM2I2S(nRESET, CLK_I2S, ANA, SH1, SH2, OP0, PHI_M, I2S_MCLK, I2S_BICK, I2S_SDTI, I2S_LRCK);
	
	// MVS only
	upd4990 RTC(CLK_RTC, RTC_CS, RTC_OE, RTC_CLK, RTC_DATA_IN, TP, RTC_DATA_OUT);

	// Todo: REMOVE HCOUNT, it's only used for simulation file output here:
	videout VOUT(CLK_6MB, nBNKB, SHADOW, PC, VIDEO_R, VIDEO_G, VIDEO_B, HCOUNT);
	/*ser_video SERVID(nRESET, CLK_SERVID, CLK_6MB, VIDEO_R, VIDEO_G, VIDEO_B,
						VIDEO_R_SER, VIDEO_G_SER, VIDEO_B_SER, VIDEO_CLK_SER, VIDEO_LAT_SER);*/
	
	// nSRAMCS comes from analog battery backup circuit
	assign nSRAMCS = 1'b0;
	sram SRAM(M68K_DATA, M68K_ADDR[15:1], nBWL, nBWU, nSRAMOEL, nSRAMOEU, nSRAMCS);
	assign nSWE = nSRAMWEN | nSRAMCS;
	assign nBWL = nSRAMWEL | nSWE;
	assign nBWU = nSRAMWEU | nSWE;
	
	// Unique gates
	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	assign nPALWE = M68K_RW | nPAL;
	assign SYSTEMB = ~nSYSTEM;
	assign nROMOE = nROMOEU & nROMOEL;
	
	// Memcard stuff
	assign CARD_PIN_nWE = |{nCARDWEN, ~CARDWENB, nCRDW};
	assign CARD_PIN_nREG = nREGEN | nCRDO;

	// Palette data bidir buffer from/to 68k
	assign M68K_DATA = (M68K_RW & ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	assign PC = nPALWE ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;

endmodule

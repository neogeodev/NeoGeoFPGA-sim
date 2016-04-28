`timescale 1ns/1ns

// SNK NeoGeo FPGA hardware definitions (for simulation only)
// furrtek, Charles MacDonald, Kyuusaku, freem and neogeodev contributors ~ 2016
// https://github.com/neogeodev/NeoGeoFPGA-sim

module neogeo_mvs(
	input CLK_24M,
	input nRESET_BTN,				// AES only
	
	inout [15:0] M68K_DATA,
	output [22:0] M68K_ADDR,	// Really A23~A1
	output nWWL, nWWU, nWRL, nWRU,
	output nSROMOE, nSYSTEM,
	
	inout [23:0] PBUS,
	output nVCS,
	output S2H1,
	
	input [7:0] FIXD_SFIX,
	
	input [9:0] P1_IN,			// Joypads
	input [9:0] P2_IN,
	output [2:0] P1_OUT,
	output [2:0] P2_OUT,
	
	output [23:0] CDA,			// Memcard address
	output [15:0] CDD,			// Memcard data
	output nCRDC, nCRDO, CARD_PIN_nWE, CARD_PIN_nREG, nCD1, nCD2, nWP,
	
	input TEST_BTN,				// MVS only
	input [7:0] DIPSW,
	output [3:0] EL_OUT,			// Clock, 3x data
	output [8:0] LED_OUT1,		// Clock, 8x data
	output [8:0] LED_OUT2,		// Clock, 8x data
	
	output [6:0] VIDEO_R,
	output [6:0] VIDEO_G,
	output [6:0] VIDEO_B,
	output VIDEO_SYNC
);

	// Dev notes:
	// ao68000 loads SSP and PC properly, reads word opcode 4EF9 for JMP at C00402
	// but reads 2x longword after, decoder_micropc is good for JMP but isn't used...

	// Todo: Z80 controller (NEO-D0)
	// Todo: VPA for interrupt ACK (NEO-C1)
	// Todo: Check watchdog timing

	// Register implementation:
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
	
	//Reg/Signal        Address                         Value     Mask
	//REG_P1CNT(RD) =   0b0011000x xxxxxxxx xxxxxxx0    300000    3E0001
	//nDIPRD0(RD) =     0b0011000x xxxxxxxx xxxxxxx1    300001    3E0001
	//  REG_DIPSW(RD)   0b0011000x xxxxxxxx 0xxxxxx1    300001    3E0081
	//  REG_$300081(RD) 0b0011000x xxxxxxxx 1xxxxxx1    300081    3E0081
	//REG_SOUND(W/RD) = 0b0011001x xxxxxxxx xxxxxxx0    320000    3E0001
	//nDIPRD1(RD) =     0b0011001x xxxxxxxx xxxxxxx1    320001    3E0001 \ Unique
	//  REG_STATUS_A    0b0011001x xxxxxxxx xxxxxxx1    320001    3E0001 /
	//REG_P2CNT(RD) =   0b001101?x xxxxxxxx xxxxxxx0    340000    3C0001 3E0001 ?
	//REG_STATUS_B(RD)= 0b0011100x xxxxxxxx xxxxxxx0    380000    3E0001
	//nBITW0(WR) =      0b0011100x xxxxxxxx xxxxxxx1    380001    3E0001
	//  nBITWD0(WR) =   0b0011100x xxxxxxxx x00xxxx1    380001    3E0061
	//      REG_POUTPUT 0b0011100x xxxxxxxx x000xxx1    380001    3E0071
	//      REG_CRDBANK 0b0011100x xxxxxxxx x001xxx1    380011    3E0071
	//  REG_SLOT        0b0011100x xxxxxxxx ?010xxx1    380021    3E0071 3E00F1 ?
	//  REG_LEDLATCHES  0b0011100x xxxxxxxx ?011xxx1    380031    3E0071 3E00F1 ?
	//  REG_LEDDATA     0b0011100x xxxxxxxx ?100xxx1    380041    3E0071 3E00F1 ?
	//  REG_RTCCTRL     0b0011100x xxxxxxxx 0101xxx1    380051    3E00F1
	//  REG_$3800D1     0b0011100x xxxxxxxx 1101xxx1    3800D1    3E00F1
	//  nCUNTOUT =      0b0011100x xxxxxxxx x11x?xx1    380061    3E0061 3E0069 ?
	//    REG_RESETCC1  0b0011100x xxxxxxxx x1100001    380051    3E0071
	//    REG_RESETCC2  0b0011100x xxxxxxxx x1100011    380051    3E0071
	//    REG_RESETCL1  0b0011100x xxxxxxxx x1100101    380051    3E0071
	//    REG_RESETCL2  0b0011100x xxxxxxxx x1100111    380051    3E0071
	//    REG_SETCC1    0b0011100x xxxxxxxx x1110001    380051    3E0071
	//    REG_SETCC2    0b0011100x xxxxxxxx x1110011    380051    3E0071
	//    REG_SETCL1    0b0011100x xxxxxxxx x1110101    380051    3E0071
	//    REG_SETCL2    0b0011100x xxxxxxxx x1110111    380051    3E0071
	//?                 0b0011101x xxxxxxxx xxxxxxx0    3A0000    3E0001
	//nBITW1(WR) =      0b0011101x xxxxxxxx xxxxxxx1    3A0001    3E0001 (system latch)
	//nLSPCZONE(W/RD) = 0b0011110x xxxxxxxx xxxxxxx0    3C0000    3E0001 (changed ? see neo_c1.v)
	
	wire A22Z, A23Z;
	wire M68K_RW;
	wire nDTACK;
	wire nRESET, nRESETP;
	wire CLK_68KCLK;
	
	wire CLK_1MB;
	wire CLK_6MB;
	
	wire [15:0] SDA;
	wire [7:0] SDD;			// Z80 data bus
	
	wire nPAL, nPALWE;
	wire nSROMOEU, nSROMOEL;
	
	wire nROMOE;
	
	wire [7:0] FIXD;
	wire [7:0] FIXD_CART;
	wire [11:0] PA;			// Palette RAM address
	wire [3:0] GAD, GBD;		// Pixel pair
	wire [31:0] CR;			// Raw sprite data
	wire [15:0] PC;			// Palette RAM data
	wire [3:0] WE;				// LSPC/B1
	wire [3:0] CK;				// LSPC/B1
	
	wire SYSTEMB;
	
	wire nVEC, SHADOW;
	wire nBNKB;
	
	wire [2:0] BNK;
	
	wire [5:0] nSLOT;
	
	wire [7:0] SDRAD;
	wire [23:20] SDRA_U;
	wire [9:8] SDRA_L;
	wire [7:0] SDPAD;
	wire [11:8] SDPA;
	
	wire [3:0] ANA;		// PSG audio level
	
	// Implementation specific (unique slot)
	assign nSLOTCS = nSLOT[0];
	
	// Are these good ?
	assign nBITWD0 = |{nBITW0, M68K_ADDR[5:4]};
	assign nCOUNTOUT = |{nBITW0, ~M68K_ADDR[5:4]};
	
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
	
	neo_c1 C1(M68K_ADDR[20:16], M68K_DATA[15:8], A22Z, A23Z, nLDS, nUDS, M68K_RW, nAS, nROMOEL, nROMOEU, nPORTOEL, nPORTOEU,
				nPORTWEL, nPORTWEU, nPORTADRS, nWRL, nWRU, nWWL, nWWU, nSROMOEL, nSROMOEU, nSRAMOEL, nSRAMOEU, nSRAMWEL,
				nSRAMWEU, nLSPOE, nLSPWE, nCRDO, nCRDW, nCRDC, nSDW, P1_IN, P2_IN, nCD1, nCD2, nWP, ROMWAIT, PWAIT0,
				PWAIT1, PDTACK, SDD, CLK_68KCLK, nDTACK, nBITW0, nBITW1, nDIPRD0, nDIPRD1, nPAL);
	
	// Todo: nSDZ80R, nSDZ80W, nSDZ80CLR comes from C1
	neo_d0 D0(CLK_24M, nRESET, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_6MB, CLK_1MB,
				M68K_ADDR[3], nBITWD0, M68K_DATA[5:0], {P2_OUT, P1_OUT},
				SDA[15:11], SDA[4:2], nSDRD, nSDWR, nMREQ, nIORQ, nZ80NMI, nSDZ80R, nSDZ80W, nSDZ80CLR,
				nSDROM, nSDMRD, nSDMWR, SDRD0, SDRD1, n2610CS, n2610RD, n2610WR, nZRAMCS, BNK);
	
	neo_e0 E0(M68K_ADDR[22:0], BNK[2:0], nSROMOEU, nSROMOEL, nSROMOE,
				nVEC, A23Z, A22Z, CDA[23:0]);
	
	neo_f0 F0(nDIPRD0, nDIPRD1, nBITWD0, DIPSW, M68K_ADDR[6:3], M68K_DATA[7:0], SYSTEMB, nSLOT, SLOTA, SLOTB, SLOTC,
				EL_OUT, LED_OUT1, LED_OUT2);
	
	neo_i0 I0(nRESET, nCOUNTOUT, M68K_ADDR[2:0], M68K_ADDR[7], COUNTER1, COUNTER2, LOCKOUT1, LOCKOUT2);
	
	syslatch SL(M68K_ADDR[3:0], nBITW1, nRESET,
				SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, SRAMWEN, PALBNK);
	
	// Video
	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);
	// Todo: REMOVE HCOUNT, it's only used for simulation in videout
	lspc_a2 LSPC(CLK_24M, nRESET, PBUS, M68K_ADDR[2:0], M68K_DATA, nLSPOE, nLSPWE, DOTA, DOTB, CA4, S2H1,
				S1H1, LOAD, H, EVEN1, EVEN2, IPL0, IPL1, CHG, LD1, LD1, PCK1, PCK2, WE[3:0], CK[3:0], SS1,
				SS2, nRESETP, VIDEO_SYNC, CHBL, nBNKB, nVCS, CLK_8M, CLK_4M, HCOUNT);
	
	neo_b1 B1(CLK_6MB, CLK_1MB, PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, S1H1,
				A23Z, A22Z, PA, nLDS, M68K_RW, M68K_ADDR[20:16], M68K_ADDR[11:0], nHALT, nRESET, VCCON, HCOUNT);
	
	z80ram ZRAM(SDA[10:0], SDD, nZRAMCS, nSDMRD, nSDMWR);
	palram PALRAM({PALBNK, PA}, PC, nPALWE);
	sram SRAM(M68K_DATA, M68K_ADDR[14:0], nBWL, nBWU, nSRAMOEL, nSRAMOEU, nSRAMCS);
	
	ym2610 YM(CLK_8M, SDD, SDA[1:0], nZ80INT, n2610CS, n2610WR, n2610RD, SDRAD, SDRA_L, SDRA_U, SDRMPX, nSDROE,
					SDPAD, SDPA, SDPMPX, nSDPOE, ANA, SH1, SH2, OP0, PHI_M);
	
	// MVS only
	upd4990 RTC(CLK_RTC, RTC_CS, RTC_OE, RTC_CLK, RTC_DATA_IN, TP, RTC_DATA_OUT);
	
	// Todo: Move all this in the testbench, not part of NeoGeo
	mvs_cart CART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, M68K_ADDR[18:0], M68K_DATA, nROMOE,
					nPORTOEL, nPORTOEU, nSLOTCS, nROMWAIT, nPWAIT0, nPWAIT1, PDTACK, SDRAD, SDRA_L, SDRA_U, SDRMPX,
					nSDROE, SDPAD, SDPA, SDPMPX, nSDPOE, nSDROM, SDA, SDD);

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
	// In NEO-G0 (AES only)
	assign M68K_DATA = (M68K_RW & ~nCRDC) ? CDD : 16'bzzzzzzzzzzzzzzzz;
	assign CDD = (~M68K_RW | nCRDC) ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;
	
	// SFIX / Cart FIX switch
	assign FIXD = nSYSTEM ? FIXD_SFIX : FIXD_CART;
	
	// Todo:
	// Palette data bidir buffer from/to 68k
	//assign M68K_DATA = (M68K_RW & ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	//assign PC = nPALWE ? 16'bzzzzzzzzzzzzzzzz : M68K_DATA;

endmodule

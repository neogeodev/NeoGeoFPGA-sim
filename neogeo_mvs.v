`timescale 10ns/10ns

module neogeo_mvs(
	input RESET_BTN,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	output [2:0] P1_OUT,
	output [2:0] P2_OUT,
	output reg [6:0] VIDEO_R,
	output reg [6:0] VIDEO_G,
	output reg [6:0] VIDEO_B,
	output VIDEO_SYNC
);
	
	wire [22:0] M68K_ADDR;	// Really A23~A1
	wire A22Z;
	wire A23Z;
	wire [15:0] M68K_DATA;
	wire M68K_RW;
	
	wire nPAL, nPALWE;
	wire nSROMOEU, nSROMOEL;
	
	wire [15:0] G;				// SFIX address
	wire [7:0] FIXD;
	wire [7:0] FIXD_CART;
	wire [11:0] PA;			// Palette RAM address
	wire [3:0] GAD, GBD;		// Pixel pair
	wire [23:0] PBUS;
	wire [31:0] CR;			// Raw sprite data
	wire [15:0] PC;			// Palette RAM data
	
	wire S2H1;
	wire nSYSTEMB;
	wire SYSTEM;
	
	wire CLK_24M;
	wire nRESETP;
	wire nVEC, SHADOW;
	wire nBNKB;
	
	wire [3:0] WE;				// LSPC/B1
	wire [3:0] CK;				// LSPC/B1
	
	clocks CLK(CLK_24M, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_8M, CLK_6MB, CLK_4M, CLK_1MB);

	mvs_cart CART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, M68K_ADDR[18:0], M68K_DATA, nROMOE,
					nPORTOEL, nPORTOEU);

	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);
	
	neo_c1 C1(M68K_ADDR[20:16], A22Z, A23Z, LDS, UDS, RW, AS, ROMOEL, ROMOEU, PORTOEL, PORTOEU, PORTWEL, PORTWEU,
				PORTADRS, WRL, WRU, WWL, WWU, SROMOEL, SROMOEU, SRAMOEL, SRAMOEU, SRAMWEL, SRAMWEU, LSPOE, LSPWE,
				CRDO, CRDW, CRDC);

	lspc_a2 LSPC(CLK_24M, nRESET, PBUS, M68K_ADDR[2:0], M68K_DATA, nLSPOE, nLSPWE, DOTA, DOTB, CA4, S2H1,
				S1H1, LOAD, H, EVEN1, EVEN2, IPL0, IPL1, CHG, LD1, LD1, PCK1, PCK2, WE[3:0], CK[3:0], SS1,
				SS2, nRESETP, SYNC, CHBL, nBNKB, nVCS, CLK_6M);
	neo_b1 B1(PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, PA);
	
	rom_l0 L0(PBUS[15:0], PBUS[23:16], nVCS);
	rom_sps2 SP(M68K_ADDR[15:0], M68K_DATA[15:0], nSROMOE);
	rom_sfix SFIX({G[15:3], S2H1, G[2:0]}, FIXD, nSYSTEM);

	palram PRAML({PALBNK, PA}, PC[7:0], nPALWE, 1'b0, 1'b0);
	palram PRAMU({PALBNK, PA}, PC[15:8], nPALWE, 1'b0, 1'b0);
	
	// Gates
	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	assign nSROMOE = nSROMOEU & nSROMOEL;
	assign nPALWE = M68K_RW & nPAL;
	assign SYSTEMB = nSYSTEM;	// ?
	
	// Good job SNK ! Gates cart FIXD to avoid bus wreck with SFIX
	assign FIXD = SYSTEM ? FIXD : FIXD_CART;
	
	// This is done by NEO-E0:
	// A' = 1 if nVEC == 0 and A == 11000000000000000xxxxxxx
	assign {A23Z, A22Z} = M68K_ADDR[22:21] ^ {2{~|{M68K_ADDR[20:6], ^M68K_ADDR[22:21], nVEC}}};
	
	// Palette data bidir buffer from/to 68k
	assign M68K_DATA = (M68K_RW | ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	assign PC = nPALWE ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;
	
	// Color data latch/blanking
	always @(posedge CLK_6MB)
	begin
		VIDEO_R <= nBNKB ? {SHADOW, PC[11:8], PC[14], PC[15]} : 7'b0000000;
		VIDEO_G <= nBNKB ? {SHADOW, PC[7:4], PC[13], PC[15]} : 7'b0000000;
		VIDEO_B <= nBNKB ? {SHADOW, PC[3:0], PC[12], PC[15]} : 7'b0000000;
	end

endmodule

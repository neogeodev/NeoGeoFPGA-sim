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

	wire [3:0] GAD, GBD;
	wire [11:0] PA;
	wire [23:0] PBUS;
	wire [7:0] FIXD;
	wire [31:0] CR;
	wire [15:0] PC;
	wire M68K_RW;
	wire nPAL, nPALWE;
	wire nSROMOEU, nSROMOEL;
	
	wire [22:0] M68K_ADDR;
	wire [15:0] M68K_DATA;
	
	wire A22Z;
	wire A23Z;
	
	wire [14:0] B;		// Low VRAM address
	wire [10:0] C;		// High VRAM address
	wire [15:0] E;		// Low VRAM data
	wire [15:0] F;		// High VRAM data
	
	wire [15:0] G;		// SFIX address
	
	wire S2H1;
	wire nSYSTEMB;
	wire SYSTEM;
	
	wire CLK_24M;
	wire nRESETP;
	wire nVEC, SHADOW;
	wire nBNKB;
	
	// LSPC
	
	// NEO-D0 clock divider
	reg [2:0] CLKDIV;
	
	always @(posedge CLK_24M or posedge ~nRESETP)
	begin
		if (~nRESETP)
			CLKDIV <= 0;
		else
			CLKDIV <= CLKDIV + 1;
	end
	
	assign CLK_12M = CLKDIV[0];
	assign CLK_68KCLK = CLKDIV[0];
	assign CLK_68KCLKB = ~CLK_68KCLK;
	assign CLK_6MB = CLKDIV[1];
	assign CLK_1MB = CLKDIV[2];

	mvs_cart CART(PBUS, CA4, S2H1, PCK1B, PCK2B, CR, FIXD_CART, M68K_ADDR[18:0], M68K_DATA, nROMOE, nPORTOEL, nPORTOEU);

	// Good job SNK !
	assign FIXD = nSYSTEM ? FIXD : FIXD_CART;

	neo_zmc2 ZMC2(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);

	neo_b1 B1(PBUS, FIXD, PCK1, PCK2, GAD, GBD, WE, CK, TMS0, LD1, LD2, SS1, SS2, PA);
	
	rom_l0 L0(PBUS[15:0], PBUS[23:16], nVCS);
	rom_sps2 SP(M68K_ADDR[15:0], M68K_DATA[15:0], nSROMOE);
	rom_sfix SFIX({G[15:3], S2H1, G[2:0]}, FIXD, nSYSTEM);

	palram PRAML({PALBNK, PA}, PC[7:0], nPALWE, 0, 0);
	palram PRAMU({PALBNK, PA}, PC[15:8], nPALWE, 0, 0);
	
	vram_l VRAMLL(B, E[7:0], nBWE, nBOE, 0);
	vram_l VRAMLU(B, E[15:8], nBWE, nBOE, 0);
	vram_u VRAMUL(C, F[7:0], nCWE, 0, 0);
	vram_u VRAMUU(C, F[15:8], nCWE, 0, 0);
	
	// Gates
	assign PCK1B = ~PCK1;
	assign PCK2B = ~PCK2;
	assign nSROMOE = nSROMOEU & nSROMOEL;
	assign nPALWE = M68K_RW & nPAL;
	assign nSYSTEMB = SYSTEM;
	
	// This is done by NEO-E0:
	// A' = 1 if nVEC == 0 and A == 11000000000000000xxxxxxx
	assign {A23Z, A22Z} = M68K_ADDR[23:22] ^ {2{~|{M68K_ADDR[21:7], ^M68K_ADDR[23:22], nVEC}}};
	
	// Palette data bidir buffer from/to 68k
	assign M68K_DATA = (M68K_RW | ~nPAL) ? PC : 16'bzzzzzzzzzzzzzzzz;
	assign PC = nPALWE ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;
	
	// Color data latch/blanking
	always @(posedge CLK_6MB)
	begin
		VIDEO_R <= nBNKB ? {SHADOW, C[11:8], C[14]} : 6'b000000;
		VIDEO_G <= nBNKB ? {SHADOW, C[7:4], C[13]} : 6'b000000;
		VIDEO_B <= nBNKB ? {SHADOW, C[3:0], C[12]} : 6'b000000;
	end

endmodule

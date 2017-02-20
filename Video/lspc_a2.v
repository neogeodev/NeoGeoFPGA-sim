`timescale 1ns/1ns

// All pins listed ok. REF, DIVI and DIVO only used on AES for video PLL hack
	
module lspc_a2(
	input CLK_24M,
	input nRESET,
	output [15:0] PBUS_OUT,
	inout [23:16] PBUS_IO,
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nLSPOE, nLSPWE,
	input DOTA, DOTB,
	output CA4, S2H1,
	output S1H1,						// ?
	output LOAD, H, EVEN1, EVEN2,	// For ZMC2
	output IPL0, IPL1,
	output TMS0,						// Also called SCH and CHG
	output LD1, LD2,
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	input SS1, SS2,					// Outputs ?
	output nRESETP,
	output SYNC,
	output CHBL,
	output nBNKB,
	output nVCS,
	output CLK_8M,
	output CLK_4M,
	output [8:0] HCOUNT				// TODO: REMOVE, only used for debug in videout and as a hack in B1
);

	assign HCOUNT = MAIN_CNT[10:2];	// TODO: REMOVE
	

	parameter VIDEO_MODE = 0;			// NTSC

	/*
		Slow cycle:
		0000~6FFF: Sprites map
		7000~7FFF: Fix map
		
		A14 A13 A12 A0
		  x   x   x  0   Sprite tile
		  x   x   x  1   Sprite attr
	     1   1   1  x   Fix
	*/

	// Todo: Merge VRAM cycle counters together if possible ? Even with P bus ?
	
	wire [8:0] VCOUNT;
	
	// VRAM CPU I/O
	reg CPU_RW;										// Direction
	reg CPU_VRAM_ZONE;							// Top bit of VRAM address (low/high indicator)
	reg [14:0] CPU_VRAM_ADDR;
	reg [14:0] CPU_VRAM_ADDRESS_BUFFER;
	reg [15:0] CPU_VRAM_WRITE_BUFFER;
	wire [15:0] CPU_VRAM_READ_BUFFER_SCY;	// Are these all the same ?
	wire [15:0] CPU_VRAM_READ_BUFFER_FCY;
	wire [15:0] CPU_VRAM_READ_BUFFER;
	
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	wire [2:0] SPR_TILE_NB_AA;		// SPR_ATTR_TILE_NB after auto-animation applied
	wire [1:0] SPR_ATTR_AA;			// Auto-animation config bits
	wire [11:0] SPR_ATTR_SHRINK;
	
	wire VBLANK;
	wire nVSYNC;
	wire HSYNC;
	
	reg [3:0] SPR_PIXELCNT;				// Sprite render pixel counter for H-shrink
	wire WR_PIXEL;
	
	wire [7:0] L0_DATA;
	
	wire [11:0] MAIN_CNT;
	
	wire [8:0] SPR_NB;
	wire [4:0] SPR_TILEIDX;
	wire [1:0] SPR_TILEFLIP;
	
	wire [19:0] SPR_TILE_NB;
	wire [7:0] SPR_TILE_PAL;
	
	wire [11:0] FIX_TILE_NB;
	wire [3:0] FIX_TILE_PAL;

	wire [16:0] FIX_ROM_ADDR;
	wire [24:0] SPR_ROM_ADDR;
	
	wire [4:0] SPR_ROM_LINE;
	
	wire [7:0] SPR_XPOS;
	wire [15:0] L0_ROM_ADDR;
	
	wire IRQ_S3;
	
	

	// Alpha68k stuff:
	assign nBFLIP = TMS0;	// ?
	// M12:
	assign RBA = nBFLIP ? 1'b0 : CLK_CLEAR;
	assign RBB = nBFLIP ? CLK_CLEAR : 1'b0;
	assign CLK_EVEN_B = nBFLIP ? nCLK_12M : CLK_CLEAR;
	assign CLK_EVEN_A = nBFLIP ? CLK_CLEAR : nCLK_12M;
	// J5
	// SELJ5 comes from K5:A
	assign CLK_CLEAR = SELJ5 ? nCLK_12M : TODO;
	assign nCLEAR_WE = SELJ5 ? nCLK_12M : 1'b1;
	always @(posedge SNKCLK_26)
		BFLIP <= 1'bz;	// TODO
	
	// P6
	assign nODD_WE = ~(DOTB & CLK_12M);
	assign nEVEN_WE = ~(DOTA & CLK_12M);
	// WSE signals to B1
	assign nWE_ODD_A = nBFLIP ? nODD_WE : nCLEAR_WE;
	assign nWE_ODD_B = nBFLIP ? nCLEAR_WE : nODD_WE;
	assign nWE_EVEN_A = nBFLIP ? nEVEN_WE : nCLEAR_WE;
	assign nWE_EVEN_B = nBFLIP ? nCLEAR_WE : nEVEN_WE;
	
	
	assign IRQ_S3 = VBLANK;			// To check
	assign CLK_24MB = ~CLK_24M;
	assign SYNC = nVSYNC ^ HSYNC;
	
	// Todo: Probably wrong:
	assign CPU_VRAM_READ_BUFFER = CPU_VRAM_ZONE ? CPU_VRAM_READ_BUFFER_FCY : CPU_VRAM_READ_BUFFER_SCY;
	
	
	timer TIMER(nRESET, VBLANK, VIDEO_MODE, TIMERSTOP, VCOUNT);
	
	resetp RSTP(CLK_24M, nRESET, nRESETP);
	
	irq IRQ(IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_S3, IRQ_R3, IPL0, IPL1);		// Probably uses nRESETP
	
	videosync VS(CLK_24M, nRESETP, VCOUNT, MAIN_CNT, TMS0, VBLANK, nVSYNC, HSYNC, nBNKB);

	odd_clk ODDCLK(CLK_24M, nRESETP, CLK_8M, CLK_4M, CLK_4MB);
	
	slow_cycle SCY(CLK_24M, nRESETP,
					HCOUNT[8:0], VCOUNT[7:3], SPR_NB, SPR_TILEIDX,	SPR_TILE_NB, SPR_TILEPAL,
					SPR_TILE_AA, SPR_TILEFLIP, FIX_TILE_NB, FIX_TILEPAL,
					CPU_VRAM_ADDRESS_BUFFER, CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER_SCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW);
	
	// Todo: this needs to give SPR_NB, SPR_TILEIDX, SPR_XPOS, L0_ADDR, SPR_ATTR_SHRINK
	// Todo: this needs L0_DATA (from P bus)
	fast_cycle FCY(CLK_24M, nRESETP,
					CPU_VRAM_ADDRESS_BUFFER[10:0], CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER_FCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW);
	
	// This needs SPR_XPOS, L0_ADDR
	p_cycle PCY(nRESET, CLK_24M, HSYNC, FIX_ROM_ADDR, FIX_TILEPAL, SPR_ROM_ADDR, SPR_TILEPAL, SPR_XPOS, L0_ADDR,
					PCK1, PCK2, LOAD, S1H1, nVCS, L0_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(nRESET, VBLANK, AA_SPEED, SPR_TILE_NB[2:0], AA_DISABLE, SPR_ATTR_AA, SPR_TILE_NB_AA, AA_COUNT);
	
	hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
	// - -------- ---10000 HCOUNT for first fix address latch would be 4 ?
	// n nnnnnnnn nnnHHvvv
	// 6M: PCK2 = 4 pixels
	// 4: Latch from P, has 2 pixels
	// 5: Nothing
	// 6: S2H1 changes, has 2 pixels
	// 7: Nothing
	
	// Same as Alpha68k:
	assign FIX_ROM_ADDR = {FIX_TILE_NB, HCOUNT[2:1], VCOUNT[2:0]};
	assign S2H1 = FIX_ROM_ADDR[3];
		
	// One address = 32bit of data = 8 pixels
	// 16,0 17,1 18,2 19,3 ... 31,15
	assign SPR_ROM_ADDR = {{SPR_TILE_NB[19:3], SPR_TILE_NB_AA}, SPR_ROM_LINE};
	assign CA4 = SPR_ROM_ADDR[4];
	
endmodule

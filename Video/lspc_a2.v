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
	output [8:0] H_COUNT				// TODO: REMOVE, only used for debug in videout and as a hack in B1
);

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
	
	wire [8:0] V_COUNT;
	
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
	
	wire [15:0] SLOW_VRAM_DATA;
	
	wire [7:0] L0_DATA;
	
	wire [11:0] MAIN_CNT;
	
	wire [8:0] SPR_NB;
	wire [4:0] SPR_TILEIDX;
	wire [1:0] SPR_TILEFLIP;
	
	wire [19:0] SPR_TILE_NB;
	wire [7:0] SPR_TILE_PAL;
	
	reg [11:0] FIX_TILE_NB;
	wire [5:0] FIX_MAP_COL;		// 0~47

	wire [15:0] PBUS_S_ADDR;
	wire [24:0] SPR_ROM_ADDR;
	
	wire [4:0] SPR_ROM_LINE;
	
	wire [7:0] SPR_XPOS;
	wire [15:0] L0_ROM_ADDR;
	
	reg CA4_Q;
	reg S2H1_Q;
	wire FIX_A4;
	reg [3:0] FIX_PAL_NB;
	
	wire IRQ_S3;
	
	wire K2_1;		// TODO
	wire K8_6;		// TODO
	wire nBFLIP;	// TODO
	wire SELJ5;		// TODO
	wire CLK_12M;	// TODO
	wire nCLK_12M;	// TODO
	wire nLATCH_X;	// TODO
	

	// Alpha68k stuff:
	// K2
	assign K2_4 = K2_1 ? 1'b1 : nLATCH_X;	// TODO
	assign K2_7 = K2_1 ? nLATCH_X : 1'b1;
	assign K2_9 = K2_1 ? K8_6 : 1'b1;		// TODO
	assign K2_12 = K2_1 ? 1'b1 : K8_6;		// TODO
	
	// Opposite ?
	// K5:C
	assign LD1 = K2_7 & K2_12;
	// K5:?
	assign LD2 = K2_4 & K2_9;		// To check !
	
	// M12
	assign RBA = nBFLIP ? 1'b0 : CLK_RD;
	assign RBB = nBFLIP ? CLK_RD : 1'b0;
	assign CLK_EVEN_B = nBFLIP ? nCLK_12M : CLK_RD;
	assign CLK_EVEN_A = nBFLIP ? CLK_RD : nCLK_12M;
	// J5
	// SELJ5 comes from K5:A
	assign CLK_RD = SELJ5 ? nCLK_12M : 1'bz;	// TODO
	assign nCLEAR_WE = SELJ5 ? nCLK_12M : 1'b1;
	//always @(posedge SNKCLK_26)
	//	BFLIP <= 1'bz;	// TODO
	
	// P6
	assign nODD_WE = ~(DOTB & CLK_12M);
	assign nEVEN_WE = ~(DOTA & CLK_12M);
	// Second half of P6 in B1
	
	// N6 - WSE signals to B1
	assign nWE_ODD_A = nBFLIP ? nODD_WE : nCLEAR_WE;
	assign nWE_ODD_B = nBFLIP ? nCLEAR_WE : nODD_WE;
	assign nWE_EVEN_A = nBFLIP ? nEVEN_WE : nCLEAR_WE;
	assign nWE_EVEN_B = nBFLIP ? nCLEAR_WE : nEVEN_WE;
	
	
	assign IRQ_S3 = VBLANK;			// To check
	assign CLK_24MB = ~CLK_24M;
	assign SYNC = nVSYNC ^ HSYNC;
	
	// Todo: Probably wrong:
	assign CPU_VRAM_READ_BUFFER = CPU_VRAM_ZONE ? CPU_VRAM_READ_BUFFER_FCY : CPU_VRAM_READ_BUFFER_SCY;
	
	// CA4	''''|______|''''
	// PCK1	____|'|_________
	always @(negedge CLK_24M)
		CA4_Q <= CA4;
	assign PCK1 = (CA4_Q & !CA4);

	// 2H1	''''|______|''''
	// PCK2	____|'|_________
	always @(negedge CLK_24M)
		S2H1_Q <= S2H1;
	assign PCK2 = (S2H1_Q & !S2H1);
	
	lspc_timer TIMER(nRESET, CLK_6M_LSPC, VBLANK, VIDEO_MODE, TIMER_MODE, TIMER_INT_EN, TIMER_LOAD,
							TIMER_PAL_STOP, V_COUNT);
	
	resetp RSTP(CLK_24M, nRESET, nRESETP);
	
	irq IRQ(IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_S3, IRQ_R3, IPL0, IPL1);		// Probably uses nRESETP
	
	videosync VS(CLK_24M, nRESETP, V_COUNT, H_COUNT, TMS0, VBLANK, nVSYNC, HSYNC, nBNKB, CHBL, FIX_MAP_COL);

	odd_clk ODDCLK(CLK_24M, nRESETP, CLK_8M, CLK_4M, CLK_4MB);
	
	// This needs to be way simpler. Use FIX_MAP_COL as input, output SLOW_VRAM_DATA.
	/*slow_cycle SCY(CLK_24M, nRESETP,
					H_COUNT[8:0], V_COUNT[7:3], SPR_NB, SPR_TILEIDX,	SPR_TILE_NB, SPR_TILEPAL,
					SPR_TILE_AA, SPR_TILEFLIP, FIX_TILE_NB, FIX_TILEPAL,
					CPU_VRAM_ADDRESS_BUFFER, CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER_SCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW, SLOW_VRAM_DATA);*/
	
	// Slow VRAM latches
	always @(posedge PCK1)				// Good ?
	begin
		FIX_TILE_NB <= SLOW_VRAM_DATA[11:0];
		FIX_PAL_NB <= SLOW_VRAM_DATA[15:12];
	end
	
	// Todo: this needs to give SPR_NB, SPR_TILEIDX, SPR_XPOS, L0_ADDR, SPR_ATTR_SHRINK
	// Todo: this needs L0_DATA (from P bus)
	fast_cycle FCY(CLK_24M, nRESETP,
					CPU_VRAM_ADDRESS_BUFFER[10:0], CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER_FCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_RW);
	
	// This needs SPR_XPOS, L0_ADDR
	p_cycle PCY(nRESET, CLK_24M, PBUS_S_ADDR, FIX_TILEPAL, SPR_ROM_ADDR, SPR_TILEPAL, SPR_XPOS, L0_ADDR,
					LOAD, S1H1, nVCS, L0_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(nRESET, VBLANK, AA_SPEED, SPR_TILE_NB[2:0], AA_DISABLE, SPR_ATTR_AA, SPR_TILE_NB_AA, AA_COUNT);
	
	hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
	// P bus values
	assign PBUS_S_ADDR = {FIX_A4, V_COUNT[2:0], FIX_TILE_NB};
	
	assign CA4 = H_COUNT[1];
	assign S2H1 = ~CA4;
		
	// One address = 32bit of data = 8 pixels
	// 16,0 17,1 18,2 19,3 ... 31,15
	assign SPR_ROM_ADDR = {{SPR_TILE_NB[19:3], SPR_TILE_NB_AA}, SPR_ROM_LINE};
	
endmodule

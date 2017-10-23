`timescale 1ns/1ns

// All pins listed ok. REF, DIVI and DIVO only used on AES for video PLL hack
// Video mode pin is the VIDEO_MODE parameter

module lspc_a2(
	input CLK_24M,
	input nRESET,
	output [15:0] PBUS_OUT,
	inout [23:16] PBUS_IO,
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input nLSPOE, nLSPWE,
	input DOTA, DOTB,
	output CA4,
	output S2H1,
	output S1H1,
	output reg LOAD,
	output H, EVEN1, EVEN2,			// For ZMC2
	output IPL0, IPL1,
	output TMS0,						// Also called SCH or CHG
	output LD1_, LD2_,				// Buffer address load
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	output SS1, SS2,					// Buffer pair selection for B1
	output nRESETP,
	output SYNC,
	output CHBL,
	output nBNKB,
	output nVCS,						// LO ROM output enable
	output CLK_8M,
	output CLK_4M
);

	parameter VIDEO_MODE = 1'b0;	// NTSC
	
	wire [8:0] H_COUNT;
	wire [8:0] V_COUNT;
	
	// VRAM CPU I/O
	reg CPU_WRITE;									// Latch for VRAM write operation
	reg CPU_WRITE_ACK_PREV;
	wire [14:0] CPU_VRAM_ADDR;
	wire [15:0] CPU_VRAM_WRITE_BUFFER;
	wire [15:0] CPU_VRAM_READ_BUFFER_SCY;	// Are these all the same ?
	wire [15:0] CPU_VRAM_READ_BUFFER_FCY;
	wire [15:0] CPU_VRAM_READ_BUFFER;
	wire [15:0] REG_VRAMMOD;
	
	// Sprites stuff
	//reg [3:0] SPR_PIXELCNT;		// TODO: Sprite render pixel counter for H-shrink
	//wire WR_PIXEL;					// TODO
	wire [11:0] SPR_ATTR_SHRINK;	// TODO
	wire [1:0] SPR_ATTR_AA;			// Auto-animation config bits
	wire [7:0] AA_SPEED;
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	wire [8:0] SPR_NB;
	wire [4:0] SPR_TILE_IDX;
	wire [1:0] SPR_TILE_FLIP;
	wire [19:0] SPR_TILE_NB;
	wire [19:0] SPR_TILE_NB_AA;	// SPR_ATTR_TILE_NB after auto-animation applied
	wire [7:0] SPR_TILE_PAL;
	wire [3:0] SPR_TILE_LINE;
	wire [8:0] SPR_XPOS;
	wire [7:0] XPOS;
	
	// Fix stuff
	wire [14:0] FIX_MAP_ADDR;
	wire [11:0] FIX_TILE_NB;
	wire [3:0] FIX_ATTR_PAL;
	
	// Pixel timer stuff
	wire [2:0] TIMER_MODE;
	wire [31:0] TIMER_LOAD;
	wire [15:0] REG_LSPCMODE;
	
	wire [15:0] PBUS_S_ADDR;	// PBUS address for fix ROM
	wire [23:0] PBUS_C_ADDR;	// PBUS address for sprite ROMs
	wire [15:0] L0_ROM_ADDR;	// TODO
	wire [7:0] L0_ROM_DATA;		// TODO
	
	reg CA4_Q;
	reg S2H1_Q;
	
	wire K2_1;
	wire K8_6;
	wire nBFLIP;
	wire CLK_12M;
	wire nCLK_12M;
	wire nLATCH_X;
	
	reg [3:0] CLKDIV_LSPC;
	reg BFLIP;
	
	// M8 - Seems to be free-running on Alpha68k ? /MR and /LOAD aren't used
	assign RESETP = ~nRESETP;
	always @(negedge CLK_24M or posedge RESETP)
	begin
		if (RESETP)
			CLKDIV_LSPC = 4'd0;
		else
			CLKDIV_LSPC <= CLKDIV_LSPC + 1'b1;
	end
	
	assign CLK_12M = CLKDIV_LSPC[0];
	assign nCLK_12M = ~CLK_12M;
	assign CLK_6M = CLKDIV_LSPC[1];
	assign CLK_6MB = ~CLK_6M;
	assign CLK_1_5M = CLKDIV_LSPC[3];
	
	assign nLATCH_X = ~(CLK_1_5M & LOAD);
	
	
	// This must be simpler
	assign SS1 = ((H_COUNT >= 9'd3) && (H_COUNT <= 9'd322)) & ~TMS0;
	assign SS2 = ((H_COUNT >= 9'd3) && (H_COUNT <= 9'd322)) & TMS0;
	
	
	assign SYNC = HSYNC ^ nVSYNC;
	
	// CPU access to VRAM ====================================================
	
	assign CPU_WRITE_ACK = CPU_WRITE_ACK_SLOW & CPU_WRITE_ACK_FAST;
	assign CPU_WRITE_ACK_PULSE = CPU_WRITE_ACK & ~CPU_WRITE_ACK_PREV;
	
	always @(posedge CLK_24M)	// negedge ?
	begin
		if (!nRESETP)
		begin
			CPU_WRITE <= 1'b1;
		end
		else
		begin
			if (CPU_WRITE_REQ)
				CPU_WRITE <= 1'b1;	// Set

			if (CPU_WRITE_ACK_PULSE)
				CPU_WRITE <= 1'b0;	// Reset
			
			CPU_WRITE_ACK_PREV <= CPU_WRITE_ACK;
		end
	end

	// CPU VRAM read buffer switch between slow and fast VRAM depending on last access
	// This is probably wrong
	assign CPU_VRAM_READ_BUFFER = CPU_VRAM_ZONE ? CPU_VRAM_READ_BUFFER_FCY : CPU_VRAM_READ_BUFFER_SCY;
	
	// CPU VRAM read
	// Todo: See if M68K_ADDR[3] is used or not (msvtech.txt says no, MAME says yes)
	assign M68K_DATA = (nLSPOE | ~nLSPWE) ? 16'bzzzzzzzzzzzzzzzz :
								(M68K_ADDR[2] == 1'b0) ? CPU_VRAM_READ_BUFFER :		// $3C0000,$3C0002,$3C0008,$3C000A
								(M68K_ADDR[1] == 1'b0) ? REG_VRAMMOD :					// 3C0004/3C000C
								REG_LSPCMODE;													// 3C0006/3C000E
	
	// Graphics ROM addressing ================================================
	
	assign S1H1 = H_COUNT[0];
	assign S2H1 = H_COUNT[1];
	// TODO: CA4 should change depending on sprite V-flip attribute (invert)
	assign CA4 = S2H1;
	
	// S2H1	____|''''''|____
	// PCK1	____|'|_________
	always @(negedge CLK_24M)
		CA4_Q <= S2H1;
	assign PCK1 = (!CA4_Q & S2H1);

	// 2H1	''''|______|''''
	// PCK2	____|'|_________
	always @(negedge CLK_24M)
		S2H1_Q <= S2H1;
	assign PCK2 = (S2H1_Q & !S2H1);
	
	// P bus values
	assign FIX_A4 = H_COUNT[2];		// Seems good, matches Alpha68k
	assign PBUS_S_ADDR = {FIX_A4, V_COUNT[2:0], FIX_TILE_NB};
	assign PBUS_C_ADDR = {SPR_TILE_NB_AA[19:16], SPR_TILE_LINE, SPR_TILE_NB_AA[15:0]};

	// The fix map is 16bits/tile in slow VRAM starting @ $7000
	// Organized as 32 lines * 64 columns
	// (0)111xCCC CCCLLLLL
	assign FIX_MAP_ADDR = {4'b1110, H_COUNT[8:3], V_COUNT[7:3]};
	
	// Can be inverted by the MCU, apparently not used (cab config ?)
	assign K2_1 = V_COUNT[0];
	
	// K8:A - Signal to select between sprite X position load or X position reset to start clearing LB ?
	//assign K8_6 = ~&{LOAD, H_COUNT[2], H_COUNT[1], SNKCLK22 ^ SNKCLK20};
	assign nLOAD_X_CLEAR = ~(~CLK_1_5M & LOAD & (H_COUNT <= 9'd2));
	
	// K2 - X load signal switch for both LB pairs
	assign K2_4 = K2_1 ? 1'b1 : nLATCH_X;
	assign K2_7 = K2_1 ? nLATCH_X : 1'b1;
	assign K2_9 = K2_1 ? nLOAD_X_CLEAR : 1'b1;	// K8_6;
	assign K2_12 = K2_1 ? 1'b1 : nLOAD_X_CLEAR;	// K8_6;
	
	// Needs checking. Might also be the opposite (reverse LD1/LD2)
	// K5:C
	assign LD1_ = K2_7 & K2_12;
	// K5:B
	assign LD2_ = K2_4 & K2_9;
	
	// J8:B
	always @(posedge H_COUNT[1])
		BFLIP <= K2_1;
	assign nBFLIP = !BFLIP;
	
	// IMPORTANT NOTE:
	// CK and WE for B1 are different from the Alpha68k, this is probably to allow for horizontal shrinking
	// CK and WE for the same buffer pair on the NeoGeo are interleaved, not synchronous
	
	// M12
	//assign RD_A = nBFLIP ? 1'b0 : CLK_LB_READ_CLEAR;
	//assign RD_B = nBFLIP ? CLK_LB_READ_CLEAR : 1'b0;
	assign CK[0] = BFLIP ? nCLK_12M : nODD_WE_CLEAR;	//CLK_LB_READ_CLEAR;	// CLK_EVEN_B
	assign CK[1] = BFLIP ? nCLK_12M : nEVEN_WE_CLEAR;	// ?
	assign CK[2] = BFLIP ? nODD_WE_CLEAR : nCLK_12M;	// CLK_EVEN_A
	assign CK[3] = BFLIP ? nEVEN_WE_CLEAR : nCLK_12M;	// ?

	// J8:A
	//always @(posedge H_COUNT[1])
	//	nJ8A_Q <= ~SS1;	//~SNKCLK20

	// K5:A
	//assign SW_LB_READ_CLEAR = ~SNKCLK22 & nJ8A_Q;
	
	// J5
	//assign CLK_LB_READ_CLEAR = SW_LB_READ_CLEAR ? nCLK_12M : H_COUNT[0];
	assign WE_LB_CLEAR = CLK_6MB & CLK_12M;	//SW_LB_READ_CLEAR ? nCLK_12M : 1'b1;
	assign nODD_WE_CLEAR = ~(H_COUNT[0] & WE_LB_CLEAR);
	assign nEVEN_WE_CLEAR = ~(~H_COUNT[0] & WE_LB_CLEAR);
	
	// P6:A & B - Pixel write enables according to opacity
	// Second half of P6 is in B1
	assign nODD_WE = ~(DOTB & CLK_12M);
	assign nEVEN_WE = ~(DOTA & CLK_12M);
	
	// N6 - WE signals to B1 (order might be wrong)
	assign WE[0] = BFLIP ? nODD_WE : nODD_WE_CLEAR;		// nWE_ODD_A
	assign WE[1] = BFLIP ? nEVEN_WE : nEVEN_WE_CLEAR;	// nWE_EVEN_A
	assign WE[2] = BFLIP ? nODD_WE_CLEAR : nODD_WE;		// nWE_ODD_B
	assign WE[3] = BFLIP ? nEVEN_WE_CLEAR : nEVEN_WE;	// nWE_EVEN_B
	
	// J13:D - LOAD signal for ZMC2
	// This seems to be different from the Alpha68k, 0.5mclk difference ?
	// Or is it (useful) propagation delay ?
	//assign LOAD = CLK_6MB & H_COUNT[0];
	always @(posedge CLK_24M)
		LOAD <= CLK_6MB & H_COUNT[0];
	
	assign IRQ_S3 = VBLANK;		// Timing to check
	
	// Probably using nRESETP
	//snkclk SCLK(CLK_6MB, nRESET, , , , , , , , , , SNKCLK20, SNKCLK22, , , , , , );
	
	lspc_regs REGS(nRESET, CLK_24M, M68K_ADDR, M68K_DATA, nLSPOE, nLSPWE, PCK1, AA_COUNT, V_COUNT[7:0],
					VIDEO_MODE, REG_LSPCMODE,
					CPU_VRAM_ZONE, CPU_WRITE_REQ, CPU_VRAM_ADDR, CPU_VRAM_WRITE_BUFFER,
					RELOAD_REQ_SLOW, RELOAD_REQ_FAST,
					TIMER_LOAD, TIMER_PAL_STOP, REG_VRAMMOD, TIMER_MODE, TIMER_IRQ_EN,
					AA_SPEED, AA_DISABLE,
					IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3);
	
	lspc_timer TIMER(nRESET, CLK_6M_LSPC, VBLANK, VIDEO_MODE, TIMER_MODE, TIMER_INT_EN, TIMER_LOAD,
							TIMER_PAL_STOP, V_COUNT);
	
	resetp RSTP(CLK_24M, nRESET, nRESETP);
	
	irq IRQ(IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_S3, IRQ_R3, IPL0, IPL1);		// Probably uses nRESETP
	
	videosync VS(CLK_24M, nRESETP, V_COUNT, H_COUNT, TMS0, VBLANK, nVSYNC, HSYNC, nBNKB, CHBL);

	odd_clk ODDCLK(CLK_24M, nRESETP, CLK_8M, CLK_4M, CLK_4MB);
	
	slow_cycle SCY(CLK_24M, CLK_6M, nRESETP, H_COUNT[1:0], PCK1, PCK2,
					FIX_MAP_ADDR, FIX_TILE_NB, FIX_ATTR_PAL,
					SPR_NB, SPR_TILE_IDX, SPR_TILE_NB,
					SPR_TILE_PAL, SPR_ATTR_AA, SPR_TILE_FLIP,
					REG_VRAMMOD[14:0], RELOAD_REQ_SLOW,
					CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER_SCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_WRITE, CPU_WRITE_ACK_SLOW);
	
	assign H = SPR_TILE_FLIP[0];	// Is it bit 1 ?
	assign EVEN1 = SPR_XPOS[0];	// Probably wrong
	
	// Todo: this needs to give L0_ADDR
	// Todo: this needs L0_DATA (from P bus)
	fast_cycle FCY(CLK_24M, nRESETP,
					V_COUNT, CHBL, BFLIP,
					SPR_XPOS, SPR_NB, SPR_TILE_IDX, SPR_TILE_LINE, SPR_ATTR_SHRINK,
					REG_VRAMMOD[10:0], RELOAD_REQ_FAST,
					CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER_FCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_WRITE, CPU_WRITE_ACK_FAST);
	
	// Briefly set XPOS to 0 to reset the line buffer address counters in B1, for output to TV
	// This probably doesn't work that way
	assign XPOS = |{H_COUNT[8:2]} ? SPR_XPOS[8:1] : 8'h00;
	
	// This needs L0_ADDR
	p_cycle PCY(nRESET, CLK_24M, PBUS_S_ADDR, FIX_ATTR_PAL, PBUS_C_ADDR, SPR_TILE_PAL, XPOS,
					L0_ROM_ADDR, nVCS, L0_ROM_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(nRESET, VBLANK, AA_SPEED, SPR_TILE_NB, AA_DISABLE, SPR_ATTR_AA, SPR_TILE_NB_AA, AA_COUNT);
	
	//hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
endmodule

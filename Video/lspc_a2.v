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
	output reg S2H1,
	output S1H1,
	output LOAD, H, EVEN1, EVEN2,	// For ZMC2
	output IPL0, IPL1,
	output TMS0,						// Also called SCH and CHG
	output LD1_, LD2_,				// Buffer address load
	output PCK1, PCK2,
	output [3:0] WE,
	output [3:0] CK,
	input SS1, SS2,					// Buffer pair selection for B1
	output nRESETP,
	output SYNC,
	output CHBL,
	output nBNKB,
	output nVCS,						// LO ROM output enable
	output CLK_8M,
	output CLK_4M,
	output [8:0] H_COUNT				// SIMULATION ONLY
);

	parameter VIDEO_MODE = 1'b0;	// NTSC
	
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
	reg [3:0] SPR_PIXELCNT;			// Sprite render pixel counter for H-shrink
	wire [11:0] SPR_ATTR_SHRINK;
	wire [1:0] SPR_ATTR_AA;			// Auto-animation config bits
	wire [7:0] AA_SPEED;
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	wire WR_PIXEL;
	wire [8:0] SPR_NB;
	wire [4:0] SPR_TILE_IDX;
	wire [1:0] SPR_TILE_FLIP;
	wire [19:0] SPR_TILE_NB;
	wire [19:0] SPR_TILE_NB_AA;	// SPR_ATTR_TILE_NB after auto-animation applied
	wire [7:0] SPR_TILE_PAL;
	wire [3:0] SPR_TILE_LINE;
	wire [8:0] SPR_XPOS;
	
	// Fix stuff
	wire [14:0] FIX_MAP_ADDR;
	wire [11:0] FIX_TILE_NB;
	wire [3:0] FIX_ATTR_PAL;
	
	// Timer stuff
	wire [2:0] TIMER_MODE;
	wire [31:0] TIMER_LOAD;
	wire [15:0] REG_LSPCMODE;
	
	wire [15:0] PBUS_S_ADDR;	// PBUS address for fix ROM
	wire [23:0] PBUS_C_ADDR;	// PBUS address for sprite ROMs
	wire [15:0] L0_ROM_ADDR;
	wire [7:0] L0_ROM_DATA;
	
	reg CA4_Q;
	reg S2H1_Q;
	
	wire K2_1;
	wire K8_6;
	reg BFLIP;
	wire nBFLIP;
	wire SELJ5;
	wire CLK_12M;
	reg nJ8A_Q;
	wire nCLK_12M;
	wire nLATCH_X;
	reg [3:0] CLKDIV_LSPC;
	
	// M8 - Seems to be free-running on Alpha68k ? /MR and /LOAD aren't used
	assign RESETP = ~nRESETP;
	always @(posedge CLK_24M or posedge RESETP)
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
	
	
	assign SYNC = HSYNC ^ nVSYNC;
	
	// CPU access to VRAM ====================================================
	
	assign CPU_WRITE_ACK = CPU_WRITE_ACK_SLOW & CPU_WRITE_ACK_FAST;
	assign CPU_WRITE_ACK_PULSE = CPU_WRITE_ACK & ~CPU_WRITE_ACK_PREV;
	
	always @(posedge CLK_24M)	// negedge ?
	begin
		if (CPU_WRITE_REQ)
			CPU_WRITE <= 1'b1;		// Set
		else
		begin
			if (CPU_WRITE_ACK_PULSE)
				CPU_WRITE <= 1'b0;	// Reset
		end
		
		CPU_WRITE_ACK_PREV <= CPU_WRITE_ACK;
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
	
	always @(posedge CLK_6M)
		S2H1 <= H_COUNT[0] ^ H_COUNT[1];		// ?
	// CA4 should change depending on sprite V-flip attribute
	assign CA4 = ~S2H1;
	
	// CA4	''''|______|''''
	// PCK1	____|'|_________
	always @(posedge CLK_24M)
		CA4_Q <= CA4;
	assign PCK1 = (CA4_Q & !CA4);

	// 2H1	''''|______|''''
	// PCK2	____|'|_________
	always @(posedge CLK_24M)
		S2H1_Q <= S2H1;
	assign PCK2 = (S2H1_Q & !S2H1);
	
	// P bus values
	assign FIX_A4 = H_COUNT[2];		// Seems good, matches Alpha68k
	assign PBUS_S_ADDR = {FIX_A4, V_COUNT[2:0], FIX_TILE_NB};
	assign PBUS_C_ADDR = {SPR_TILE_NB_AA[19:16], SPR_TILE_LINE, SPR_TILE_NB_AA[15:0]};
	
	// Alpha68k stuff:
	
	// Can be inverted by the MCU, apparently not used (cab config ?)
	assign K2_1 = V_COUNT[0];
	
	// K8:A - Signal to select between sprite X position load or X position reset to start clearing LB ?
	assign K8_6 = &{LOAD, H_COUNT[2], H_COUNT[1], SNKCLK22 ^ SNKCLK20};
	
	// K2 - X load signal switch for both LB pairs
	assign K2_4 = K2_1 ? 1'b1 : nLATCH_X;
	assign K2_7 = K2_1 ? nLATCH_X : 1'b1;
	assign K2_9 = K2_1 ? K8_6 : 1'b1;
	assign K2_12 = K2_1 ? 1'b1 : K8_6;
	
	// Needs checking. Might also be the opposite (reverse LD1/LD2)
	// K5:C
	assign LD1_ = K2_7 & K2_12;
	// K5:B
	assign LD2_ = K2_4 & K2_9;
	
	// J8:B
	always @(posedge H_COUNT[1])
		BFLIP <= K2_1;
	assign nBFLIP = !BFLIP;
	
	// M12
	assign RD_A = nBFLIP ? 1'b0 : CLK_LB_READ_CLEAR;
	assign RD_B = nBFLIP ? CLK_LB_READ_CLEAR : 1'b0;
	assign CK[0] = nBFLIP ? nCLK_12M : CLK_LB_READ_CLEAR;	// CLK_EVEN_B
	assign CK[1] = CK[1];	// ?
	assign CK[2] = nBFLIP ? CLK_LB_READ_CLEAR : nCLK_12M;	// CLK_EVEN_A
	assign CK[3] = CK[2];	// ?

	// J8:A
	always @(posedge H_COUNT[1])
		nJ8A_Q <= ~SNKCLK20;

	// K5:A
	assign SW_LB_READ_CLEAR = ~SNKCLK22 & nJ8A_Q;
	
	// J5
	assign CLK_LB_READ_CLEAR = SW_LB_READ_CLEAR ? nCLK_12M : H_COUNT[0];
	assign nWE_LB_CLEAR = SW_LB_READ_CLEAR ? nCLK_12M : 1'b1;
	
	// P6:A & B - Pixel write enables according to opacity
	// Second half of P6 is in B1
	assign nODD_WE = ~(DOTB & CLK_12M);
	assign nEVEN_WE = ~(DOTA & CLK_12M);
	
	// N6 - WE signals to B1 (order might be wrong)
	assign WE[0] = nBFLIP ? nODD_WE : nWE_LB_CLEAR;		// nWE_ODD_A
	assign WE[1] = nBFLIP ? nEVEN_WE : nWE_LB_CLEAR;	// nWE_EVEN_A
	assign WE[2] = nBFLIP ? nWE_LB_CLEAR : nODD_WE;		// nWE_ODD_B
	assign WE[3] = nBFLIP ? nWE_LB_CLEAR : nEVEN_WE;	// nWE_EVEN_B
	
	// J13:D - LOAD signal for ZMC2
	assign LOAD = CLK_6M & H_COUNT[0];
	
	assign IRQ_S3 = VBLANK;		// Timing to check
	
	// TESTING
	// Probably using nRESETP
	snkclk SCLK(CLK_6MB, nRESET, , , , , , , , , , SNKCLK20, SNKCLK22, , , , , , );
	
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
	
	videosync VS(CLK_24M, nRESETP, V_COUNT, H_COUNT, TMS0, VBLANK, nVSYNC, HSYNC, nBNKB, CHBL, FIX_MAP_ADDR);

	odd_clk ODDCLK(CLK_24M, nRESETP, CLK_8M, CLK_4M, CLK_4MB);
	
	slow_cycle SCY(CLK_6M, nRESETP, H_COUNT[1:0], PCK1, PCK2,
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
	
	// This needs L0_ADDR
	p_cycle PCY(nRESET, CLK_24M, PBUS_S_ADDR, FIX_ATTR_PAL, PBUS_C_ADDR, SPR_TILE_PAL, SPR_XPOS[8:1], L0_ROM_ADDR,
					S1H1, nVCS, L0_ROM_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(nRESET, VBLANK, AA_SPEED, SPR_TILE_NB, AA_DISABLE, SPR_ATTR_AA, SPR_TILE_NB_AA, AA_COUNT);
	
	hshrink HSHRINK(SPR_ATTR_SHRINK[11:8], SPR_PIXELCNT, WR_PIXEL);
	
endmodule

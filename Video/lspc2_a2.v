`timescale 1ns/1ns

// All pins listed ok. REF, DIVI and DIVO only used on AES for video PLL hack
// Video mode pin is the VMODE parameter

module lspc2_a2(
	input CLK_24M,
	input RESET,
	output [15:0] PBUS_OUT,
	inout [23:16] PBUS_IO,
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	input LSPOE, LSPWE,
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
	output RESETP,
	output SYNC,
	output CHBL,
	output BNKB,
	output nVCS,						// LO ROM output enable
	output LSPC_8M,
	output LSPC_4M
);

	parameter VMODE = 1'b0;	// NTSC
	
	wire [8:0] RASTERC;
	wire [7:0] AA_SPEED;
	wire [2:0] AA_COUNT;				// Auto-animation tile #
	reg [7:0] WR_DECODED;
	wire [15:0] CPU_DATA_MUX;
	wire [15:0] CPU_DATA_OUT;
	wire [15:0] VRAM_ADDR_RAW;
	wire [15:0] VRAM_READ_LOW;
	wire [15:0] VRAM_READ_HIGH;
	
	wire [15:0] REG_VRAMMOD;
	wire [15:0] REG_LSPCMODE;
	
	
	
	
	// Sprites stuff
	wire [11:0] SPR_ATTR_SHRINK;	// TODO
	wire [1:0] SPR_ATTR_AA;			// Auto-animation config bits
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
	
	
	

	assign S1H1 = LSPC_3M;
	assign S2H1 = LSPC_1_5M;
	
	
	
	
	
	// CPU access to VRAM ====================================================
	
/*
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
	
	// P bus values
	assign FIX_A4 = H_COUNT[2];		// Seems good, matches Alpha68k
	assign PBUS_S_ADDR = {FIX_A4, V_COUNT[2:0], FIX_TILE_NB};
	assign PBUS_C_ADDR = {SPR_TILE_NB_AA[19:16], SPR_TILE_LINE, SPR_TILE_NB_AA[15:0]};*/

	// The fix map is 16bits/tile in slow VRAM starting @ $7000
	// Organized as 32 lines * 64 columns
	// (0)111xCCC CCCLLLLL
	//assign FIX_MAP_ADDR = {4'b1110, H_COUNT[8:3], V_COUNT[7:3]};
	
	// C27: CPU write decode
	always @(*)
	begin
		if (~LSPWE)
		begin
			case (M68K_ADDR)
				3'h0 : WR_DECODED <= 8'b11111110;
				3'h1 : WR_DECODED <= 8'b11111101;
				3'h2 : WR_DECODED <= 8'b11111011;
				3'h3 : WR_DECODED <= 8'b11110111;
				3'h4 : WR_DECODED <= 8'b11101111;
				3'h5 : WR_DECODED <= 8'b11011111;
				3'h6 : WR_DECODED <= 8'b10111111;
				3'h7 : WR_DECODED <= 8'b01111111;
			endcase
		end
		else
			WR_DECODED <= 8'b11111111;
	end
	
	assign WR_VRAM_ADDR = WR_DECODED[0];
	assign WR_VRAM_RW = WR_DECODED[1];
	assign WR_VRAM_MOD = WR_DECODED[2];
	assign WR_LSPC_MODE = WR_DECODED[3];
	assign WR_TIMER_HIGH = WR_DECODED[4];
	assign WR_TIMER_LOW = WR_DECODED[5];
	assign WR_IRQ_ACK = WR_DECODED[6];
	assign WR_TIMER_STOP = WR_DECODED[7];
	
	// CPU reads
	
	assign REG_LSPCMODE = {RASTERC, 3'b0, VMODE, AA_COUNT};
	
	assign CPU_READ = ~|{~|{M68K_ADDR[1], ~M68K_ADDR[2]}, ~|{VRAM_ADDR_RAW[15], M68K_ADDR[2]}};
	
	assign CPU_DATA_MUX = M68K_ADDR[2] ? 
							CPU_READ ? REG_VRAMMOD : REG_LSPCMODE			// Maybe swapped
							:
							CPU_READ ? VRAM_READ_LOW : VRAM_READ_HIGH;	// Maybe swapped
	
	assign C22A_OUT = ~&{WR_VRAM_RW, WR_VRAM_ADDR};
	FDM B18(C22A_OUT, M68K_ADDR[1], B18_Q, );
	
	FDSCell A28(~B18_Q, CPU_DATA_MUX[3:0], CPU_DATA_OUT[3:0]);
	FDSCell A68(~B18_Q, CPU_DATA_MUX[7:4], CPU_DATA_OUT[7:4]);
	FDSCell A123(~B18_Q, CPU_DATA_MUX[11:8], CPU_DATA_OUT[11:8]);
	FDSCell B138(~B18_Q, CPU_DATA_MUX[15:12], CPU_DATA_OUT[15:12]);
	
	
	// CPU write to REG_VRAMMOD
	
	FDSCell G123(~WR_VRAM_MOD, M68K_DATA[3:0], REG_VRAMMOD[3:0]);
	FDSCell F81(~WR_VRAM_MOD, M68K_DATA[7:4], REG_VRAMMOD[7:4]);
	FDSCell G105(~WR_VRAM_MOD, M68K_DATA[11:8], REG_VRAMMOD[11:8]);
	FDSCell H105(~WR_VRAM_MOD, M68K_DATA[15:12], REG_VRAMMOD[15:12]);
	
	
	// CPU write to REG_VRAMADDR
	
	FDSCell C123(~WR_VRAM_ADDR, M68K_DATA[3:0], VRAM_ADDR_RAW[3:0]);
	FDSCell A79(~WR_VRAM_ADDR, M68K_DATA[7:4], VRAM_ADDR_RAW[7:4]);
	FDSCell D87(~WR_VRAM_ADDR, M68K_DATA[11:8], VRAM_ADDR_RAW[11:8]);
	FDSCell F47(~WR_VRAM_ADDR, M68K_DATA[15:12], VRAM_ADDR_RAW[15:12]);
	
	
	// CPU write to REG_LSPCMODE
	
	FDSCell C87(WR_LSPC_MODE, M68K_DATA[11:8], AA_SPEED[3:0]);
	FDSCell E105(WR_LSPC_MODE, M68K_DATA[15:12], AA_SPEED[7:4]);
	
	
	/*lspc_regs REGS(RESET, CLK_24M, M68K_ADDR, M68K_DATA, nLSPOE, nLSPWE, PCK1, AA_COUNT, V_COUNT[7:0],
					VIDEO_MODE, REG_LSPCMODE,
					CPU_VRAM_ZONE, CPU_WRITE_REQ, CPU_VRAM_ADDR, CPU_VRAM_WRITE_BUFFER,
					RELOAD_REQ_SLOW, RELOAD_REQ_FAST,
					TIMER_LOAD, TIMER_PAL_STOP, REG_VRAMMOD, TIMER_MODE, TIMER_IRQ_EN,
					AA_SPEED, AA_DISABLE,
					IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3);*/
	
	//lspc_timer TIMER(RESET, CLK_6M_LSPC, VBLANK, VIDEO_MODE, TIMER_MODE, TIMER_INT_EN, TIMER_LOAD,
	//						TIMER_PAL_STOP, V_COUNT);
	
	resetp RSTP(CLK_24MB, RESET, RESETP);
	
	irq IRQ(WR_IRQ_ACK, M68K_DATA[2:0], BNK, LSPC_6M, IPL0, IPL1);
	
	videosync VS(CLK_24MB, LSPC_1_5M, Q53_CO, RESETP, VMODE, , RASTERC, SYNC, BNK, BNKB, CHBL);

	lspc2_clk LSPCCLK(CLK_24M, RESETP, CLK_24MB, LSPC_12M, LSPC_8M, LSPC_6M, LSPC_4M, LSPC_3M, LSPC_1_5M,
							Q53_CO);
	
	/*slow_cycle SCY(CLK_24M, CLK_6M, RESETP, H_COUNT[1:0], PCK1, PCK2,
					FIX_MAP_ADDR, FIX_TILE_NB, FIX_ATTR_PAL,
					SPR_NB, SPR_TILE_IDX, SPR_TILE_NB,
					SPR_TILE_PAL, SPR_ATTR_AA, SPR_TILE_FLIP,
					REG_VRAMMOD[14:0], RELOAD_REQ_SLOW,
					CPU_VRAM_ADDR, CPU_VRAM_READ_BUFFER_SCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_WRITE, CPU_WRITE_ACK_SLOW);
	
	// Todo: this needs to give L0_ADDR
	// Todo: this needs L0_DATA (from P bus)
	fast_cycle FCY(CLK_24M, RESETP,
					V_COUNT, CHBL, BFLIP,
					SPR_XPOS, SPR_NB, SPR_TILE_IDX, SPR_TILE_LINE, SPR_ATTR_SHRINK,
					REG_VRAMMOD[10:0], RELOAD_REQ_FAST,
					CPU_VRAM_ADDR[10:0], CPU_VRAM_READ_BUFFER_FCY, CPU_VRAM_WRITE_BUFFER,
					CPU_VRAM_ZONE, CPU_WRITE, CPU_WRITE_ACK_FAST);*/
	
	// Briefly set XPOS to 0 to reset the line buffer address counters in B1, for output to TV
	// This probably doesn't work that way
	//assign XPOS = |{H_COUNT[8:2]} ? SPR_XPOS[8:1] : 8'h00;
	
	// This needs L0_ADDR
	//p_cycle PCY(RESET, CLK_24M, PBUS_S_ADDR, FIX_ATTR_PAL, PBUS_C_ADDR, SPR_TILE_PAL, XPOS,
	//				L0_ROM_ADDR, nVCS, L0_ROM_DATA, {PBUS_IO, PBUS_OUT});
	
	autoanim AA(RASTERC[8], RESETP, AA_SPEED, AA_COUNT);
	
	hshrink HSH(HSHRINK, , , , );
	
endmodule

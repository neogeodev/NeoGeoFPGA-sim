`timescale 1ns/1ns

module slow_cycle(
	input CLK_24M,
	input nRESETP,
	
	input [1:0] H_COUNT,
	input PCK1,
	input PCK2,
	
	input [5:0] FIX_MAP_COL,
	input [7:3] V_COUNT,
	input [8:0] SPR_NB,					// Sprite number being rendered (0~381 ?)
	input [4:0] SPR_TILEIDX,			// Tile index in sprite (0~31)
	output [19:0] SPR_TILE_NB,
	output reg [7:0] SPR_ATTR_PAL,	// Todo: Probaby just wires
	output reg [1:0] SPR_ATTR_AA,
	output reg [1:0] SPR_ATTR_FLIP,	// Todo: H flip goes to ZMC2
	output reg [11:0] FIX_TILE_NB,
	output reg [3:0] FIX_PAL_NB,
	
	input [14:0] REG_VRAMMOD,
	input RELOAD_REQ,
	
	input [14:0] CPU_ADDR,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_ZONE,
	input CPU_WRITE,
	output CPU_WRITE_ACK
);

	reg [14:0] CPU_ADDR_SLOW;
	reg SPR_ADDR_LSB;
	wire [14:0] SPR_ADDR_SLOW;
	wire [14:0] FIX_ADDR_SLOW;
	
	reg [3:0] SPR_TILE_NB_U;
	reg [15:0] SPR_TILE_NB_L;
	
	wire [14:0] B;		// Slow VRAM address
	wire [15:0] E;		// Slow VRAM data
	wire nBOE;
	reg nBWE;
	
	wire [4:0] FIX_MAP_LINE;
	
	reg [1:0] CYCLE_SLOW;
	reg RELOAD_CPU_ADDR;
	
	vram_slow_u VRAMLU(B, E[15:8], 1'b0, nBOE, nBWE);
	vram_slow_l VRAMLL(B, E[7:0], 1'b0, nBOE, nBWE);
	
	always @(posedge RELOAD_REQ or posedge (&{CYCLE_SLOW[1:0]}))
	begin
		if (RELOAD_REQ)
			RELOAD_CPU_ADDR <= 1'b1;
		else
			RELOAD_CPU_ADDR <= 1'b0;
	end
	
	// The fix map is 16bit/tile in slow VRAM starting @ $7000
	// 0 111 0CCC CCCL LLLL
	assign FIX_MAP_LINE = V_COUNT[7:3];		// Fix renders only for the first 256 lines (not during vblank ?)
	
	always @(posedge CLK_24M)
	begin
		// Time slot change on PCK* signals seems to fit in well,
		// but not sure how the FIXMAP and SPRMAP 2nd word are triggered
		CYCLE_SLOW <= H_COUNT[1:0];
		
		if (PCK1)						// Sprite map first word
		begin
			SPR_ADDR_LSB <= 1'b0;	// This might not be a register
		end
		
		if (H_COUNT[1:0] == 2'd1)	// Sprite map second word
		begin
			SPR_ADDR_LSB <= 1'b1;	// This might not be a register
		end
		
		if (PCK2)						// CPU
		begin
			if (RELOAD_CPU_ADDR) CPU_ADDR_SLOW <= CPU_ADDR;
			nBWE <= ~(CPU_WRITE & ~CPU_ZONE);
		end
		
		if (H_COUNT[1:0] == 2'd3)	// Fix map
		begin
			if (!nBWE)
				CPU_ADDR_SLOW <= CPU_ADDR_SLOW + REG_VRAMMOD;
			nBWE <= 1'b1;
		end
	end
	
	// Red sprite map 1st word 0.5mclk before new cycle. Should be ok.
	always @(posedge (~H_COUNT[1] & H_COUNT[0]))
	begin
		SPR_TILE_NB_L <= E;
	end
	
	// Read sprite map 2nd word
	always @(posedge PCK2)
	begin
		SPR_ATTR_PAL <= E[15:8];
		SPR_TILE_NB_U <= E[7:4];
		SPR_ATTR_AA <= E[3:2];
		SPR_ATTR_FLIP <= E[1:0];
	end
	
	// Read data for CPU 0.5mclk before new cycle. Should be ok.
	always @(posedge (&{H_COUNT[1:0]}))
	begin
		CPU_RDDATA <= E;
	end
	
	// Read fix map
	always @(posedge PCK1)
	begin
		FIX_TILE_NB <= E[11:0];
		FIX_PAL_NB <= E[15:12];
	end
	
	// SPR_TILEIDX   /------- --xxxxx! [4:0]
	// SPR_NB        /xxxxxxx xx-----! [8:0]
	assign SPR_ADDR_SLOW = {SPR_NB, SPR_TILEIDX, SPR_ADDR_LSB};
	assign FIX_ADDR_SLOW = {4'b1110, FIX_MAP_COL, FIX_MAP_LINE};
	
	assign B = (CYCLE_SLOW[1] == 1'b0) ? SPR_ADDR_SLOW :		// SPR
						(CYCLE_SLOW == 2'd2) ? CPU_ADDR_SLOW :		// CPU
						FIX_ADDR_SLOW;										// FIX

	assign E = nBWE ? 16'bzzzzzzzzzzzzzzzz : CPU_WRDATA;
	
	// TODO: An OE signal is used for slow VRAM, but not for fast VRAM. What's up with that ? Shared internal bus ?
	assign nBOE = ~nBWE;
	
	assign CPU_WRITE_ACK = nBWE;	// Works but probably wrong

	assign SPR_TILE_NB = {SPR_TILE_NB_U, SPR_TILE_NB_L};

endmodule

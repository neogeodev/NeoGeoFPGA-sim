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
	input [4:0] SPR_TILEIDX,			// Sprite tile index (0~31)
	output [19:0] SPR_ATTR_TILENB,
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
	wire [14:0] B;		// Slow VRAM address
	wire [15:0] E;		// Slow VRAM data
	wire nBOE;
	reg nBWE;
	
	wire [4:0] FIX_MAP_LINE;
	
	reg [1:0] CYCLE_SLOW;
	reg RELOAD_CPU_ADDR;
	
	vram_slow_u VRAMLU(B, E[15:8], 1'b0, nBOE, nBWE);
	vram_slow_l VRAMLL(B, E[7:0], 1'b0, nBOE, nBWE);
	
	always @(posedge RELOAD_REQ or posedge CYCLE_SLOW[1])
	begin
		if (RELOAD_REQ)
			RELOAD_CPU_ADDR <= 1'b1;
		else
			RELOAD_CPU_ADDR <= 1'b0;
	end
	
	// Slow VRAM latches
	always @(posedge PCK1)				// Good ?
	begin
		FIX_TILE_NB <= E[11:0];
		FIX_PAL_NB <= E[15:12];
	end
	
	// The fix map is 16bit/tile in slow VRAM starting @ $7000
	// 0 111 0CCC CCCL LLLL
	assign FIX_MAP_LINE = V_COUNT[7:3];		// Fix renders only for the first 256 lines (not during vblank ?)
	
	always @(posedge CLK_24M)
	begin
		// Timing cycle change on PCK* signals seems to fit in well, but not sure how the FIXMAP is triggered
		if (PCK1)
			CYCLE_SLOW <= 2'd0;		// SPRMAP
		
		if (PCK2)
		begin
			CYCLE_SLOW <= 2'd1;		// CPU
			if (RELOAD_CPU_ADDR) CPU_ADDR_SLOW <= CPU_ADDR;
			nBWE <= ~(CPU_WRITE & ~CPU_ZONE);
		end
		
		if (H_COUNT[1:0] == 2'd3)
		begin
			CYCLE_SLOW <= 2'd2;		// FIXMAP
			if (!nBWE)
				CPU_ADDR_SLOW <= CPU_ADDR_SLOW + REG_VRAMMOD;
			nBWE <= 1'b1;
		end
	end
	
	// Terrible.
	always @(posedge CYCLE_SLOW[1])
	begin
		CPU_RDDATA <= E;
	end
	
	assign CPU_WRITE_ACK = nBWE;	// Does this work ?
	
	assign B = (CYCLE_SLOW == 2'd0) ? 15'bzzzzzzzzzzzzzzz :		// SPR: Todo
						(CYCLE_SLOW == 2'd1) ? CPU_ADDR_SLOW :			// CPU
						{4'b1110, FIX_MAP_COL, FIX_MAP_LINE};			// FIX




	// Guesswork:
	// Slow VRAM is 120ns, so at least 3mclk needed between address set and data valid
	
	reg [3:0] SPR_TILENB_U;
	reg [15:0] SPR_TILENB_L;
	wire [13:0] SPRVRAM_ADDR;	// LSB added later for even/odd word selection
	
	
	// TODO: An OE signal is used for slow VRAM, but not for fast VRAM. What's up with that ? Shared internal bus ?
	assign nBOE = ~nBWE;

	//assign B = {SPRVRAM_ADDR, CYCLE_SLOW[3]};		// 0100~1011 (8)	Is LSB good ?
	
	assign E = nBWE ? 16'bzzzzzzzzzzzzzzzz : CPU_WRDATA;
	
	
	assign SPR_ATTR_TILENB = {SPR_TILENB_U, SPR_TILENB_L};
	
	// SPR_TILEIDX   /------- --xxxxx! [4:0]
	// SPR_NB        /xxxxxxx xx-----! [8:0]
	assign SPRVRAM_ADDR = {SPR_NB, SPR_TILEIDX};
	
	/*always @(posedge CLK_24M)
	begin
		if (!nRESETP)
		begin
			CYCLE_SLOW <= 0;	// Resync cycle just on reset pulse (cycle continues during reset, right ?)
		end
		else
		begin
			case (CYCLE_SLOW)
				4'd6 :
				begin
					// End of SPR map cycle A (should be 7 ?)
					SPR_TILENB_L <= E;
				end
				4'd10 :
				begin
					// End of SPR map cycle B (should be 11 ?)
					SPR_ATTR_PAL <= E[15:8];
					SPR_TILENB_U <= E[7:4];
					SPR_ATTR_AA <= E[3:2];
					SPR_ATTR_FLIP <= E[1:0];
				end
				4'd11 :
				begin
					if (!CPU_RW_LATCHED)
						CPU_RW_LATCHED <= 1'b1;		// Do writes only once. Ugly, probably simpler.
					else
						CPU_RW_LATCHED <= CPU_RW;	// Avoids CPU_RW changing during VRAM CPU access cycle (not verified on hw)
				end
				4'd14 :
				begin
					// End of CPU cycle (should be 15 ?)
					if (CPU_RW_LATCHED)
						CPU_RDDATA <= E;	// Read: latch data
				end
			endcase
			
			CYCLE_SLOW <= CYCLE_SLOW + 1'b1;
		end
	end*/

endmodule

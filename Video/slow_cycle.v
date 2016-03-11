`timescale 1ns/1ns

module slow_cycle(
	input CLK_24M,
	
	input HSYNC,
	input [8:0] HCOUNT,					// Todo: Should be [8:3] only, [2:0] for dirty sync hack
	input [7:3] VCOUNT,
	input [8:0] SPR_NB,					// Sprite number being rendered
	input [4:0] SPR_TILEIDX,			// Sprite tile index
	output [19:0] SPR_ATTR_TILENB,
	output reg [7:0] SPR_ATTR_PAL,	// Todo: Probaby just wires
	output reg [1:0] SPR_ATTR_AA,
	output reg [1:0] SPR_ATTR_FLIP,	// Todo: H flip goes to ZMC2
	output [11:0] FIX_ATTR_TILENB,
	output reg [3:0] FIX_ATTR_PAL,
	
	input [14:0] CPU_ADDR,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_PENDING,
	input CPU_ZONE,
	input CPU_RW
);

	// Guesswork:
	// Slow VRAM is 120ns, so at least 3mclk needed between address set and data valid
	// Certainly 4x 4mclk slots: Fix, Sprite even, Sprite odd, CPU (in whatever order)

	// Todo: CPU access if pending=1, zone=0
	// Are reads done just when changing address ?

	// 4 cycles of CLK_6M corresponds to 16 cycles of CLK_24M, so...
	reg [3:0] CYCLE_SLOW;
	
	reg [3:0] SPR_TILENB_U;
	reg [15:0] SPR_TILENB_L;

	wire [14:0] B;		// Low VRAM address
	wire [15:0] E;		// Low VRAM data
	
	wire [14:0] FIXVRAM_ADDR;
	wire [13:0] SPRVRAM_ADDR;	// LSB added later for even/odd word selection
	
	wire nBOE;
	
	// Todo: An OE signal is used for slow VRAM, but not for fast VRAM. What's up with that ? Shared E bus ?

	assign nBOE = 1'b0;

	vram_slow_u VRAMLU(B, E[15:8], nBWE, nBOE, 1'b0);
	vram_slow_l VRAMLL(B, E[7:0], nBWE, nBOE, 1'b0);

	// Todo: This is all wrong ! (shifting needed, should be way simpler)
	// Warning: Update this according to cycle order if changed !			
	assign B = (CYCLE_SLOW == 14) ? FIXVRAM_ADDR :
					(CYCLE_SLOW == 15) ? FIXVRAM_ADDR :
					(CYCLE_SLOW == 0) ? FIXVRAM_ADDR :
					(CYCLE_SLOW == 1) ? FIXVRAM_ADDR :
					(CYCLE_SLOW == 2) ? CPU_ADDR :
					(CYCLE_SLOW == 3) ? CPU_ADDR :
					(CYCLE_SLOW == 4) ? CPU_ADDR :
					(CYCLE_SLOW == 5) ? CPU_ADDR :
					(CYCLE_SLOW == 6) ? {SPRVRAM_ADDR, 1'b0} :
					(CYCLE_SLOW == 7) ? {SPRVRAM_ADDR, 1'b0} :
					(CYCLE_SLOW == 8) ? {SPRVRAM_ADDR, 1'b0} :
					(CYCLE_SLOW == 9) ? {SPRVRAM_ADDR, 1'b0} :
					{SPRVRAM_ADDR, 1'b1};
	
	assign SPR_ATTR_TILENB = {SPR_TILENB_U, SPR_TILENB_L};

	// Todo: Check cycles order, 3 reads needed, 1 access slot for CPU ?
	
	// Fix map x,y = VRAM address:
	// 0,0 = 7000
	// 39,31 = 74FF
	// 47,31 = 75FF (Rendering actually never stops: 48*8 = 384 ! NEO-CMC chip exploits this)
	
	// Fix map address:
	// ((HCOUNT / 8) << 5) | ((VCOUNT & 255) / 8) | $7000
	// 01110HHHHHHVVVVV
	
	// Wrong, same sync hack
	// Todo: should just be HCOUNT[8:3], VCOUNT[7:3]
	wire [8:0] DEBUG_HCOUNT;
	assign DEBUG_HCOUNT = (HCOUNT == 9'd383) ? 9'd0 : HCOUNT + 9'd1;
	assign FIXVRAM_ADDR = {4'b1110, DEBUG_HCOUNT[8:3], VCOUNT[7:3]};
	
	// SPR_TILEIDX   /------- --xxxxx! [4:0]
	// SPR_NB        /xxxxxxx xx-----! [8:0]
	assign SPRVRAM_ADDR = {SPR_NB, SPR_TILEIDX};

	// This doesn't seem/need to be registered, gated in p_cycle.v
	assign FIX_ATTR_TILENB = E[11:0];
	
	always @(posedge CLK_24M)
	begin
		if (HSYNC)
		begin
			CYCLE_SLOW <= 0;
		end
		else
		begin
			// Todo: Wrong.
			// Should switch case always when bits1:0 == 3 (3rd mclk, lets VRAM reply in time after address set)
			CYCLE_SLOW <= CYCLE_SLOW + 1;
			case (CYCLE_SLOW)
				4'd0 :
				begin
					// Should match PCK2 ?
					FIX_ATTR_PAL <= E[15:12];
				end
				4'd4 :
				begin
					// CPU access here ?
				end
				4'd8 :
				begin
					// Todo
					SPR_TILENB_L <= E;
				end
				4'd12 :
				begin
					// Todo
					SPR_ATTR_PAL <= E[15:8];
					SPR_TILENB_U <= E[7:4];
					SPR_ATTR_AA <= E[3:2];
					SPR_ATTR_FLIP <= E[1:0];
				end
			endcase
		end
	end

endmodule

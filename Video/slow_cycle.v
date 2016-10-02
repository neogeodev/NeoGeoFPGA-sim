`timescale 1ns/1ns

module slow_cycle(
	input CLK_24M,
	input nRESETP,
	
	input [8:0] HCOUNT,					// Todo: Should be [8:3] only, [2:0] for dirty sync hack
	input [7:3] VCOUNT,
	input [8:0] SPR_NB,					// Sprite number being rendered (0~381 ?)
	input [4:0] SPR_TILEIDX,			// Sprite tile index (0~31)
	output [19:0] SPR_ATTR_TILENB,
	output reg [7:0] SPR_ATTR_PAL,	// Todo: Probaby just wires
	output reg [1:0] SPR_ATTR_AA,
	output reg [1:0] SPR_ATTR_FLIP,	// Todo: H flip goes to ZMC2
	output [11:0] FIX_ATTR_TILENB,
	output reg [3:0] FIX_ATTR_PAL,
	
	input [14:0] CPU_ADDR_WR,
	input [14:0] CPU_ADDR_RD,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_ZONE,
	input CPU_RW
);

	// Guesswork:
	// Slow VRAM is 120ns, so at least 3mclk needed between address set and data valid

	// Todo: CPU access if zone=0

	// 4 cycles of CLK_6M corresponds to 16 cycles of CLK_24M, so...
	reg [3:0] CYCLE_SLOW;
	
	reg [3:0] SPR_TILENB_U;
	reg [15:0] SPR_TILENB_L;
	
	reg CPU_RW_LATCHED;

	wire [14:0] B;		// Low VRAM address
	wire [15:0] E;		// Low VRAM data
	
	wire [14:0] FIXVRAM_ADDR;
	wire [13:0] SPRVRAM_ADDR;	// LSB added later for even/odd word selection
	
	wire nBWE;
	wire nBOE;
	
	assign nBWE = (CPU_RW_LATCHED | CPU_ZONE | ~&{CYCLE_SLOW[3:2]});		// TODO: Verify on hw
	// TODO: An OE signal is used for slow VRAM, but not for fast VRAM. What's up with that ? Shared internal bus ?
	assign nBOE = ~(CPU_RW_LATCHED | CPU_ZONE | ~&{CYCLE_SLOW[3:2]});	// TODO: Verify on hw

	vram_slow_u VRAMLU(B, E[15:8], 1'b0, nBOE, nBWE);
	vram_slow_l VRAMLL(B, E[7:0], 1'b0, nBOE, nBWE);

	// Not sure if all of this is right...
	// Cycle order is good at least: FIX, SPR, SPR, CPU
	assign B = (CYCLE_SLOW[3:2] == 2'b00) ? FIXVRAM_ADDR :	// 0000~0011 (4)
					(CYCLE_SLOW[3:2] == 2'b11) ?						// 1100~1111 (4)
						(CPU_RW_LATCHED) ? CPU_ADDR_RD : CPU_ADDR_WR :
					{SPRVRAM_ADDR, CYCLE_SLOW[3]};					// 0100~1011 (8)	Is LSB right ?
	
	assign E = ((CYCLE_SLOW[3:2] == 2'b11) && ~(CPU_RW_LATCHED | CPU_ZONE)) ? CPU_WRDATA : 16'bzzzzzzzzzzzzzzzz;
	
	assign SPR_ATTR_TILENB = {SPR_TILENB_U, SPR_TILENB_L};
	
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
		if (!nRESETP)
		begin
			CYCLE_SLOW <= 0;	// Resync cycle just on reset pulse (cycle continues during reset, right ?)
		end
		else
		begin
			case (CYCLE_SLOW)
				4'd2 :
				begin
					// End of FIX map cycle (should be 3 ?)
					// Should match PCK2 ?
					FIX_ATTR_PAL <= E[15:12];	// Maybe no latch required here, as with FIX_ATTR_TILENB ?
				end
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
	end

endmodule

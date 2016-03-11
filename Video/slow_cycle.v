`timescale 1ns/1ns

module slow_cycle(
	input CLK_24M,
	
	input HSYNC,
	input [8:0] HCOUNT,	// Todo: Should be [8:3] only
	input [7:3] VCOUNT,
	input [8:0] SPR_NB,
	input [4:0] SPR_IDX,
	output [19:0] SPR_ATTR_TILENB,
	output reg [7:0] SPR_ATTR_PAL,
	output reg [1:0] SPR_ATTR_AA,
	output reg [1:0] SPR_ATTR_FLIP,
	output [11:0] FIX_ATTR_TILENB,
	output reg [3:0] FIX_ATTR_PAL,
	
	input [14:0] CPU_ADDR,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_PENDING,
	input CPU_ZONE,
	input CPU_RW
);

	// Todo: CPU access if pending=1, zone=0
	// Are reads done when changing address ? Maybe this is clocked by 12M or 24M

	reg [3:0] CYCLE_SLOW;	// 4 cycles of CLK_6M corresponds to 16 cycles of CLK_24M

	wire [14:0] B;		// Low VRAM address
	wire [15:0] E;		// Low VRAM data
	
	wire [14:0] FIXVRAM_ADDR;
	wire [13:0] SPRVRAM_ADDR;
	
	reg [3:0] SPR_TILENB_U;
	reg [15:0] SPR_TILENB_L;

	// This is all wrong ! (shifting needed)
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

	// FIX tile
	//		FIX pal (already have it)
	// SPR tile
	// SPR pal
	
	// TODO: Check cycles order, 3 reads needed, 1 access slot for CPU ?
	
	// 0,0 = 7000
	// 0,1 = 7001
	// 1,0 = 7020
	// 39,31 = 74FF (Normally)
	// 47,31 = 75FF (NEO-CMC exploits this !)
	
	// ((HCOUNT / 8) << 5) | ((VCOUNT & 255) / 8)
	// 1110HHHHHHVVVVV
	
	//     !
	// xxxx0111 xxxx0110
	// xxxx1000 xxxx0111
	wire [8:0] DEBUG_HCOUNT;
	assign DEBUG_HCOUNT = (HCOUNT == 9'd383) ? 9'd0 : HCOUNT + 9'd1;
	assign FIXVRAM_ADDR = {4'b1110, DEBUG_HCOUNT[8:3], VCOUNT[7:3]};	// Todo: should just be HCOUNT[8:3],VCOUNT[7:3]
	
	// SPR_IDX   /------- --xxxxx! [4:0]
	// SPR_NB    /xxxxxxx xx-----! [8:0]
	assign SPRVRAM_ADDR = {SPR_NB, SPR_IDX};

	assign FIX_ATTR_TILENB = E[11:0];	// This doesn't seem/need to be registered, gated in p_cycle.v
	
	always @(posedge CLK_24M)		// negedge CLK_6M
	begin
		if (HSYNC)
		begin
			CYCLE_SLOW <= 0;
		end
		else
		begin
			// Todo, check bits1:0 == 1 and switch with bits3:2
			CYCLE_SLOW <= CYCLE_SLOW + 1;
			case (CYCLE_SLOW)
				4'd0 :
				begin
					// Should match PCK2
					FIX_ATTR_PAL <= E[15:12];
				end
				4'd4 :
				begin
					// CPU access R/W ?
				end
				4'd8 :
				begin
					SPR_TILENB_L <= E;
				end
				4'd12 :
				begin
					SPR_ATTR_PAL <= E[15:8];
					SPR_TILENB_U <= E[7:4];
					SPR_ATTR_AA <= E[3:2];
					SPR_ATTR_FLIP <= E[1:0];
				end
			endcase
		end
	end
	
	assign nBOE = 1'b0;

	vram_slow_u VRAMLU(B, E[15:8], nBWE, nBOE, 1'b0);
	vram_slow_l VRAMLL(B, E[7:0], nBWE, nBOE, 1'b0);

endmodule

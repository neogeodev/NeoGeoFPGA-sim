`timescale 10ns/10ns

module slow_cycle(
	input CLK_6M,
	
	input [8:3] HCOUNT,
	input [7:3] VCOUNT,
	input [8:0] SPR_NB,
	input [4:0] SPR_IDX,
	output [19:0] SPR_ATTR_TILENB,
	output reg [7:0] SPR_ATTR_PAL,
	output reg [1:0] SPR_ATTR_AA,
	output reg [1:0] SPR_ATTR_FLIP,
	output reg [11:0] FIX_ATTR_TILENB,
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

	reg [1:0] CYCLE;	// 4 cycles of CLK_6M corresponds to 16 cycles of CLK_24M

	wire [14:0] B;		// Low VRAM address
	wire [15:0] E;		// Low VRAM data
	
	wire [13:0] FIXVRAM_ADDR;
	wire [14:0] SPRVRAM_ADDR;
	
	reg [3:0] SPR_TILENB_U;
	reg [15:0] SPR_TILENB_L;
	
	// Warning: Update this according to cycle order if changed !
	assign B = (CYCLE == 0) ? CPU_ADDR :
					(CYCLE == 1) ? {SPRVRAM_ADDR, 1'b0} :
					(CYCLE == 2) ? {SPRVRAM_ADDR, 1'b1} :
					FIXVRAM_ADDR;
	
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
	assign FIXVRAM_ADDR = {4'b1110, HCOUNT[8:3], VCOUNT[7:3]};
	
	// SPR_IDX   /------- --xxxxx! [4:0]
	// SPR_NB    /xxxxxxx xx-----! [8:0]
	assign SPRVRAM_ADDR = {SPR_NB, SPR_IDX};
	
	always @(posedge CLK_6M)		// negedge ?
	begin
		CYCLE <= CYCLE + 1;
		case (CYCLE)
			0 :
			begin
				FIX_ATTR_PAL <= E[15:12];
				FIX_ATTR_TILENB <= E[11:0];
			end
			1 :
			begin
				// CPU access R/W ?
			end
			2 :
			begin
				SPR_TILENB_L <= E;
			end
			3 :
			begin
				SPR_ATTR_PAL <= E[15:8];
				SPR_TILENB_U <= E[7:4];
				SPR_ATTR_AA <= E[3:2];
				SPR_ATTR_FLIP <= E[1:0];
			end
		endcase
	end

	vram_slow_u VRAMLU(B, E[15:8], nBWE, nBOE, 1'b0);
	vram_slow_l VRAMLL(B, E[7:0], nBWE, nBOE, 1'b0);

endmodule

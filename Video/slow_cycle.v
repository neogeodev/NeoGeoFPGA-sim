`timescale 1ns/1ns

// Slow VRAM is 120ns (3mclk or more, probably 3.5mclk)

module slow_cycle(
	input CLK_24M,
	input RESETP,
	input [14:0] VRAM_ADDR,
	input [15:0] VRAM_WRITE,
	input [7:3] RASTERC,
	input [3:0] PIXEL_HPLUS,
	input [7:0] ACTIVE_RD,
	input [3:0] SPR_TILEMAP
);

	wire [14:0] B;
	wire [15:0] E;
	wire [15:0] VRAM_LOW_WRITE;
	wire [15:0] FIX_MAP_READ;
	wire [11:0] FIX_TILE;
	wire [3:0] FIX_PAL;
	wire [19:0] SPR_TILE;
	wire [7:0] SPR_PAL;

	// CPU read
	// H251 F269 F250 D214
	FDS16bit H251(~CLK_CPU_READ_LOW, E, VRAM_LOW_READ);

	// Fix map read
	// E233 C269 B233 B200
	FDS16bit E233(~CLK_FIX_TILE, E, FIX_MAP_READ);
	assign FIX_TILE = FIX_MAP_READ[11:0];
	FDSCell E251(CLK_SPR_TILE, FIX_MAP_READ[15:12], FIX_PAL);
	
	// Sprite map read even
	// H233 C279 B250 C191
	FDS16bit H233(CLK_SPR_TILE, E, SPR_TILE[15:0]);
	
	// Sprite map read even
	// D233 D283 A249 C201
	FDS16bit D233(~P201_QA, E, {D233_Q, D283_Q, SPR_TILE[19:16], SPR_AA_3, SPR_AA_2, SPR_TILE_VFLIP, SPR_TILE_HFLIP});
	FDSCell C233(~CLK_FIX_TILE, D233_Q, SPR_PAL[7:4]);
	FDSCell D269(~CLK_FIX_TILE, D283_Q, SPR_PAL[3:0]);
	
	assign E = VRAM_LOW_WRITE ? VRAM_WRITE : 16'bzzzzzzzzzzzzzzzz;
	
	// BOE and BWE outputs
	FD2 Q220(CLK_24MB, Q106_QX, Q220_Q, BOE);
	FD2 R289(LSPC_12M, R287A_OUT, BWE, R289_nQ);
	assign R287A_OUT = Q220_Q | R289_nQ;
	
	
	// Address mux
	// E54A F34 F30A
	// F39A J31A H39A H75A
	// F206A I75A E146A N177
	// N179A N182 N172A K169A
	assign B = ~N165_nQ ?
					~N160_Q ? VRAM_ADDR : FIXMAP_ADDR
					:
					~N160_Q ? 15'd0 : SPRMAP_ADDR;
	
	assign FIXMAP_ADDR = {4'b1110, O62_nQ, PIXEL_HPLUS, ~PIXEL_H8, RASTERC[7:3]};
	assign SPRMAP_ADDR = {H57_Q, ACTIVE_RD, O185_Q, SPR_TILEMAP, K166_Q};
	
	FDM O185(P222A_OUT, S182A_OUT, O185_Q);
	FDM H57(N98_QA, I148_Q, H57_Q, );
	FDM K166(CLK_24M, P210A_OUT, K166_Q, );
	FDM N165(CLK_24M, Q174B_OUT, , N165_nQ);
	FDM N160(CLK_24M, N169A_OUT, N160_Q, );
	
	FDPCell O62(PIXEL_H8, P49A_OUT, 1'b1, RESETP, O62_Q, O62_nQ);
	
	
	
	vram_slow_u VRAMLU(B, E[15:8], 1'b0, BOE, BWE);
	vram_slow_l VRAMLL(B, E[7:0], 1'b0, BOE, BWE);

endmodule

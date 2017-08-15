`timescale 1ns/1ns

module autoanim(
	input nRESET,
	input VBLANK,
	input [7:0] AA_SPEED,
	input [19:0] SPR_TILE_NB,
	input AA_DISABLE,
	input [1:0] AA_ATTR,
	output [19:0] SPR_TILE_NB_AA,
	output reg [2:0] AA_COUNT			// Output used for REG_LSPCMODE read
);

	reg [7:0] AA_TIMER;
	wire [2:0] TILE_NB_MUX;

	assign SPR_TILE_NB_AA = {SPR_TILE_NB[19:3], TILE_NB_MUX};

	assign TILE_NB_MUX = AA_DISABLE ? SPR_TILE_NB[2:0] :						// nnn	AA disabled
								AA_ATTR[1] ? AA_COUNT :									// AAA	3-bit AA
								AA_ATTR[0] ? {SPR_TILE_NB[2], AA_COUNT[1:0]} :	// nAA	2-bit AA
								SPR_TILE_NB[2:0];											// nnn	Tile attribute: no AA
	
	// Todo: Is is really nRESET ?
	// Todo: posedge VBLANK ?
	// Verified: Always runs
	// Verified: Reload only happens when AA_TIMER underflows
	always @(negedge nRESET or posedge VBLANK)
	begin
		if (nRESET)
		begin
			AA_COUNT <= 3'd0;
			AA_TIMER <= 8'd0;
		end
		else
		begin
			if (AA_TIMER)
				AA_TIMER <= AA_TIMER - 1'b1;
			else
			begin
				AA_TIMER <= AA_SPEED;		// Reload
				AA_COUNT <= AA_COUNT + 1'b1;
			end
		end
	end

endmodule

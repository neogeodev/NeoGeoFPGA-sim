`timescale 1ns/1ns

module autoanim(
	input VBLANK,
	input [7:0] AASPEED,
	input [19:0] TILENB_IN,
	input AA_DISABLE,
	input [1:0] AA_ATTR,
	output [19:0] TILENB_OUT,
	output reg [2:0] AACOUNT
);

	reg [7:0] AATIMER;

	assign TILENB_OUT = AA_DISABLE ? TILENB_IN :									// nnnnnnnnnnnnnnnnnnnn	No AA
								AA_ATTR[1] ? {TILENB_IN[19:3], AACOUNT} :			// nnnnnnnnnnnnnnnnnAAA	3-bit AA
								AA_ATTR[0] ? {TILENB_IN[19:2], AACOUNT[1:0]} :	// nnnnnnnnnnnnnnnnnnAA	2-bit AA
								TILENB_IN;
	
	always @(posedge VBLANK)
	begin
		if (AATIMER)
			AATIMER <= AATIMER + 1'b1;
		else
		begin
			AATIMER <= AASPEED;
			AACOUNT <= AACOUNT + 1'b1;
		end
	end

endmodule

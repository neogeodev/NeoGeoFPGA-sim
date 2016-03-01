`timescale 10ns/10ns

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
	
	// nnnnnnnnnnnnnnnnnAAA
	// nnnnnnnnnnnnnnnnnnAA
	assign TILENB_OUT = AA_DISABLE ? TILENB_IN :
								AA_ATTR[1] ? {TILENB_IN[19:3], AACOUNT} :
								AA_ATTR[0] ? {TILENB_IN[19:2], AACOUNT[1:0]} :
								TILENB_IN;
	
	// Is the AA counter always enabled ?
	always @(posedge VBLANK)
	begin
		if (AATIMER)
			AATIMER <= AATIMER + 1;
		else
		begin
			AATIMER <= AASPEED;
			AACOUNT <= AACOUNT + 1;
		end
	end

endmodule

`timescale 1ns/1ns

module linebuffer(
	input CK,
	input WE,
	input nLDX,
	input [7:0] XPOS,
	inout [11:0] DATA,
	input MODE
);

	reg [7:0] X_CNT;
	reg [11:0] LBRAM[0:191];

	// TMS0=0:Output, =1:Write
	assign DATA = MODE ? 12'bzzzzzzzzzzzz : LBRAM[X_CNT];

	always @(negedge CK)
	begin
		if (!nLDX)
			X_CNT <= XPOS;			// Disabled in MODE=0 ?
		else
			X_CNT <= X_CNT + 1;
	end
	
	always @(posedge WE)
	begin
		if (!MODE)
			LBRAM[X_CNT] <= 12'hFFF;	// Clear to backdrop. This is inherited from the Alpha68k
		else
			LBRAM[X_CNT] <= DATA;		// Render
	end

endmodule

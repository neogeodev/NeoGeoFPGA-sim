`timescale 10ns/10ns

module linebuffer(
	input CK,
	input WE,
	input LDX,
	input [7:0] XPOS,
	inout [11:0] DATA,
	input MODE
);

	reg [7:0] X_CNT;
	reg [7:0] LBRAM[0:191];

	assign DATA = MODE ? LBRAM[X_CNT] : 8'bzzzzzzzz;

	always @(posedge CK)
	begin
		if (!MODE)
		begin
			// Render
			if (WE) LBRAM[X_CNT] <= DATA;
		end
		
		if (LDX)
			X_CNT <= XPOS;
		else
			X_CNT <= X_CNT + 1;
	end

endmodule

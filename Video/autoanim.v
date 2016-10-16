`timescale 1ns/1ns

module autoanim(
	input nRESET,
	input VBLANK,
	input [7:0] AA_SPEED,
	input [2:0] TILENB_IN,
	input AA_DISABLE,
	input [1:0] AA_ATTR,
	output [2:0] TILENB_OUT,
	output reg [2:0] AA_COUNT	// Output used for REG_LSPCMODE read
);

	reg [7:0] AA_TIMER;

	// Todo: Only use TILENB_IN[2:0]
	assign TILENB_OUT = AA_DISABLE ? TILENB_IN :									// nnn	No AA
								AA_ATTR[1] ? AA_COUNT :									// AAA	3-bit AA
								AA_ATTR[0] ? {TILENB_IN[2], AA_COUNT[1:0]} :		// nAA	2-bit AA
								TILENB_IN;													// nnn	No AA
	
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

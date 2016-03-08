`timescale 1ns/1ns

module ym_pcmb(
	input PHI_S,
	output reg [7:0] PAD,
	output reg [11:8] PA,
	output reg PMPX,
	output reg nPOE
);

	always @(posedge PHI_S)		// posedge ?
	begin
		PAD <= 8'b00000000;
		PA <= 4'b0000;
		PMPX <= 0;
		nPOE <= 1;
	end
	
endmodule

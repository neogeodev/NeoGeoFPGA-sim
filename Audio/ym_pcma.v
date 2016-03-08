`timescale 1ns/1ns

module ym_pcma(
	input PHI_S,
	output reg [7:0] RAD,
	output reg [9:8] RA_L,
	output reg [23:20] RA_U,
	output reg RMPX,
	output reg nROE
);

	always @(posedge PHI_S)		// posedge ?
	begin
		RAD <= 8'b00000000;
		RA_L <= 2'b00;
		RA_U <= 4'b0000;
		RMPX <= 0;
		nROE <= 1;
	end
	
endmodule

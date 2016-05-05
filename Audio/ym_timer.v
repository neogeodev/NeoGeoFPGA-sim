`timescale 1ns/1ns

module ym_timer(
	input PHI_S,
	input [9:0] YMTIMER_TA_LOAD,
	input [7:0] YMTIMER_TB_LOAD,
	input [7:0] YMTIMER_CONFIG,
	output reg nIRQ
);


	always @(posedge PHI_S)		// ?
	begin
		nIRQ <= 1'b1;	// Todo
	end
	
endmodule

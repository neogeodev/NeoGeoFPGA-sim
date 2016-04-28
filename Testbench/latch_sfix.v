`timescale 1ns/1ns

module latch_sfix(
	input [15:0] PBUS,
	input PCK2B,
	output reg [15:0] G
);

	always @(posedge PCK2B)
	begin
		G = {PBUS[11:0], PBUS[15:12]};
	end
	
endmodule

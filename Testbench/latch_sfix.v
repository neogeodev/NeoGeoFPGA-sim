`timescale 1ns/1ns

// SIMULATION
// 16-bit latch, 2x 273 on the verification board
// Similar to the fix part of NEO-273, but for the embedded SFIX ROM
// Normally done in NEO-I0
// Signals: PCK2B

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

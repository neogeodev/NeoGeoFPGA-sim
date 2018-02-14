`timescale 1ns/1ns

module FD2(
	input nCK,
	input D,
	output reg Q = 1'b0,
	output nQ
);

	always @(posedge ~nCK)	// negedge CK
		Q <= D;
	
	assign nQ = ~Q;

endmodule

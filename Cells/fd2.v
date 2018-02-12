`timescale 1ns/1ns

module FD2(
	input CK,
	input D,
	output reg Q = 1'b0,
	output nQ
);

	always @(posedge ~CK)	// negedge CK
		Q <= D;
	
	assign nQ = ~Q;

endmodule

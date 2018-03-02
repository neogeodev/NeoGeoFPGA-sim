`timescale 1ns/1ns

module FDM(
	input CK,
	input D,
	output reg Q,
	output nQ
);

	initial
		Q <= 1'b0;

	always @(posedge CK)
		#2 Q <= D;
	
	assign nQ = ~Q;

endmodule

`timescale 1ns/1ns

module FD5(
	input nCK,
	input D,
	input nCL,
	output reg Q = 1'b0,
	output nQ
);

	always @(posedge ~nCK or posedge ~nCL)
	begin
		if (!nCL)
			Q <= #1 1'b0;
		else
			Q <= #1 D;
	end
	
	assign nQ = ~Q;

endmodule

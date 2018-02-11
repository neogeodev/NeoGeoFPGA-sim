`timescale 1ns/1ns

module LT4(
	input nG,
	input [3:0] D,
	output reg [3:0] P = 4'd0,
	output reg [3:0] N
);

	always @(*)
	begin
		if (!nG)
			P <= D;			// Latch
	end
	
	assign N = ~P;

endmodule

`timescale 10ns/10ns

module ym_ssg(
	input PHI_S,
	output reg [3:0] ANA
);

	always @(posedge PHI_S)		// posedge ?
	begin
		ANA <= 4'b0000;	// Todo
	end
	
endmodule

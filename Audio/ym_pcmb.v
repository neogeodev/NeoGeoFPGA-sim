`timescale 1ns/1ns

module ym_pcmb(
	input PHI_S,
	inout [7:0] PAD,
	output reg [11:8] PA,
	output reg PMPX,
	output reg nPOE
);

	reg [7:0] ADDRESS;
	reg MUX;

	assign PAD = MUX ? ADDRESS : 8'bzzzzzzzz;

	always @(posedge PHI_S)		// posedge ?
	begin
		ADDRESS <= 8'b00000000;
		PA <= 4'b0000;
		PMPX <= 0;
		nPOE <= 1;
	end
	
endmodule

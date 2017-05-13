`timescale 1ns/1ns

module linebuffer(
	input nOE_TO_WRITE,
	input nWE,
	input [7:0] ADDRESS,
	input [11:0] DATA_IN,
	output [11:0] DATA_OUT
);

	reg [11:0] LB_RAM[0:255];	// TODO: Add a check, should never go over 191

	// Read
	assign #35 DATA_OUT = LB_RAM[ADDRESS];
	assign DATA = nWE ? DATA_OUT : 8'bzzzzzzzz;

	// Write
	assign DATA_IN = nOE_TO_WRITE ? 12'b111111111111 : DATA;
	always @(*)
		if (!nWE)
			#10 LB_RAM[ADDRESS] <= DATA_IN;
	
	// nOE_TO_WRITE = 0 and nWE = 1 should NEVER happen !
	always @(*)
		if (!nOE_TO_WRITE && nWE)
			$display("ERROR: LINEBUFFER: data contention !");

endmodule

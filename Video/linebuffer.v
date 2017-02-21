`timescale 1ns/1ns

module linebuffer(
	input nOE_TO_WRITE,
	input nWE,
	input [7:0] ADDRESS,
	inout [11:0] DATA
);

	reg [11:0] LB_RAM[0:255];	// CHECK: Should never go over 191
	wire [7:0] DATA_OUT;
	wire [7:0] DATA_IN;

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

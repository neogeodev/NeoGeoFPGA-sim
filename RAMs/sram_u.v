`timescale 1ns/1ns

// 120ns 32768*8bit RAM

module sram_u(
	input [14:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:32767];
	
	initial begin
		//$readmemh("raminit_sram_u.txt", RAMDATA);
	end

	assign #120 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #30 RAMDATA[ADDR] <= DATA;

endmodule

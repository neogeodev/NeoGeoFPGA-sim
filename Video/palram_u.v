`timescale 1ns/1ns

// 100ns 8192*8bit RAM

module palram_u(
	input [12:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:8191];
	
	initial begin
		$readmemh("raminit_palu.txt", RAMDATA);
	end

	assign #10 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #5 RAMDATA[ADDR] = DATA;

endmodule

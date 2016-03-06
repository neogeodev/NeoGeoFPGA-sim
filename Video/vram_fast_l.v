`timescale 10ns/10ns

// 30ns (should be 35) 2048*8bit RAM

module vram_fast_l(
	input [10:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:2047];
	
	initial begin
		$readmemh("raminit_vram_fastl.txt", RAMDATA);
	end

	assign #3 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #2 RAMDATA[ADDR] <= DATA;

endmodule

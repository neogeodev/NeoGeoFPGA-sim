`timescale 1ns/1ns

// 35ns 2048*8bit RAM

module vram_fast_u(
	input [10:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:2047];
	
	initial begin
		$readmemh("raminit_vram_fastu.txt", RAMDATA);
	end

	assign #35 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #20 RAMDATA[ADDR] <= DATA;

endmodule

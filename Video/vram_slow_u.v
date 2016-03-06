`timescale 10ns/10ns

// 120ns 32768*8bit RAM

module vram_slow_u(
	input [14:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:32767];
	
	initial begin
		$readmemh("raminit_vram_slowu.txt", RAMDATA);
	end

	assign #12 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #5 RAMDATA[ADDR] <= DATA;

endmodule

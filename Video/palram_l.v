`timescale 10ns/10ns

// 100ns 8192*8bit RAM

module palram_l(
	input [12:0] ADDR,
	inout [7:0] DATA,
	input nWE,
	input nOE,
	input nCE
);

	reg [7:0] RAMDATA[0:8191];
	
	initial begin
		$readmemh("raminit_pall.txt", ROMDATA);
	end

	assign #10 DATA = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[ADDR];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #5 RAMDATA[ADDR] = DATA;

endmodule

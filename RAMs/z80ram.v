`timescale 1ns/1ns

// 2K Z80 RAM (100ns 2048*8bit RAM)

module z80ram(
	input [10:0] SDA,
	inout [7:0] SDD,
	input nCE,
	input nOE,
	input nWE
);

	reg [7:0] RAMDATA[0:2047];

	assign #100 SDD[7:0] = (nCE & nOE & ~nWE) ? 8'bzzzzzzzz : RAMDATA[SDA];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #20 RAMDATA[SDA] = SDD[7:0];

endmodule

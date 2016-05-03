`timescale 1ns/1ns

// 2K memory card (100ns 2048*8bit RAM)

module memcard(
	input [23:0] CDA,
	inout [15:0] CDD,
	input nCE,
	input nOE,
	input nWE,
	input nREG,				// Ignore
	output nCD1, nCD2,
	output nWP
);

	parameter nINSERTED = 1'b0;		// :)
	parameter nPROTECT = 1'b1;

	reg [7:0] RAMDATA[0:2047];
	
	assign nCD1 = nINSERTED;
	assign nCD2 = nINSERTED;
	assign nWP = nPROTECT;
	
	assign #10 CDD[7:0] = (nCE | nOE | ~nWE) ? 8'bzzzzzzzz : RAMDATA[CDA[10:0]];

	always @(nCE or nWE)
	  if (!(nCE & nWE))
		 #5 RAMDATA[CDA[10:0]] = CDD[7:0];

endmodule

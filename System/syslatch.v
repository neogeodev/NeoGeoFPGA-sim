`timescale 1ns/1ns

module syslatch(
	input [4:1] M68K_ADDR,
	input nBITW1,
	input nRESET,
	output SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, nSRAMWEN, PALBNK
);

	reg [7:0] SLATCH;
	
	assign SHADOW = SLATCH[7];
	assign nVEC = SLATCH[6];
	assign nCARDWEN = SLATCH[5];
	assign CARDWENB = SLATCH[4];
	assign nREGEN = SLATCH[3];
	assign nSYSTEM = SLATCH[2];
	assign nSRAMWEN = ~SLATCH[1];		// See MVS schematics page 3
	assign PALBNK = SLATCH[0];
	
	// System latch
	always @(M68K_ADDR[4:1] or nBITW1 or nRESET)
	begin
		if (!nRESET)
			SLATCH <= 8'b0;
		if (!nBITW1)
			SLATCH[M68K_ADDR[3:1]] <= M68K_ADDR[4];
	end
	
endmodule

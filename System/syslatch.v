`timescale 10ns/10ns

module syslatch(
	input [3:0] M68K_ADDR,
	input nBITW1,
	input nRESET,
	output SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, nSRAMLOCK, nPALBANK
);

	reg [7:0] SLATCH;
	
	assign SHADOW = SLATCH[7];
	assign nVEC = SLATCH[6];
	assign nCARDWEN = SLATCH[5];
	assign CARDWENB = SLATCH[4];
	assign nREGEN = SLATCH[3];
	assign nSYSTEM = SLATCH[2];
	assign nSRAMLOCK = SLATCH[1];
	assign nPALBANK = SLATCH[0];
	
	// System latch
	always @(M68K_ADDR[3:0] or nBITW1 or nRESET)
	begin
		if (!nRESET)
			SLATCH <= 8'b0;
		if (!nBITW1)
			SLATCH[M68K_ADDR[2:0]] <= M68K_ADDR[3];
	end
	
endmodule

`timescale 1ns/1ns

module syslatch(
	input [3:0] M68K_ADDR,
	input nBITW1,
	input nRESET,
	output SHADOW, nVEC, nCARDWEN, CARDWENB, nREGEN, nSYSTEM, SRAMWEN, PALBNK
);

	reg [7:0] SLATCH;
	
	// Todo: debug
	assign PALBNK = 1'b0;
	
	assign SHADOW = SLATCH[7];
	assign nVEC = SLATCH[6];
	assign nCARDWEN = SLATCH[5];
	assign CARDWENB = SLATCH[4];
	assign nREGEN = SLATCH[3];
	assign nSYSTEM = SLATCH[2];
	assign SRAMWEN = SLATCH[1];
	//assign PALBNK = SLATCH[0];
	
	// System latch
	always @(M68K_ADDR[3:0] or nBITW1 or nRESET)
	begin
		if (!nRESET)
			SLATCH <= 8'b0;
		if (!nBITW1)
			SLATCH[M68K_ADDR[2:0]] <= M68K_ADDR[3];
	end
	
endmodule

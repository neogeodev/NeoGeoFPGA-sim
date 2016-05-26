`timescale 1ns/1ns

/*
From LA:

24M  __|''|__|''|__|''|__|''|__|''|__|''|__|''|__|''|
12M  '''''|_____|'''''|_____|'''''|_____|'''''|_____|
6MB  '''''|___________|'''''''''''|__________|'''''''
1MB  _______________________|'''''''''''''''''''''''|
68K  _____|'''''|_____|'''''|_____|'''''|_____|'''''|
*/

module clocks(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_6MB,
	output CLK_1MB
);

	reg CLKDIV_68K;
	reg [1:0] CLKDIV_A;
	reg [1:0] CLKDIV_B;
	
	assign CLK_12M = CLKDIV_A[0];
	assign CLK_6MB = CLKDIV_A[1];
	assign CLK_68KCLK = CLKDIV_68K;
	assign CLK_68KCLKB = ~CLK_68KCLK;	// ?
	assign CLK_1MB = CLKDIV_B[1];
	
	always @(negedge CLK_24M)
		CLKDIV_68K <= ~CLKDIV_68K;			// Is CLK_68KCLK free runing ?
	
	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
			CLKDIV_A <= 0;
		else
			CLKDIV_A <= CLKDIV_A + 1;
	end
	
	always @(negedge CLK_68KCLK or negedge nRESETP)
	begin
		if (!nRESETP)
			CLKDIV_B <= 0;
		else
			CLKDIV_B <= CLKDIV_B + 1;
	end
	
endmodule

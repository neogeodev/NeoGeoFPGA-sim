`timescale 1ns/1ns

module clocks(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_6MB,
	output CLK_1MB
);

	// Everything here happens on negedge 24M

	reg [2:0] CLKDIV_A;
	reg [2:0] CLKDIV_B;
	
	assign CLK_12M = CLKDIV_A[0];
	assign CLK_68KCLKB = CLKDIV_A[0];	// What's the difference ?
	assign CLK_68KCLK = ~CLK_68KCLKB;
	assign CLK_6MB = ~CLKDIV_A[1];
	assign CLK_1MB = CLKDIV_B[2];
	
	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
		begin
			CLKDIV_A <= 0;
			CLKDIV_B <= 3'd7;
		end
		else
		begin
			CLKDIV_A <= CLKDIV_A + 1;
			CLKDIV_B <= CLKDIV_B + 1;
		end
	end
	
endmodule

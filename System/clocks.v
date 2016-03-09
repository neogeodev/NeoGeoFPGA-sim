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

	reg [2:0] CLKDIV;
	
	assign RESETP = ~nRESETP;
	
	always @(posedge CLK_24M or posedge RESETP)
	begin
		if (!nRESETP)
			CLKDIV <= 0;
		else
			CLKDIV <= CLKDIV + 1;
	end
	
	assign CLK_12M = CLKDIV[0];			// ?
	assign CLK_68KCLK = CLKDIV[0];		// ?
	assign CLK_68KCLKB = ~CLK_68KCLK;
	assign CLK_6MB = ~CLKDIV[1];
	assign CLK_1MB = ~CLKDIV[2];
	
endmodule

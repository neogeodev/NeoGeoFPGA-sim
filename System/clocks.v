`timescale 1ns/1ns

// Everything here was verified on a MV4 board
// Todo: Check phase relations between 12M, 68KCLK and 68KCLKB
// Todo: Check cycle right after nRESETP goes high, real hw might have an important delay added

module clocks(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output reg CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_6MB,
	output reg CLK_1MB
);

	wire CLK_3M;
	
	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
			CLK_68KCLK <= 1'b1;	// Real hw doesn't clearly init DFF, this needs to be checked
		else
			CLK_68KCLK <= ~CLK_68KCLK;
	end
	
	assign CLK_68KCLKB = ~CLK_68KCLK;
	
	
	reg [2:0] CLKDIV_B;			// Bit 3 of counter isn't used
	
	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
			CLKDIV_B <= 3'b100;	// Load
		else
			CLKDIV_B <= CLKDIV_B + 1'b1;
	end
	
	assign CLK_12M = CLKDIV_B[0];
	assign CLK_6MB = ~CLKDIV_B[1];
	assign CLK_3M = CLKDIV_B[2];
	
	always @(posedge CLK_12M)	// DFF
		CLK_1MB <= ~CLK_3M;
	
endmodule

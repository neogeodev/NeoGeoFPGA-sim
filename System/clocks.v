`timescale 1ns/1ns

// Everything here was verified on a MV4 board
// Todo: Check phase relations between 12M, 68KCLK and 68KCLKB
// Todo: Check cycle right after nRESETP goes high, real hw might have an important delay added

module clocks(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output reg CLK_68KCLK = 1'b0,	// Real hw doesn't clearly init DFF, this needs to be checked
	output CLK_68KCLKB,
	output CLK_6MB,
	output reg CLK_1MB
);

	reg [2:0] CLK_DIV;
	wire CLK_3M;
	
	// MV4 C4:A
	always @(posedge CLK_24M)
		CLK_68KCLK <= ~CLK_68KCLK;
	
	assign CLK_68KCLKB = ~CLK_68KCLK;
	
	always @(negedge CLK_24M or negedge nRESETP)
	begin
		if (!nRESETP)
			CLK_DIV <= 3'b100;
		else
			CLK_DIV <= CLK_DIV + 1'b1;
	end
	
	assign CLK_12M = CLK_DIV[0];
	assign CLK_6MB = ~CLK_DIV[1];
	assign CLK_3M = ~CLK_DIV[2];
	
	// MV4 C4:B
	always @(posedge CLK_12M)
		CLK_1MB <= ~CLK_3M;
	
endmodule

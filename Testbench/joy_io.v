`timescale 1ns/1ns

module joy_io(
	input nCTRL1ZONE,
	input nCTRL2ZONE,
	input nSTATUSBZONE,
	inout [15:0] M68K_DATA,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input nBITWD0,
	input M68K_ADDR_A4,
	output reg [2:0] P1_OUT,
	output reg [2:0] P2_OUT
);
		
	always @(negedge nBITWD0)
	begin
		if (!M68K_ADDR_A4) {P2_OUT, P1_OUT} <= M68K_DATA[5:0];		// REG_POUTPUT
	end
	
	// REG_P1CNT
	assign M68K_DATA = nCTRL1ZONE ? 8'bzzzzzzzz : P1_IN[7:0];
	// REG_P2CNT
	assign M68K_DATA = nCTRL2ZONE ? 8'bzzzzzzzz : P2_IN[7:0];
	
	// REG_STATUS_B
	// assign M68K_DATA = nSTATUSBZONE ? 8'bzzzzzzzz : {CONSOLE_MODE, nWP, nCD2, nCD1, P2_IN[9:8], P1_IN[9:8]};
	
endmodule

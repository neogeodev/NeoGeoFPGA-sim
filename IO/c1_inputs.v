`timescale 1ns/1ns

module c1_inputs(
	input nCTRL1_ZONE,
	input nCTRL2_ZONE,
	input nSTATUSB_ZONE,
	output [15:8] M68K_DATA,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input nWP, nCD2, nCD1,
	input SYSTEM_MODE
);

	// REG_P1CNT
	assign M68K_DATA[15:8] = nCTRL1_ZONE ? 8'bzzzzzzzz : P1_IN[7:0];
	// REG_P2CNT
	assign M68K_DATA[15:8] = nCTRL2_ZONE ? 8'bzzzzzzzz : P2_IN[7:0];
	
	// REG_STATUS_B
	assign M68K_DATA[15:8] = nSTATUSB_ZONE ? 8'bzzzzzzzz : {SYSTEM_MODE, nWP, nCD2, nCD1, P2_IN[9:8], P1_IN[9:8]};
	
endmodule

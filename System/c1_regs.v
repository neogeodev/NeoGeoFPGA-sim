`timescale 10ns/10ns

module c1_regs(
	input nCTRL1ZONE,
	input nCTRL2ZONE,
	input nSTATUSBZONE,
	input nICOMZONE,
	input CONSOLE_MODE,
	input nWP, nCD2, nCD1,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input RW,
	inout [15:8] M68K_DATA
);

	reg [7:0] SDD_LATCH;			// Z80 data latch

	// REG_P1CNT
	assign M68K_DATA = (~nCTRL1ZONE) ? P1_IN[7:0] : 8'bzzzzzzzz;
	// REG_P2CNT
	assign M68K_DATA = (~nCTRL2ZONE) ? P2_IN[7:0] : 8'bzzzzzzzz;
	
	// REG_STATUS_B
	assign M68K_DATA = (~nSTATUSBZONE) ? {CONSOLE_MODE, nWP, nCD2, nCD1, P2_IN[9:8], P1_IN[9:8]} : 8'bzzzzzzzz;
	
	// REG_SOUND - Is Z80 data latch really 2 different latches ?
	assign M68K_DATA = (RW & ~nICOMZONE) ? SDD_LATCH : 8'bzzzzzzzz;
	always @(RW or nICOMZONE)
	begin
		if (~RW & ~nICOMZONE) SDD_LATCH <= M68K_DATA;
	end
	
endmodule

`timescale 1ns/1ns

module c1_regs(
	input nICOMZONE,
	input CONSOLE_MODE,
	input nWP, nCD2, nCD1,
	input RW,
	inout [15:8] M68K_DATA
);

	reg [7:0] SDD_LATCH;			// Z80 data latch
	
	// REG_SOUND - Is Z80 data latch really 2 different latches ?
	assign M68K_DATA = (RW & ~nICOMZONE) ? SDD_LATCH : 8'bzzzzzzzz;
	always @(RW or nICOMZONE)
	begin
		if (!(RW | nICOMZONE)) SDD_LATCH <= M68K_DATA;
	end
	
endmodule

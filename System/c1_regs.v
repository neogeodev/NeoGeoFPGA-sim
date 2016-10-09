`timescale 1ns/1ns

module c1_regs(
	input nICOMZONE,
	input RW,
	inout [15:8] M68K_DATA,
	inout [7:0] SDD,
	input nSDZ80R, nSDZ80W, nSDZ80CLR,
	output nSDW
);

	reg [7:0] SDD_LATCH_CMD;
	reg [7:0] SDD_LATCH_REP;
	
	// Z80 command read
	assign SDD = nSDZ80R ? 8'bzzzzzzzz : SDD_LATCH_CMD;
	
	// Z80 reply write
	always @(posedge nSDZ80W)	// No edge at all ?
	begin
		// DEBUG begin
		$display("Z80 replied to 68K command !");
		$stop;
		// DEBUG end
		SDD_LATCH_REP <= SDD;
	end
	
	// REG_SOUND read
	assign M68K_DATA = (RW & ~nICOMZONE) ? SDD_LATCH_REP : 8'bzzzzzzzz;
	
	// REG_SOUND write
	assign nSDW = (RW | nICOMZONE);
	
	// DEBUG begin
	always @(negedge nSDW)
	begin
		$display("68K sent Z80 command %H !", M68K_DATA);
		if (M68K_DATA == 8'h03) $stop;
	end
	// DEBUG end
	
	// REG_SOUND write
	always @(negedge nICOMZONE or negedge nSDZ80CLR)		// Which one has priority ?
	begin
		if (!nSDZ80CLR)
		begin
			SDD_LATCH_CMD <= 8'b00000000;
			//nSDW <= 1'b1;
		end
		else
		begin
			if (!RW)
			begin
				SDD_LATCH_CMD <= M68K_DATA;
				//nSDW <= 1'b0;	// Tells Z80 that 68k sent a command
			end
		end
	end
	
endmodule

`timescale 10ns/10ns

module videocycle(
	input CLK_24M,
	output PCK1, PCK2,
	output LOAD,
	output nVCS,
	inout [23:0] PBUS
);

	reg [3:0] CYCLE_POS;		// 0 ~ 15
	reg [3:0] CYCLE_NEG;		// 0 ~ 15
	
	reg [15:0] PBUSL;
	reg [7:0] PBUSU;
	
	assign PBUS = {PBUSU, PBUSL};
	
	assign PCK2 = (CYCLE_NEG == 0) ? 1 : 0;
	assign PCK1 = (CYCLE_NEG == 8) ? 1 : 0;
	assign LOAD = CYCLE_POS[2] & CYCLE_POS[1];	// 6 & 7
	assign nVCS = (CYCLE_POS[2] & CYCLE_POS[1]) | ~CYCLE_POS[3];	// 9 ~ 13

	always @(posedge CLK_24M)
	begin
		CYCLE_POS <= CYCLE_POS + 1;
		
		// Just for testing:
		PBUSL = 0;
		PBUSU = 0;
	end
	
	always @(negedge CLK_24M)
	begin
		CYCLE_NEG <= CYCLE_NEG + 1;
	end

endmodule

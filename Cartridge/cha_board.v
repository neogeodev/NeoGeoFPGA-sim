`timescale 1ns/1ns

module cha_board(
	input [23:0] PBUS,
	input CA4,
	input S2H1,
	input PCK1B,
	input PCK2B,
	input [15:0] SDA,
	input nSDROM,
	inout [7:0] SDD,
	output [31:0] CR,
	output [7:0] FIXD
);

	wire [19:0] C_LATCH;
	wire [15:0] S_LATCH;
	wire [20:0] C_ADDR;
	wire [16:0] S_ADDR;
	wire [15:0] C1DATA;
	wire [15:0] C2DATA;
	
	assign C_ADDR = {C_LATCH[19:4], CA4, C_LATCH[3:0]};
	assign S_ADDR = {S_LATCH[15:3], S2H1, S_LATCH[2:0]};
	
	assign CR = {C1DATA, C2DATA};		// Other way around ?
	
	rom_c1 C1(C_ADDR[17:0], C1DATA);
	rom_c2 C2(C_ADDR[17:0], C2DATA);
	rom_s1 S1(S_ADDR[16:0], FIXD);
	
	// Need ZMC here
	//rom_m1 M1(SDA, SDD, nSDROM);
	
	neo_273 N273(PBUS[19:0], PCK1B, PCK2B, C_LATCH, S_LATCH);

endmodule

`timescale 1ns/1ns

module neo_e0(
	input [22:0] M68K_ADDR,
	input [2:0] BNK,
	input nSROMOEU, nSROMOEL,
	output nSROMOE,
	input nVEC,
	output A23Z, A22Z,
	output [23:0] CDA
);

	assign nSROMOE = nSROMOEU & nSROMOEL;

	// A = 1 if nVEC == 0 and A == 11000000000000000xxxxxxx
	assign {A23Z, A22Z} = M68K_ADDR[22:21] ^ {2{~|{M68K_ADDR[20:6], ^M68K_ADDR[22:21], nVEC}}};

	// nCARDZONE: 8xxxxx Bxxxxx (3FFFFF) 22 bits
	// CDA: 24 bits
	
	wire [1:0] CDB;
	
	assign CDB = BNK[2] ? 2'b11 :
						BNK[1] ? 2'b10 :
						BNK[0] ? 2'b01 :
						2'b00;
	
	assign CDA = {CDB, M68K_ADDR[21:0]};
	
endmodule

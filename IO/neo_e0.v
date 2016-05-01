`timescale 1ns/1ns

module neo_e0(
	input [22:6] M68K_ADDR,
	input [2:0] BNK,
	input nSROMOEU, nSROMOEL,
	output nSROMOE,
	input nVEC,
	output A23Z, A22Z,
	output [4:0] CDA_U
);

	//wire [1:0] CDB;
	
	assign nSROMOE = nSROMOEU & nSROMOEL;

	// A = 1 if nVEC == 0 and A == 11000000000000000xxxxxxx
	assign {A23Z, A22Z} = M68K_ADDR[22:21] ^ {2{~|{M68K_ADDR[20:6], ^M68K_ADDR[22:21], nVEC}}};

	// Todo: Check this on real hw
	/*assign CDB = BNK[2] ? 2'b11 :
						BNK[1] ? 2'b10 :
						BNK[0] ? 2'b01 :
						2'b00;*/
	
	assign CDA_U = {BNK, M68K_ADDR[21:20]};
	
endmodule

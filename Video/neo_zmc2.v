// Graphics mux part (CT0) was written by Kyuusaku
`timescale 1ns/1ns

module neo_zmc2(
	input CLK_12M,
	input EVEN,
	input LOAD,
	input H,
	input [31:0] CR,
	output [3:0] GAD, GBD,
	output DOTA, DOTB
	
	// Not used here
	/*input SDRD0,
	input [1:0] SDA_L,
	input [15:8] SDA_U,
	output [21:11] MA*/
);

	// Not used here
	//zmc2_zmc ZMC2ZMC(SDRD0, SDA_L, SDA_U, MA);
	zmc2_dot ZMC2DOT(CLK_12M, EVEN, LOAD, H, CR, GAD, GBD, DOTA, DOTB);

endmodule


`timescale 1ns/1ns

module z80ctrl(
	input [4:2] SDA_L,
	input [15:11] SDA_U,
	input nSDRD, nSDWR, 
	input nMREQ, nIORQ,
	input nSDW,				// Input ?
	input nRESET, nRESETP,
	output nZ80NMI,
	input nSDZ80R, nSDZ80W,
	input nSDZ80CLR,
	output nSDROM,
	output nSDMRD, nSDMWR,
	output SDRD0, SDRD1,
	output n2610CS, n2610RD, n2610WR,
	output nZRAMCS
);

	// Todo...
	
endmodule

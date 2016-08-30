`timescale 1ns/1ns

// Z80 CPU plug into TV80 core

module cpu_z80(
	input CLK_4M,
	input nRESET,
	inout [7:0] SDD,
	output [15:0] SDA,
	output nIORQ, nMREQ,
	output nRD, nWR,
	output nINT, nNMI
);

	wire [7:0] SDD_IN;
	wire [7:0] SDD_OUT;

	assign nWR = ~WR;
	
	assign SDD = nWR ? 8'bzzzzzzzz : SDD_OUT;
	assign SDD_IN = nRD ? 8'bzzzzzzzz : SDD;

	tv80_core TV80( , nIORQ, nRD, WR, , , , SDA, SDD_OUT, , // nMREQ ?
							, , , ,
							nRESET, CLK_4M, 1'b1, 1'b1, nINT, nNMI, 1'b1, SDD_IN, );
	
endmodule

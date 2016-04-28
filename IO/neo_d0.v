`timescale 1ns/1ns

module neo_d0(
	input CLK_24M,
	input nRESET, nRESETP,
	output CLK_12M,
	output CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_6MB,
	output CLK_1MB,
	input M68K_ADDR_A4,
	input nBITWD0,
	input [5:0] M68K_DATA,
	input [15:11] SDA_H,
	input [4:2] SDA_L,
	input nSDRD, nSDWR, nMREQ, nIORQ,
	output nZ80NMI,
	input nSDZ80R, nSDZ80W, nSDZ80CLR,
	output nSDROM, nSDMRD, nSDMWR,
	output SDRD0, SDRD1,
	output n2610CS, n2610RD, n2610WR,
	output nZRAMCS,
	output reg [2:0] BNK
);

	// Clock divider part
	clocks CLK(CLK_24M, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_6MB, CLK_1MB);
	
	// Z80 controller part
	z80ctrl Z80CTRL(SDA_L, SDA_H, nSDRD, nSDWR, nMREQ, nIORQ, nSDW, nRESET, nRESETP, nZ80NMI,
					nSDZ80R, nSDZ80W, nSDZ80CLR, nSDROM, nSDMRD, nSDMWR, SDRD0, SDRD1, n2610CS, n2610RD, n2610WR, nZRAMCS);
	
	always @(negedge nBITWD0)
	begin
		if (M68K_ADDR_A4) BNK <= M68K_DATA[2:0];	// REG_CRDBANK
	end
	
endmodule

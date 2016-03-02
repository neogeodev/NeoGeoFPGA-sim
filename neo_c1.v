`timescale 10ns/10ns

module neo_c1(
	input [20:16] M68K_ADDR,
	output [7:0] M68K_DATA,
	input A22Z, A23Z,
	input nLDS, nUDS,
	input RW, AS,
	output nROMOEL, nROMOEU,
	output nPORTOEL, nPORTOEU,
	output nPORTWEL, nPORTWEU,
	output nPORTADRS,
	output nWRL, nWRU,
	output nWWL, nWWU,
	output nSROMOEL, nSROMOEU,
	output nSRAMOEL, nSRAMOEU,
	output nSRAMWEL, nSRAMWEU,
	output nLSPOE, nLSPWE,
	output nCRDO, nCRDW, nCRDC,
	output nSDW,
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input nCD1, nCD2, nWP,
	input ROMWAIT, PWAIT0, PWAIT1, PDTACK,
	input [7:0] SDD,
	input CLK_68KCLK,
	output reg nDTACK,
	output nBITW0, nBITW1, nDIPRD0, nDIPRD1,
	output nPAL
);

	parameter CONSOLE_MODE = 1;	// MVS (IN27 of NEO-C1)

	wire nSTATUSB;
	
	reg [7:0] SDD_LATCH;				// Z80 data latch

	// REG_P1CNT
	assign M68K_DATA = (RW & ~nCTRL1ZONE) ? P1_IN[7:0] : 8'bzzzzzzzz;
	// REG_P2CNT
	assign M68K_DATA = (RW & ~nCTRL2ZONE) ? P2_IN[7:0] : 8'bzzzzzzzz;
	
	// REG_STATUS_B
	assign M68K_DATA = (RW & ~nSTATUSBZONE) ? {CONSOLE_MODE, nWP, nCD2, nCD1, P2_IN[9:8], P1_IN[9:8]} : 8'bzzzzzzzz;
	
	// REG_SOUND Is Z80 data latch really 2 different latches ?
	assign M68K_DATA = (RW & ~nICOMZONE) ? SDD_LATCH : 8'bzzzzzzzz;
	always @(RW or nICOMZONE)
	begin
		if (~RW & ~nICOMZONE) SDD_LATCH <= M68K_DATA;
	end
	
	// Wait cycle gen
	always @(posedge CLK_68KCLK)
	begin
		// ROMWAIT, PWAIT0, PWAIT1, PDTACK, CLK_68KCLK
		nDTACK <= 0;	// TODO
	end
	
	// Address decoding, is everything in sync with AS ?
	
	// 0xxxxx
	assign nROMZONE = |{A23Z, A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// 1xxxxx
	assign nWRAMZONE = |{A23Z, A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};
	
	// 2xxxxx
	assign nPORTZONE = |{A23Z, A22Z, ~M68K_ADDR[20], M68K_ADDR[19]};
	
	// 30xxxx 31xxxx even bytes
	assign nCTRL1ZONE = nUDS & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17] ,M68K_ADDR[16]};
	
	// 32xxxx 33xxxx even bytes
	assign nICOMZONE = nUDS & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 34xxxx 37xxxx even bytes not sure if M68K_ADDR[16] is used (up to 35FFFF only ?)
	assign nCTRL2ZONE = nUDS & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 30xxxx 31xxxx ?, odd bytes write
	assign nDIPRD0 = nLDS & RW & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17], M68K_ADDR[17]};
	
	// 32xxxx 33xxxx ?, odd bytes write
	assign nDIPRD1 = nLDS & RW & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[17]};
	
	// 38xxxx 39xxxx odd bytes ?
	assign nBITW0 = nLDS & ~RW & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17], M68K_ADDR[16]};
	
	// 3Axxxx 3Bxxxx odd bytes ?
	assign nBITW1 = nLDS & ~RW & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 38xxxx 3Bxxxx even bytes
	assign nSTATUSBZONE = nUDS & |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17]};
	
	// 3Cxxxx 3Dxxxx not sure if M68K_ADDR[16] is used (up to 3DFFFF only ?)
	assign nLSPCZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 4xxxxx 7xxxxx
	assign nPAL = |{A23Z, ~A22Z};
	
	// 8xxxxx Bxxxxx
	assign nCARDZONE = |{~A23Z, A22Z};
	
	// Cxxxxx Cxxxxx
	assign nSROMZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// Dxxxxx Dxxxxx ?
	assign nSRAMZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};

	assign nWORDACCESS = nLDS | nUDS;

	assign nROMOEL = ~RW | nLDS | nROMZONE;
	assign nROMOEU = ~RW | nUDS | nROMZONE;
	assign nPORTOEL = ~RW | nLDS | nPORTZONE;
	assign nPORTOEU = ~RW | nUDS | nPORTZONE;
	assign nPORTWEL = RW | nLDS | nPORTZONE;
	assign nPORTWEU = RW | nUDS | nPORTZONE;
	assign nPADRS = nPORTZONE;
	assign nWRL = ~RW | nLDS | nWRAMZONE;
	assign nWRU = ~RW | nUDS | nWRAMZONE;
	assign nWWL = RW | nLDS | nWRAMZONE;
	assign nWWU = RW | nUDS | nWRAMZONE;
	assign nSROMOEL = ~RW | nLDS | nSROMZONE;
	assign nSROMOEU = ~RW | nUDS | nSROMZONE;
	assign nSRAMOEL = ~RW | nLDS | nSRAMZONE;
	assign nSRAMOEU = ~RW | nUDS | nSRAMZONE;
	assign nSRAMWEL = RW | nLDS | nSRAMZONE;
	assign nSRAMWEU = RW | nUDS | nSRAMZONE;

	// assign DIPRD0 = ? // Asks NEO-F0 for dipswitches on D0~7 ?

	// Not sure about word access ?
	assign nLSPOE = ~RW | nWORDACCESS | nLSPCZONE;
	assign nLSPWE = RW | nWORDACCESS | nLSPCZONE;
	assign nCRDO = ~RW | nWORDACCESS | nCARDZONE;
	assign nCRDW = RW | nWORDACCESS | nCARDZONE;
	assign nCRDC = nCRDO & nCRDW;

	// Inter-CPU comm.
	// To do

	// Inputs
	// To do

	// Wait states
	// To do

endmodule

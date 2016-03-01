`timescale 10ns/10ns

module neo_c1(
	input [20:16] M68K_ADDR,
	input A22Z, A23Z,
	input LDS, UDS,
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
	output nCRDO, nCRDW, nCRDC
);

	// Address decoding, is everything in sync with AS ?
	
	// 0xxxxx
	assign nROMZONE = |{A23Z, A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// 1xxxxx
	assign nWRAMZONE = |{A23Z, A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};
	
	// 2xxxxx
	assign nPORTZONE = |{A23Z, A22Z, ~M68K_ADDR[20], M68K_ADDR[19]};
	
	// 30xxxx 31xxxx
	assign nCTRL1ZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17] ,M68K_ADDR[16]};
	
	// 32xxxx 33xxxx
	assign nICOMZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 34xxxx 37xxxx not sure if M68K_ADDR[16] is used (up to 35FFFF only ?)
	assign nCTRL2ZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 38xxxx 39xxxx ?
	assign nBITW0 = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17], M68K_ADDR[16]};
	
	// 3Axxxx 3Bxxxx ?
	assign nBITW1 = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 3Cxxxx 3Dxxxx not sure if M68K_ADDR[16] is used (up to 3DFFFF only ?)
	assign nLSPCZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19], ~M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 4xxxxx 7xxxxx
	assign nPAL = |{A23Z,~A22Z};
	
	// 8xxxxx Bxxxxx
	assign nCARDZONE = |{~A23Z,A22Z};
	
	// Cxxxxx Cxxxxx
	assign nSROMZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// Dxxxxx Dxxxxx ?
	assign nSRAMZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};

	assign nWORDACCESS = LDS | UDS;

	assign nROMOEL = ~RW | LDS | nROMZONE;
	assign nROMOEU = ~RW | UDS | nROMZONE;
	assign nPORTOEL = ~RW | LDS | nPORTZONE;
	assign nPORTOEU = ~RW | UDS | nPORTZONE;
	assign nPORTWEL = RW | LDS | nPORTZONE;
	assign nPORTWEU = RW | UDS | nPORTZONE;
	assign nPADRS = nPORTZONE;
	assign nWRL = ~RW | LDS | nWRAMZONE;
	assign nWRU = ~RW | UDS | nWRAMZONE;
	assign nWWL = RW | LDS | nWRAMZONE;
	assign nWWU = RW | UDS | nWRAMZONE;
	assign nSROMOEL = ~RW | LDS | nSROMZONE;
	assign nSROMOEU = ~RW | UDS | nSROMZONE;
	assign nSRAMOEL = ~RW | LDS | nSRAMZONE;
	assign nSRAMOEU = ~RW | UDS | nSRAMZONE;
	assign nSRAMWEL = RW | LDS | nSRAMZONE;
	assign nSRAMWEU = RW | UDS | nSRAMZONE;

	// assign DIPRD0 = ? // Asks NEO-F0 for dipswitches on D0~7 ?

	// Not sure about word access, is it LDS|UDS or LDS&UDS or nothing at all ?
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

`timescale 1ns/1ns

module neo_c1(
	input [21:17] M68K_ADDR,
	output [15:8] M68K_DATA,
	input A22Z, A23Z,
	input nLDS, nUDS,
	input RW, nAS,
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
	//input [9:0] P1_IN,
	//input [9:0] P2_IN,
	input nCD1, nCD2, nWP,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	input [7:0] SDD,
	input CLK_68KCLK,
	output nDTACK,
	output nBITW0, nBITW1, nDIPRD0, nDIPRD1,
	output nPAL,
	output nCTRL1ZONE,
	output nCTRL2ZONE,
	output nSTATUSBZONE
);

	wire nIO_ZONE;			// Internal
	wire nC1REGS_ZONE;	// Internal
	wire nROM_ZONE;		// Internal
	wire nWRAM_ZONE;		// Internal
	wire nPORT_ZONE;		// Internal
	wire nCTRL1_ZONE;		// Internal (external for PCB)
	wire nICOM_ZONE;		// Internal
	wire nCTRL2_ZONE;		// Internal (external for PCB)
	wire nSTATUSB_ZONE;	// Internal (external for PCB)
	wire nLSPC_ZONE;		// Internal
	wire nCARD_ZONE;		// Internal
	wire nSROM_ZONE;		// Internal
	wire nSRAM_ZONE;		// Internal
	wire nWORDACCESS;		// Internal
	
	assign nVALID = nAS | (nLDS & nUDS);
	
	c1_regs C1REGS(nICOM_ZONE, RW, M68K_DATA);
	
	c1_wait C1WAIT(CLK_68KCLK, nAS, nROM_ZONE, nPORT_ZONE, nCARD_ZONE, nROMWAIT, nPWAIT0,
					nPWAIT1, PDTACK, nDTACK);
	
	// 000000~0FFFFF read/write
	assign nROM_ZONE = |{A23Z, A22Z, M68K_ADDR[21], M68K_ADDR[20]};
	
	// 100000~1FFFFF read/write
	assign nWRAM_ZONE = |{A23Z, A22Z, M68K_ADDR[21], ~M68K_ADDR[20]};
	
	// 200000~2FFFFF read/write
	assign nPORT_ZONE = |{A23Z, A22Z, ~M68K_ADDR[21], M68K_ADDR[20]};
	
	// 300000~3FFFFF read/write
	assign nIO_ZONE = |{A23Z, A22Z, ~M68K_ADDR[21], ~M68K_ADDR[20]};
	
		// 300000~3FFFFF even bytes read/write
		assign nC1REGS_ZONE = nUDS | nIO_ZONE;
		
			// 300000~31FFFF even bytes read only
			assign nCTRL1_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
			
			// 32FFFF~33FFFF even bytes read/write
			assign nICOM_ZONE = nC1REGS_ZONE | |{M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
			// 34FFFF~37FFFF even bytes read only - not sure if M68K_ADDR[17] is used (up to 35FFFF only ?)
			assign nCTRL2_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[19], ~M68K_ADDR[18]};

	// 30xxxx 31xxxx ?, odd bytes read only
	assign nDIPRD0 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 32xxxx 33xxxx ?, odd bytes read only
	assign nDIPRD1 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 38xxxx 39xxxx odd bytes write only
	assign nBITW0 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 3Axxxx 3Bxxxx odd bytes write only
	assign nBITW1 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 38xxxx 39xxxx even bytes read only
	assign nSTATUSB_ZONE = nC1REGS_ZONE | ~RW | |{~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 3C0000~3DFFFF 
	assign nLSPC_ZONE = |{nIO_ZONE, ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17]};
	
	// 4xxxxx 7xxxxx
	assign nPAL = |{A23Z, ~A22Z};
	
	// 8xxxxx Bxxxxx
	assign nCARD_ZONE = |{~A23Z, A22Z};
	
	// Cxxxxx Cxxxxx
	assign nSROM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[21], M68K_ADDR[20]};
	
	// Dxxxxx Dxxxxx ?
	assign nSRAM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[21], ~M68K_ADDR[20]};

	assign nWORDACCESS = nLDS | nUDS;

	// Outputs:
	assign nROMOEL = ~RW | nLDS | nROM_ZONE | nAS;
	assign nROMOEU = ~RW | nUDS | nROM_ZONE | nAS;
	assign nPORTOEL = ~RW | nLDS | nPORT_ZONE | nAS;
	assign nPORTOEU = ~RW | nUDS | nPORT_ZONE | nAS;
	assign nPORTWEL = RW | nLDS | nPORT_ZONE | nAS;
	assign nPORTWEU = RW | nUDS | nPORT_ZONE | nAS;
	assign nPADRS = nPORT_ZONE | nVALID;
	assign nWRL = ~RW | nLDS | nWRAM_ZONE | nAS;
	assign nWRU = ~RW | nUDS | nWRAM_ZONE | nAS;
	assign nWWL = RW | nLDS | nWRAM_ZONE | nAS;
	assign nWWU = RW | nUDS | nWRAM_ZONE | nAS;
	assign nSROMOEL = ~RW | nLDS | nSROM_ZONE | nAS;
	assign nSROMOEU = ~RW | nUDS | nSROM_ZONE | nAS;
	assign nSRAMOEL = ~RW | nLDS | nSRAM_ZONE | nAS;
	assign nSRAMOEU = ~RW | nUDS | nSRAM_ZONE | nAS;
	assign nSRAMWEL = RW | nLDS | nSRAM_ZONE | nAS;
	assign nSRAMWEU = RW | nUDS | nSRAM_ZONE | nAS;

	// Not sure about word access ?
	assign nLSPOE = RW | nWORDACCESS | nLSPC_ZONE | nAS;
	assign nLSPWE = ~RW | nWORDACCESS | nLSPC_ZONE | nAS;
	assign nCRDO = RW | nWORDACCESS | nCARD_ZONE | nAS;
	assign nCRDW = ~RW | nWORDACCESS | nCARD_ZONE | nAS;
	assign nCRDC = nCRDO & nCRDW;

endmodule

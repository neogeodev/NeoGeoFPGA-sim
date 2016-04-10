`timescale 1ns/1ns

module neo_c1(
	input [20:16] M68K_ADDR,
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
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input nCD1, nCD2, nWP,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,		// nROMWAIT=nPWAIT0=nPWAIT1=PDTACK = 1 = fullspeed ?
	input [7:0] SDD,
	input CLK_68KCLK,
	output nDTACK,
	output nBITW0, nBITW1, nDIPRD0, nDIPRD1,
	output nPAL
);

	parameter CONSOLE_MODE = 1'b1;	// MVS (IN27 of NEO-C1)


	reg [1:0] WAIT_CNT;
	
	assign nPDTACK = ~(nPORT_ZONE | PDTACK);		// Really a NOR ? May stall CPU if PDTACK = GND
	assign nDTACK = nAS | |{WAIT_CNT} | nPDTACK;
	
	assign nCLK_68KCLK = ~nCLK_68KCLK;
	
	always @(negedge nCLK_68KCLK or negedge nAS)
	begin
		if (!nCLK_68KCLK)
		begin
			// posedge CLK_68KCLK
			if (!nAS)
			begin
				// Count down only after address valid
				if (WAIT_CNT) WAIT_CNT <= WAIT_CNT - 1'b1;
			end
		end
		else
		begin
			// negedge nAS
			if (nROM_ZONE)
				WAIT_CNT <= ~nROMWAIT;		// 0~1 or 1~2 wait cycles ?
			if (nPORT_ZONE)
				WAIT_CNT <= ~{nPWAIT0,nPWAIT1};
			else if (nBITW0)
				WAIT_CNT <= 1;
			else
				WAIT_CNT <= 0;
		end
	end

	wire nIO_ZONE;			// Internal
	wire nC1REGS_ZONE;	// Internal
	wire nROM_ZONE;		// Internal
	wire nWRAM_ZONE;		// Internal
	wire nPORT_ZONE;		// Internal
	wire nCTRL1_ZONE;		// Internal
	wire nICOM_ZONE;		// Internal
	wire nCTRL2_ZONE;		// Internal
	wire nSTATUSB_ZONE;	// Internal
	wire nLSPC_ZONE;		// Internal
	wire nCARD_ZONE;		// Internal
	wire nSROM_ZONE;		// Internal
	wire nSRAM_ZONE;		// Internal
	wire nWORDACCESS;		// Internal
	
	c1_regs C1REGS(nCTRL1_ZONE, nCTRL2_ZONE, nSTATUSB_ZONE, nICOM_ZONE, CONSOLE_MODE, nWP, nCD2, nCD1,
					P2_IN, P1_IN, RW, M68K_DATA);
	
	c1_wait C1WAIT(CLK_68KCLK, nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK, nDTACK);
	
	// 0xxxxx read/write
	assign nROM_ZONE = |{A23Z, A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// 1xxxxx read/write
	assign nWRAM_ZONE = |{A23Z, A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};
	
	// 2xxxxx read/write
	assign nPORT_ZONE = |{A23Z, A22Z, ~M68K_ADDR[20], M68K_ADDR[19]};
	
	// 3xxxxx read/write
	assign nIO_ZONE = |{A23Z, A22Z, ~M68K_ADDR[20], ~M68K_ADDR[19]};
	
	// 30xxxx 37xxxx even bytes read/write
	assign nC1REGS_ZONE = nUDS | |{nIO_ZONE, M68K_ADDR[18]};
	
	// 30xxxx 31xxxx even bytes read only
	assign nCTRL1_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[17], M68K_ADDR[16]};
	
	// 32xxxx 33xxxx even bytes read/write
	assign nICOM_ZONE = nC1REGS_ZONE | |{M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 34xxxx 37xxxx even bytes read only - not sure if M68K_ADDR[16] is used (up to 35FFFF only ?)
	assign nCTRL2_ZONE = nC1REGS_ZONE | ~RW | |{~M68K_ADDR[17]};

	// 30xxxx 31xxxx ?, odd bytes read only
	assign nDIPRD0 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[18], M68K_ADDR[17], M68K_ADDR[16]};
	
	// 32xxxx 33xxxx ?, odd bytes read only
	assign nDIPRD1 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 38xxxx 39xxxx odd bytes write only
	assign nBITW0 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[18], M68K_ADDR[17], M68K_ADDR[16]};
	
	// 3Axxxx 3Bxxxx odd bytes write only
	assign nBITW1 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[18], M68K_ADDR[17], ~M68K_ADDR[16]};
	
	// 38xxxx 39xxxx even bytes read only
	assign nSTATUSB_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[17], M68K_ADDR[16]};
	
	// 3Cxxxx 3Dxxxx - not sure if M68K_ADDR[16] is used (up to 3DFFFF only ?)
	assign nLSPC_ZONE = |{nIO_ZONE, ~M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 4xxxxx 7xxxxx
	assign nPAL = |{A23Z, ~A22Z};
	
	// 8xxxxx Bxxxxx
	assign nCARD_ZONE = |{~A23Z, A22Z};
	
	// Cxxxxx Cxxxxx
	assign nSROM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], M68K_ADDR[19]};
	
	// Dxxxxx Dxxxxx ?
	assign nSRAM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[20], ~M68K_ADDR[19]};

	assign nWORDACCESS = nLDS | nUDS;

	// Outputs:
	assign nROMOEL = ~RW | nLDS | nROM_ZONE | nDTACK;
	assign nROMOEU = ~RW | nUDS | nROM_ZONE | nDTACK;
	assign nPORTOEL = ~RW | nLDS | nPORT_ZONE | nDTACK;
	assign nPORTOEU = ~RW | nUDS | nPORT_ZONE | nDTACK;
	assign nPORTWEL = RW | nLDS | nPORT_ZONE | nDTACK;
	assign nPORTWEU = RW | nUDS | nPORT_ZONE | nDTACK;
	assign nPADRS = nPORT_ZONE | nDTACK;
	assign nWRL = ~RW | nLDS | nWRAM_ZONE | nDTACK;
	assign nWRU = ~RW | nUDS | nWRAM_ZONE | nDTACK;
	assign nWWL = RW | nLDS | nWRAM_ZONE | nDTACK;
	assign nWWU = RW | nUDS | nWRAM_ZONE | nDTACK;
	assign nSROMOEL = ~RW | nLDS | nSROM_ZONE | nDTACK;
	assign nSROMOEU = ~RW | nUDS | nSROM_ZONE | nDTACK;
	assign nSRAMOEL = ~RW | nLDS | nSRAM_ZONE | nDTACK;
	assign nSRAMOEU = ~RW | nUDS | nSRAM_ZONE | nDTACK;
	assign nSRAMWEL = RW | nLDS | nSRAM_ZONE | nDTACK;
	assign nSRAMWEU = RW | nUDS | nSRAM_ZONE | nDTACK;

	// Not sure about word access ?
	assign nLSPOE = RW | nWORDACCESS | nLSPC_ZONE | nDTACK;
	assign nLSPWE = ~RW | nWORDACCESS | nLSPC_ZONE | nDTACK;
	assign nCRDO = RW | nWORDACCESS | nCARD_ZONE | nDTACK;
	assign nCRDW = ~RW | nWORDACCESS | nCARD_ZONE | nDTACK;
	assign nCRDC = nCRDO & nCRDW;

endmodule

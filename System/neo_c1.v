// NeoGeo logic definition (simulation only)
// Copyright (C) 2018 Sean Gonsalves
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

`timescale 1ns/1ns

// Missing pin: VPA

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
	input [9:0] P1_IN,
	input [9:0] P2_IN,
	input nCD1, nCD2, nWP,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	inout [7:0] SDD,
	input nSDZ80R, nSDZ80W, nSDZ80CLR,
	input CLK_68KCLK,
	output nDTACK,
	output nBITW0, nBITW1, nDIPRD0, nDIPRD1,
	output nPAL,
	input SYSTEM_MODE
);

	wire nIO_ZONE;			// Internal
	wire nC1REGS_ZONE;	// Internal
	wire nROM_ZONE;		// Internal
	wire nWRAM_ZONE;		// Internal (external for PCB)
	wire nPORT_ZONE;		// Internal (external for PCB)
	wire nCTRL1_ZONE;		// Internal (external for PCB)
	wire nICOM_ZONE;		// Internal
	wire nCTRL2_ZONE;		// Internal (external for PCB)
	wire nSTATUSB_ZONE;	// Internal (external for PCB)
	wire nLSPC_ZONE;		// Internal
	wire nCARD_ZONE;		// Internal
	wire nSROM_ZONE;		// Internal
	wire nSRAM_ZONE;		// Internal (external for PCB)
	wire nWORDACCESS;		// Internal
	
	c1_regs C1REGS(nICOM_ZONE, RW, M68K_DATA, SDD, nSDZ80R, nSDZ80W, nSDZ80CLR, nSDW);
	
	c1_wait C1WAIT(CLK_68KCLK, nAS, nROM_ZONE, nPORT_ZONE, nCARD_ZONE, nROMWAIT, nPWAIT0,
					nPWAIT1, PDTACK, nDTACK);
	
	c1_inputs C1INPUTS(nCTRL1_ZONE, nCTRL2_ZONE, nSTATUSB_ZONE, M68K_DATA, P1_IN[9:0], P2_IN[9:0],
						nWP, nCD2, nCD1, SYSTEM_MODE);
	
	// 000000~0FFFFF read/write
	assign nROM_ZONE = |{A23Z, A22Z, M68K_ADDR[21], M68K_ADDR[20]};
	
	// 100000~1FFFFF read/write
	assign nWRAM_ZONE = |{A23Z, A22Z, M68K_ADDR[21], ~M68K_ADDR[20]};
	
	// 200000~2FFFFF read/write
	assign nPORT_ZONE = |{A23Z, A22Z, ~M68K_ADDR[21], M68K_ADDR[20]};
	
	// 300000~3FFFFF read/write
	assign nIO_ZONE = |{A23Z, A22Z, ~M68K_ADDR[21], ~M68K_ADDR[20]};
	
		// 300000~3FFFFE even bytes read/write
		assign nC1REGS_ZONE = nUDS | nIO_ZONE;
		
			// 300000~31FFFE even bytes read only
			assign nCTRL1_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
			
			// 320000~33FFFE even bytes read/write
			assign nICOM_ZONE = nC1REGS_ZONE | |{M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
			// 340000~35FFFE even bytes read only - Todo: MAME says A17 is used, see right below
			assign nCTRL2_ZONE = nC1REGS_ZONE | ~RW | |{M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17]};
			// 360000~37FFFF is not mapped ?

	// 30xxxx 31xxxx ?, odd bytes read only
	assign nDIPRD0 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 32xxxx 33xxxx ?, odd bytes read only
	assign nDIPRD1 = nLDS | ~RW | |{nIO_ZONE, M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	
	// 38xxxx 39xxxx odd bytes write only
	assign nBITW0 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 380000~39FFFE even bytes read only
	assign nSTATUSB_ZONE = nC1REGS_ZONE | ~RW | |{~M68K_ADDR[19], M68K_ADDR[18], M68K_ADDR[17]};
	
	// 3A0001~3BFFFF odd bytes write only
	assign nBITW1 = nLDS | RW | |{nIO_ZONE, ~M68K_ADDR[19], M68K_ADDR[18], ~M68K_ADDR[17]};
	// 3A0001~3BFFFF odd bytes read is not mapped ? To check
	
	// 3C0000~3DFFFF
	assign nLSPC_ZONE = |{nIO_ZONE, ~M68K_ADDR[19], ~M68K_ADDR[18], M68K_ADDR[17]};
	
	// 3E0000~3FFFFF is not mapped ? To check
	
	// 400000~7FFFFF
	assign nPAL_ZONE = |{A23Z, ~A22Z};
	
	// 800000~BFFFFF odd bytes ? To check, is A19~A17 used ? MAME limits to 800FFF, impossible ?
	assign nCARD_ZONE = nLDS | |{~A23Z, A22Z};
	
	// C00000~CFFFFF ? To check, is A19~A17 used ? MAME says no
	assign nSROM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[21], M68K_ADDR[20]};
	
	// D00000~DFFFFF ? To check, is A19~A17 used ? MAME says no
	assign nSRAM_ZONE = |{~A23Z, ~A22Z, M68K_ADDR[21], ~M68K_ADDR[20]};

	// Outputs:
	assign nROMOEL = ~RW | nLDS | nROM_ZONE | nAS;
	assign nROMOEU = ~RW | nUDS | nROM_ZONE | nAS;
	assign nPORTOEL = ~RW | nLDS | nPORT_ZONE | nAS;
	assign nPORTOEU = ~RW | nUDS | nPORT_ZONE | nAS;
	assign nPORTWEL = RW | nLDS | nPORT_ZONE | nAS;
	assign nPORTWEU = RW | nUDS | nPORT_ZONE | nAS;
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

	assign nPAL = nPAL_ZONE | nAS;
	
	// Todo: Check if TG68k duplicates byte on data bus on byte writes
	assign nLSPWE = RW | nUDS | nLSPC_ZONE | nAS;		// MAME says LSB write isn't mapped
	assign nLSPOE = ~RW | nUDS | nLSPC_ZONE | nAS;		// MAME says LSB write isn't mapped
	
	assign nCRDO = ~RW | nCARD_ZONE | nAS;
	assign nCRDW = RW | nCARD_ZONE | nAS;
	assign nCRDC = nCRDO & nCRDW;

endmodule

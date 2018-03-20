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

// All pins listed OK

// Signal to latch fix palette ? posedge 1MB + PCK2 ?
// Signal to latch sprite palette ? posedge 1MB + PCK1 ?

module neo_b1(
	input CLK_6MB,				// 1px
	input CLK_1MB,				// 3MHz 2px Even/odd pixel selection
	
	input [23:0] PBUS,		// Used to retrieve X position, SPR palette # and FIX palette # from LSPC
	input [7:0] FIXD,			// 2 fix pixels
	input PCK1,
	input PCK2,
	input CHBL,					// Force PA to zeros
	input BNKB,					// For Watchdog and PA
	input [3:0] GAD, GBD,	// 2 sprite pixels
	input [3:0] WE,			// LB writes
	input [3:0] CK,			// LB address counter clocks
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Load X positions
	input SS1, SS2,			// Buffer select for output
	input S1H1,					// 3MHz 2px Even/odd pixel selection
	
	input A23Z, A22Z,
	output [11:0] PA,			// Palette address bus
	
	input nLDS,					// For watchdog kick
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	output nHALT,				// Todo
	output nRESET,
	input nRST
);

	// Delay registers
	reg [7:0] SPR_PAL_REG;
	reg [3:0] FIX_PAL_REG;
	reg [7:0] FIXD_REG;
	
	// Line buffers address and data
	wire [7:0] LB_EVEN_A_ADDR;
	wire [7:0] LB_ODD_A_ADDR;
	wire [7:0] LB_EVEN_B_ADDR;
	wire [7:0] LB_ODD_B_ADDR;
	
	wire [11:0] LB_EVEN_DATA_IN;
	wire [11:0] LB_ODD_DATA_IN;
	
	wire [11:0] LB_EVEN_A_DATA_IN;
	wire [11:0] LB_ODD_A_DATA_IN;
	wire [11:0] LB_EVEN_B_DATA_IN;
	wire [11:0] LB_ODD_B_DATA_IN;
	
	wire [11:0] LB_EVEN_A_DATA_OUT;
	wire [11:0] LB_ODD_A_DATA_OUT;
	wire [11:0] LB_EVEN_B_DATA_OUT;
	wire [11:0] LB_ODD_B_DATA_OUT;
	
	wire [7:0] X_LOAD_VALUE_A;
	wire [7:0] X_LOAD_VALUE_B;

	// Pixel mixing
	wire [3:0] SPR_COLOR;
	wire [7:0] SPR_PAL;
	wire [3:0] FIX_COLOR;
	wire [3:0] COLOR;
	wire [7:0] PAL;
	wire [1:0] MUX_BA;
	wire [11:0] PA_VIDEO;
	
	reg PAL_SWITCH;
	
	
	// Note: nRESET is sync'd to frame start
	// To check: BNKB might have to be inverted (see Alpha68k K7:A)
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);


	// Just renaming
	assign BFLIP = TMS0;
	
	assign nWE_EVEN_A = WE[0];
	assign nWE_ODD_A = WE[1];
	assign nWE_EVEN_B = WE[2];
	assign nWE_ODD_B = WE[3];
	
	// Fix stuff checked on DE1 board
	// When are palettes latched from the P BUS ?
	// PCK* are sharing the edges, so it can't be them
	// CLK_1MB has just the right timing, but NEO-B1 must differentiate between SPR palette and FIX palette
	// Is this done with a S/R latch using PCK1/2 ? Let's try...
	assign PCK = (PCK1 | PCK2);
	
	always @(posedge PCK)
	begin
		if (PCK1)
			PAL_SWITCH <= 1'b0;	// Sprite palette comes next
		else if (PCK2)
			PAL_SWITCH <= 1'b1;	// Fix palette comes next
	end
	
	always @(posedge PCK1)
	begin
		FIX_PAL_REG <= PBUS[19:16];
	end
	
	always @(posedge PCK2)
	begin
		SPR_PAL_REG <= PBUS[23:16];
	end
	
	// Fix data delay
	always @(posedge ~S1H1)		// negedge
	begin
		FIXD_REG <= FIXD;
	end
	
	assign X_LOAD_VALUE_A = PBUS[7:0];
	assign X_LOAD_VALUE_B = PBUS[15:8];
	
	//assign DIR_OB_EA = 1;	//~(nBFLIP & 1);		// TODO: Probably whole display h-flip
	//assign DIR_OA_EB = 1;	//~(BFLIP & 1);		// TODO: Probably whole display h-flip
	
	// LB address counters:
	hc669_dual L12M13(CK[0], LD1, 1'b1, X_LOAD_VALUE_A, LB_EVEN_A_ADDR);
	hc669_dual N13N12(CK[1], LD1, 1'b1, X_LOAD_VALUE_B, LB_ODD_A_ADDR);
	
	hc669_dual K12L13(CK[2], LD2, 1'b1, X_LOAD_VALUE_A, LB_EVEN_B_ADDR);
	hc669_dual P13P12(CK[3], LD2, 1'b1, X_LOAD_VALUE_B, LB_ODD_B_ADDR);
	
	assign LB_EVEN_DATA_IN = {SPR_PAL_REG, GAD[2], GAD[3], GAD[0], GAD[1]};
	assign LB_ODD_DATA_IN = {SPR_PAL_REG, GBD[2], GBD[3], GBD[0], GBD[1]};
	
	// Switch between pixel (render) or backdrop (clear)
	assign LB_EVEN_A_DATA_IN = BFLIP ? LB_EVEN_DATA_IN : 12'b111111111111;
	assign LB_ODD_A_DATA_IN = BFLIP ? LB_ODD_DATA_IN : 12'b111111111111;
	assign LB_EVEN_B_DATA_IN = BFLIP ? 12'b111111111111 : LB_EVEN_DATA_IN;
	assign LB_ODD_B_DATA_IN = BFLIP ? 12'b111111111111 : LB_ODD_DATA_IN;
	
	linebuffer LB1(nWE_EVEN_A, LB_EVEN_A_ADDR, LB_EVEN_A_DATA_IN, LB_EVEN_A_DATA_OUT);
	linebuffer LB2(nWE_ODD_A, LB_ODD_A_ADDR, LB_ODD_A_DATA_IN, LB_ODD_A_DATA_OUT);
	
	linebuffer LB3(nWE_EVEN_B, LB_EVEN_B_ADDR, LB_EVEN_B_DATA_IN, LB_EVEN_B_DATA_OUT);
	linebuffer LB4(nWE_ODD_B, LB_ODD_B_ADDR, LB_ODD_B_DATA_IN, LB_ODD_B_DATA_OUT);
	
	// SS1 high: output buffer A
	// SS2 high: output buffer B
	
	// Maybe SS* instead of BFLIP
	// Maybe S1H1 instead of BFLIP
	assign MUX_BA = {SS1, S1H1};
							
	// K15, L15, N15, P15, K13, M15 Sprite color and palette muxes
	assign {SPR_PAL, SPR_COLOR} = 
							(MUX_BA == 2'b00) ? LB_EVEN_B_DATA_OUT :
							(MUX_BA == 2'b01) ? LB_ODD_B_DATA_OUT :
							(MUX_BA == 2'b10) ? LB_EVEN_A_DATA_OUT :
							LB_ODD_A_DATA_OUT;

	// $400000~$7FFFFF why not use nPAL ?
	// Not sure about inclusion of nAS
	assign nPAL_ACCESS = |{A23Z, ~A22Z, nAS};
	
	// Pixel mixing
	assign FIX_COLOR = S1H1 ? FIXD_REG[7:4] : FIXD_REG[3:0];
	assign FIX_OPAQUE = |{FIX_COLOR};
	assign COLOR = FIX_OPAQUE ? FIX_COLOR : SPR_COLOR;
	assign PAL = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG} : SPR_PAL;
	assign PA_VIDEO = CHBL ? 12'h000 : {PAL, COLOR};
	
	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -FIX pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ? PA_VIDEO : M68K_ADDR_L;

endmodule

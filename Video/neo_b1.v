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
	input PCK1,					// What for ?
	input PCK2,					// What for ?
	input CHBL,					// Force PA to zeros
	input BNKB,					// For Watchdog and PA
	input [3:0] GAD, GBD,	// 2 sprite pixels
	input [3:0] WE,			// LB writes
	input [3:0] CK,			// LB address counter clocks
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Load X positions
	input SS1, SS2,			// Buffer pair select for output ?
	input S1H1,					// 3MHz 2px Even/odd pixel selection ?
	
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
	reg [7:0] SPR_PAL_REG_A;
	reg [7:0] SPR_PAL_REG_B;
	reg [3:0] FIX_PAL_REG_A;
	reg [3:0] FIX_PAL_REG_B;
	reg [7:0] FIXD_REG_A;
	reg [7:0] FIXD_REG_B;
	reg [7:0] FIXD_REG_C;
	
	// +1 adders
	wire [3:0] P10_OUT;
	wire [3:0] N10_OUT;
	wire [3:0] P11_OUT;
	wire [3:0] N11_OUT;
	wire PLUS_ONE;
	
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

	// Pixel mixing
	wire [3:0] SPR_COLOR;
	wire [7:0] SPR_PAL;
	wire [3:0] FIX_COLOR;
	wire [3:0] COLOR;
	wire [7:0] PAL;
	wire [1:0] MUX_BA;
	wire [11:0] PA_VIDEO;
	
	wire nPA_OE;		// TODO
	reg PAL_SWITCH;
	wire [7:0] X_LOAD_VALUE;
	
	
	// Note: nRESET is sync'd to frame start
	// To check: BNKB might have to be inverted (see Alpha68k K7:A)
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);


	// Just renaming
	assign BFLIP = TMS0;
	assign nBFLIP = ~BFLIP;
	
	assign nWE_ODD_A = WE[0];
	assign nWE_EVEN_A = WE[1];
	assign nWE_ODD_B = WE[2];
	assign nWE_EVEN_B = WE[3];
	
	assign nLOAD_X_A = LD1;
	assign nLOAD_X_B = LD2;
	
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

	/*
	// Palettes latch from PBUS and delays
	always @(posedge CLK_1MB)
	begin
		if (PAL_SWITCH)
		begin
			FIX_PAL_REG_A <= PBUS[19:16];
			FIX_PAL_REG_B <= FIX_PAL_REG_A;
		end
		else
		begin
			SPR_PAL_REG_A <= PBUS[23:16];
			SPR_PAL_REG_B <= SPR_PAL_REG_A;
		end
	end
	*/
	
	always @(posedge PCK1)
	begin
		FIX_PAL_REG_A <= PBUS[19:16];
		FIX_PAL_REG_B <= FIX_PAL_REG_A;
	end
	
	always @(posedge PCK2)
	begin
		SPR_PAL_REG_A <= PBUS[23:16];
		SPR_PAL_REG_B <= SPR_PAL_REG_A;
	end
	
	// Fix data delay
	always @(posedge CLK_1MB)
	begin
		FIXD_REG_A <= FIXD;
		FIXD_REG_B <= FIXD_REG_A;
		FIXD_REG_C <= FIXD_REG_B;
	end
	
	// G3 (374): nOE seems used !
	/*always @(posedge S1H1)	// nLATCH_X on Alpha68k
	begin
		if (PAL_SWITCH)
			X_LOAD_VALUE <= PBUS[15:8];
	end*/
	assign X_LOAD_VALUE = PBUS[15:8];
	
	// G5:C
	assign PLUS_ONE = ~1'b1;	// TODO: Wrong !
	
	// Both of these output the exact same thing, something must be wrong
	assign {P10_C4, P10_OUT} = X_LOAD_VALUE[3:0] + PLUS_ONE;
	assign P11_OUT = X_LOAD_VALUE[7:4] + P10_C4;	// P11_C4 apparently not used
	assign {N10_C4, N10_OUT} = X_LOAD_VALUE[3:0] + PLUS_ONE;
	assign N11_OUT = X_LOAD_VALUE[7:4] + N10_C4;	// N11_C4 apparently not used
	
	// P6:C and P6:D
	// Render: Count up (X ->>>>)
	// Output: ???
	assign DIR_OB_EA = 1;	//~(nBFLIP & 1);		// TODO: Probably whole display h-flip
	assign DIR_OA_EB = 1;	//~(BFLIP & 1);		// TODO: Probably whole display h-flip
	
	// LB address counters:
	hc669_dual L12M13(CK[0], nLOAD_X_A, DIR_OA_EB, X_LOAD_VALUE, LB_ODD_A_ADDR);	// ?
	hc669_dual N13N12(CK[1], nLOAD_X_A, DIR_OA_EB, {N11_OUT, N10_OUT}, LB_EVEN_A_ADDR);
	hc669_dual K12L13(CK[2], nLOAD_X_B, DIR_OB_EA, X_LOAD_VALUE, LB_ODD_B_ADDR);	// ?
	hc669_dual P13P12(CK[3], nLOAD_X_B, DIR_OB_EA, {P11_OUT, P10_OUT}, LB_EVEN_B_ADDR);
	
	// Maybe SPR_PAL_REG_A is enough delay ?
	assign LB_EVEN_DATA_IN = {SPR_PAL_REG_A, GAD[2], GAD[3], GAD[0], GAD[1]};
	assign LB_ODD_DATA_IN = {SPR_PAL_REG_A, GBD[2], GBD[3], GBD[0], GBD[1]};
	
	// Switch between pixel (render) or backdrop (clear)
	assign LB_EVEN_A_DATA_IN = BFLIP ? 12'b111111111111 : LB_EVEN_DATA_IN;
	assign LB_EVEN_B_DATA_IN = BFLIP ? LB_EVEN_DATA_IN : 12'b111111111111;
	assign LB_ODD_A_DATA_IN = BFLIP ? 12'b111111111111 : LB_ODD_DATA_IN;
	assign LB_ODD_B_DATA_IN = BFLIP ? LB_ODD_DATA_IN : 12'b111111111111;
	
	linebuffer LB1(nWE_EVEN_A, LB_EVEN_A_ADDR, LB_EVEN_DATA_IN, LB_EVEN_A_DATA_OUT);
	linebuffer LB2(nWE_ODD_A, LB_ODD_A_ADDR, LB_ODD_DATA_IN, LB_ODD_A_DATA_OUT);
	linebuffer LB3(nWE_EVEN_B, LB_EVEN_B_ADDR, LB_EVEN_DATA_IN, LB_EVEN_B_DATA_OUT);
	linebuffer LB4(nWE_ODD_B, LB_ODD_B_ADDR, LB_ODD_DATA_IN, LB_ODD_B_DATA_OUT);
	
	// N4 and N7 ORs
	/*assign nOE_P18P20 = RBA | nWE_EVEN_A;
	assign nOE_P19P21 = RBB | nWE_EVEN_B;
	assign nOE_M18N18 = RBA | nWE_ODD_A;
	assign nOE_M19N19 = RBB | nWE_ODD_B;*/
	
	// Maybe SS* instead of BFLIP
	// Maybe S1H1 instead of BFLIP
	assign MUX_BA = {SS1, CLK_1MB};
							
	// K15, L15, N15, P15, K13, M15 Sprite color and palette muxes
	assign {SPR_PAL, SPR_COLOR} = 
							(MUX_BA == 2'b00) ? LB_EVEN_B_DATA_OUT :
							(MUX_BA == 2'b01) ? LB_ODD_B_DATA_OUT :
							(MUX_BA == 2'b10) ? LB_EVEN_A_DATA_OUT :
							LB_ODD_A_DATA_OUT;
	
	// --------------------------------------------------------------------------------
	
	// H10 & H11 Palette RAM address latches
	// nOE is used, certainly to gate outputs during CPU access
	/*assign PA_VIDEO = nPA_OE ? 12'bzzzzzzzzzzzz : PA_VIDEO_REG;
	always @(posedge CLK_PA)
	begin
		PA_VIDEO_REG <= {PAL, COLOR};
	end*/
	
	// $400000~$7FFFFF why not use nPAL ?
	// Not sure about inclusion of nAS
	assign nPAL_ACCESS = |{A23Z, ~A22Z, nAS};
	
	// Pixel mixing
	assign FIX_COLOR = CLK_1MB ? FIXD_REG_C[3:0] : FIXD_REG_C[7:4];
	assign FIX_OPAQUE = |{FIX_COLOR};
	assign COLOR = FIX_OPAQUE ? FIX_COLOR : SPR_COLOR;
	assign PAL = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG_B} : SPR_PAL;
	assign PA_VIDEO = CHBL ? 12'h000 : {PAL, COLOR};
	
	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -FIX pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ? PA_VIDEO : M68K_ADDR_L;

endmodule

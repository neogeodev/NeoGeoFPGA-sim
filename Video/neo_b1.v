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

module neo_b1(
	input CLK_6MB,				// 1px
	input CLK_1MB,				// 3MHz 2px Even/odd pixel selection
	
	input [23:0] PBUS,		// Used to retrieve LB addresses loads, SPR palette # and FIX palette # from LSPC
	input [7:0] FIXD,			// 2 fix pixels
	input PCK1,
	input PCK2,
	input CHBL,					// Force PA to zeros
	input BNKB,					// For Watchdog and PA
	input [3:0] GAD, GBD,	// 2 sprite pixels
	input WE1,					// LB writes
	input WE2,
	input WE3,
	input WE4,
	input CK1,					// LB address counter clocks
	input CK2,
	input CK3,
	input CK4,
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Load LB addresses
	input SS1, SS2,			// Buffer select for render/clearing
	input S1H1,					// 3MHz offset from CLK_1MB
	
	input A23I, A22I,
	output [11:0] PA,			// Palette address bus
	
	input nLDS,					// For watchdog kick
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	output nHALT,
	output nRESET,
	input nRST
);

	reg nCPU_ACCESS;
	reg [7:0] FIXD_REG;
	wire [3:0] FIX_COLOR;
	wire [3:0] SPR_COLOR;
	wire [11:0] PA_MUX_A;
	wire [11:0] PA_MUX_B;
	wire [11:0] RAM_MUX_OUT;
	reg [11:0] PA_VIDEO;
	wire [1:0] MUX_BA;
	// Line buffers address and data
	wire [7:0] RAMTL_ADDR;
	wire [7:0] RAMTR_ADDR;
	wire [7:0] RAMBL_ADDR;
	wire [7:0] RAMBR_ADDR;
	wire [11:0] RAMTL_WR;
	wire [11:0] RAMTR_WR;
	wire [11:0] RAMBL_WR;
	wire [11:0] RAMBR_WR;
	wire [11:0] RAMTL_RD;
	wire [11:0] RAMTR_RD;
	wire [11:0] RAMBL_RD;
	wire [11:0] RAMBR_RD;
	// Delay registers
	reg [3:0] FIX_PAL_REG;
	reg [7:0] TL_PAL_REG;
	reg [7:0] TR_PAL_REG;
	reg [7:0] BL_PAL_REG;
	reg [7:0] BR_PAL_REG;
	// Buffer address counters
	wire [7:0] MUX_A;
	reg [7:0] COUNTER_A;
	wire [7:0] MUX_B;
	reg [7:0] COUNTER_B;
	wire [7:0] MUX_C;
	reg [7:0] COUNTER_C;
	wire [7:0] MUX_D;
	reg [7:0] COUNTER_D;
	wire [3:0] GAD_GATED_A;
	wire [3:0] GBD_GATED_A;
	wire [3:0] GAD_GATED_B;
	wire [3:0] GBD_GATED_B;
	// Debug
	reg [7:0] LATCH_A;
	reg [7:0] LATCH_B;
	reg [7:0] LATCH_C;
	reg [7:0] LATCH_D;
	
	parameter TEST_MODE = 0;	// "XMM" pin
	
	//initial
	//	nCPU_ACCESS <= 1'b1;		// Only useful when the 68k is disabled
	
	assign nHALT = nRESET;		// Yup (also those are open-collector)

	assign RAMBL_ADDR = LATCH_A;	// Checked OK
	assign RAMBR_ADDR = LATCH_B;	// Checked OK
	assign RAMTL_ADDR = LATCH_C;	// Checked OK
	assign RAMTR_ADDR = LATCH_D;	// Checked OK
	assign RAMBL_WE = ~WE1;
	assign RAMBR_WE = ~WE2;
	assign RAMTL_WE = ~WE3;
	assign RAMTR_WE = ~WE4;
	assign RAMBL_RE = ~RAMBL_WE;
	assign RAMBR_RE = ~RAMBR_WE;
	assign RAMTL_RE = ~RAMTL_WE;
	assign RAMTR_RE = ~RAMTR_WE;

	// 2px fix data reg
	// BEKU AKUR...
	always @(posedge CLK_1MB)
		FIXD_REG <= FIXD;
	
	// Fix odd/even pixel select
	// BEVU AWEQ...
	assign FIX_COLOR = S1H1 ? FIXD_REG[7:4] : FIXD_REG[3:0];

	// IDUF
	assign FIX_OPAQUE = |{FIX_COLOR};

	// GETU FUCA...
	always @(posedge PCK1)
		FIX_PAL_REG <= PBUS[19:16];
	
	
	// MOZA MAKO...
	assign GAD_GATED_A = GAD | {4{SS2}};
	// MAPE MUCA...
	assign RAMTL_WR[3:0] = TEST_MODE ? GBD : GAD_GATED_A;
	
	// NEGA NACO...
	assign GBD_GATED_A = GBD | {4{SS1}};
	// NOFA NYKO...
	assign RAMBR_WR[3:0] = TEST_MODE ? GBD : GBD_GATED_A;

	// NUDE NOSY...
	assign GAD_GATED_B = GAD | {4{SS1}};
	// NODO NUJA...
	assign RAMBL_WR[3:0] = TEST_MODE ? GBD : GAD_GATED_B;
	
	// NUDE NOSY...
	assign GBD_GATED_B = GBD | {4{SS2}};
	// LANO LODO...
	assign RAMTR_WR[3:0] = TEST_MODE ? GBD : GBD_GATED_B;
	
	
	
	always @(posedge PCK2)
	begin
		BL_PAL_REG <= PBUS[23:16];		// MANA NAKA...
		BR_PAL_REG <= PBUS[23:16];		// MESY NEPA...
		TL_PAL_REG <= PBUS[23:16];		// JETU JUMA...
		TR_PAL_REG <= PBUS[23:16];		// GENA HARU...
	end
	
	assign RAMBL_WR[11:4] = BL_PAL_REG | {8{SS1}};	// MORA NOKU...
	assign RAMBR_WR[11:4] = BR_PAL_REG | {8{SS1}};	// MECY NUXA...
	assign RAMTL_WR[11:4] = TL_PAL_REG | {8{SS2}};	// JEZA JODE...
	assign RAMTR_WR[11:4] = TR_PAL_REG | {8{SS2}};	// GUSU HYKU...
	
	/*
	assign VORU = S1H1 & TMS0;
	assign VOTO = S1H1 & ~TMS0;
	assign VEZA = ~S1H1 & TMS0;
	assign VOKE = ~S1H1 & ~TMS0;
	*/

	// Load/count select
	// RUFY QAZU...
	assign MUX_A = LD1 ? (COUNTER_A + 1) : PBUS[7:0];

	// Address counter update
	// REVA QEVU...
	always @(posedge CK1)
		COUNTER_A <= MUX_A;
	
	// NACY OKYS...
	always @(*)
		if (WE1) LATCH_A <= COUNTER_A;

	// Load/count select
	// PECU QUNY...
	assign MUX_B = LD1 ? (COUNTER_B + 1) : PBUS[15:8];

	// Address counter update
	// PAJE QATA...
	always @(posedge CK2)
		COUNTER_B <= MUX_B;
	
	// PEXU QUVU...
	always @(*)
		if (WE2) LATCH_B <= COUNTER_B;
	
	// Load/count select
	// BAME CUNU...
	assign MUX_C = LD2 ? (COUNTER_C + 1) : PBUS[7:0];

	// Address counter update
	// BEWA CENA...
	always @(posedge CK3)
		COUNTER_C <= MUX_C;
	
	// ERYV ENOG...
	always @(*)
		if (WE3) LATCH_C <= COUNTER_C;
	
	// Load/count select
	// EGED DUGA...
	assign MUX_D = LD2 ? (COUNTER_D + 1) : PBUS[15:8];

	// Address counter update
	// EPAQ DAFU...
	always @(posedge CK4)
		COUNTER_D <= MUX_D;
	
	// EDYZ ASYX...
	always @(*)
		if (WE4) LATCH_D <= COUNTER_D;
	
	
	// JAGU JURA...
	always @(negedge nAS)
		nCPU_ACCESS <= A23I | ~A22I;
	
	// Note: nRESET is sync'd to frame start
	watchdog WD(nLDS, RW, A23I, A22I, M68K_ADDR_U, BNKB, nHALT, nRESET, nRST);
	
	linebuffer RAMBL(RAMBL_ADDR, RAMBL_WR, RAMBL_RD, RAMBL_RE, RAMBL_WE);
	linebuffer RAMBR(RAMBR_ADDR, RAMBR_WR, RAMBR_RD, RAMBR_RE, RAMBR_WE);
	linebuffer RAMTL(RAMTL_ADDR, RAMTL_WR, RAMTL_RD, RAMTL_RE, RAMTL_WE);
	linebuffer RAMTR(RAMTR_ADDR, RAMTR_WR, RAMTR_RD, RAMTR_RE, RAMTR_WE);
	
	assign MUX_BA = {TMS0, S1H1};
	
	// Output buffer select
	// MEGA MAKA MEJU ORUG...
	assign RAM_MUX_OUT = 
							(MUX_BA == 2'b00) ? RAMBR_RD :
							(MUX_BA == 2'b01) ? RAMBL_RD :
							(MUX_BA == 2'b10) ? RAMTR_RD :
							RAMTL_RD;
	
	// Fix/Sprite/Blanking select
	// KUQA KUTU JARA...
	assign PA_MUX_A = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG, FIX_COLOR} : RAM_MUX_OUT;
	assign PA_MUX_B = CHBL ? 12'h000 : PA_MUX_A;

	// KAWE KESE...
	always @(posedge CLK_6MB)
		PA_VIDEO <= PA_MUX_B;
	
	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -Fix pixel if opaque
	// -Line buffer (sprites) output is last
	// KUTE KENU...
	assign PA = nCPU_ACCESS ? PA_VIDEO : M68K_ADDR_L;

endmodule

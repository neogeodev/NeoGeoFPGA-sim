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
	
	input [23:0] PBUS,		// Used to retrieve X position, SPR palette # and FIX palette # from LSPC
	input [7:0] FIXD,			// 2 fix pixels
	input PCK1,
	input PCK2,
	input CHBL,					// Force PA to zeros
	input BNKB,					// For Watchdog and PA
	input [3:0] GAD, GBD,	// 2 sprite pixels
	input [3:0] WE,			// LB writes
	input CK1,					// LB address counter clocks
	input CK2,
	input CK3,
	input CK4,
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
	output nHALT,
	output nRESET,
	input nRST
);

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
	reg [7:0] SPR_PAL_REG_A;
	reg [3:0] FIX_PAL_REG;
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
	// Shift registers
	reg [2:0] SR_WUDO_REG;
	reg [2:0] SR_MAVO_REG;
	
	assign nHALT = nRESET;	// Yup (also those are open-collector)

	// 2px fix data reg
	// BEKU AKUR...
	always @(posedge CLK_1MB)		// negedge ?
	begin
		FIXD_REG <= FIXD;
	end
	
	// Fix odd/even pixel select
	// BEVU AWEQ...
	assign FIX_COLOR = S1H1 ? FIXD_REG[7:4] : FIXD_REG[3:0];		// Swap ?

	// IDUF
	assign FIX_OPAQUE = |{FIX_COLOR};

	// Fix/Sprite/Blanking select
	// KUQA KUTU JARA...
	assign PA_MUX_A = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG, FIX_COLOR} : RAM_MUX_OUT;
	assign PA_MUX_B = CHBL ? 12'h000 : PA_MUX_A;

	// KAWE KESE...
	always @(posedge CLK_6MB)
	begin
		PA_VIDEO <= PA_MUX_B;
	end

	// GETU FUCA...
	always @(posedge PCK1)
	begin
		FIX_PAL_REG <= PBUS[19:16];
	end
	
	// MESY NEPA...
	always @(posedge PCK2)
	begin
		SPR_PAL_REG_A <= PBUS[23:16];
	end
	
	
	// WUDO
	always @(posedge TODO_CLK1)
	begin
		SR_WUDO_REG <= {SR_WUDO_REG[2:1], ~SS2};
	end
	
	// MOZA MAKO...
	assign GAD_GATED_A = SR_WUDO_REG[2] ? GAD : 4'b0000;
	
	// MAPE MUCA...
	assign RAMTL_WR[3:0] = TODO_SW_A ? GAD_GATED_A : GBD;
	
	
	// MAVO
	always @(posedge TODO_CLK2)
	begin
		SR_MAVO_REG <= {SR_MAVO_REG[2:1], ~SS1};
	end
	
	// NEGA NACO...
	assign GBD_GATED_A = SR_MAVO_REG[2] ? GBD : 4'b0000;
	
	// NOFA NYKO...
	assign RAMBR_WR[3:0] = TODO_SW_B ? GBD_GATED_A : GBD;		// Shouldn't this be GAD ?
	

	
	// NUDE NOSY...
	assign GAD_GATED_B = ~SS1 ? GAD : 4'b0000;
	
	// NODO NUJA...
	assign RAMBL_WR[3:0] = TODO_SW_C ? GAD_GATED_B : ~SS1;	// WTF is up with ~SS1 ?
	
	
	
	// Output buffer select
	// MEGA MAKA MEJU ORUG...
	assign RAM_MUX_OUT = 
							(MUX_BA == 2'b00) ? RAMTL_RD :
							(MUX_BA == 2'b01) ? RAMTR_RD :
							(MUX_BA == 2'b10) ? RAMBL_RD :
							RAMBR_RD;

	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -Fix pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = PAL_ACCESS ? M68K_ADDR_L : PA_VIDEO;

	// Load/count select
	// RUFY QAZU...
	assign MUX_A = LD1 ? (COUNTER_A + 1) : PBUS[7:0];	// TODO: Check LD1, should be ok

	// Address counter update
	// REVA QEVU...
	always @(posedge CK1)
	begin
		COUNTER_A <= MUX_A;
	end

	// Load/count select
	// PECU QUNY...
	assign MUX_B = LD1 ? (COUNTER_B + 1) : PBUS[15:8];

	// Address counter update
	// PAJE QATA...
	always @(posedge CK2)
	begin
		COUNTER_B <= MUX_B;
	end
	
	// Load/count select
	// BAME CUNU...
	assign MUX_C = LD2 ? (COUNTER_C + 1) : PBUS[7:0];

	// Address counter update
	// BEWA CENA...
	always @(posedge CK3)
	begin
		COUNTER_C <= MUX_C;
	end
	
	// Load/count select
	// EGED DUGA...
	assign MUX_D = LD2 ? (COUNTER_D + 1) : PBUS[15:8];

	// Address counter update
	// EPAQ DAFU...
	always @(posedge CK4)
	begin
		COUNTER_D <= MUX_D;
	end
	
	
	
	// Note: nRESET is sync'd to frame start
	// To check: BNKB might have to be inverted (see Alpha68k K7:A)
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);
	
	// LB address counters:
	//hc669_dual L12M13(CK[0], LD1, 1'b1, X_LOAD_VALUE_A, RAMTL_ADDR);
	//hc669_dual N13N12(CK[1], LD1, 1'b1, X_LOAD_VALUE_B, RAMTR_ADDR);
	//hc669_dual K12L13(CK[2], LD2, 1'b1, X_LOAD_VALUE_A, RAMBL_ADDR);
	//hc669_dual P13P12(CK[3], LD2, 1'b1, X_LOAD_VALUE_B, RAMBR_ADDR);
	
	linebuffer RAMTL(RAMTL_ADDR, RAMTL_WR, RAMTL_RD, RAMTL_RE, RAMTL_WE);
	linebuffer RAMTR(RAMTR_ADDR, RAMTR_WR, RAMTR_RD, RAMTR_RE, RAMTR_WE);
	linebuffer RAMBL(RAMBL_ADDR, RAMBL_WR, RAMBL_RD, RAMBL_RE, RAMBL_WE);
	linebuffer RAMBR(RAMBR_ADDR, RAMBR_WR, RAMBR_RD, RAMBR_RE, RAMBR_WE);
	
	// SS1 high: output buffer A
	// SS2 high: output buffer B

	// $400000~$7FFFFF why not use nPAL ?
	// Not sure about inclusion of nAS
	assign PAL_ACCESS = ~|{A23Z, ~A22Z, nAS};

endmodule

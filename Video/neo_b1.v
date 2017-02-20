`timescale 1ns/1ns

// All pins listed OK

// Signal to latch fix palette ? posedge 1MB + PCK2 ?
// Signal to latch sprite palette ? posedge 1MB + PCK1 ?
// Signal to latch fix data ? 8 pixel delay = 4 bytes = 6M/8 ?
// Signal to latch x position ? S1H1 + ?

module neo_b1(
	input CLK_6MB,				// 1px
	input CLK_1MB,				// 2px Even/odd pixel selection ?
	
	input [23:0] PBUS,		// Used for X position, SPR palette # and FIX palette #
	input [7:0] FIXD,			// Color data
	input PCK1,					// What for ?
	input PCK2,					// What for ?
	input CHBL,					// Set PA to zeros
	input BNKB,					// What for ?
	input [3:0] GAD, GBD,	// Color data
	input [3:0] WE,			// LB writes
	input [3:0] CK,			// LB clocks
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Latch x position of sprite from P bus ?
	input SS1, SS2,			// Up/Down for LB address counters ?
	input S1H1,					// ?
	
	input A23Z, A22Z,
	output [11:0] PA,
	
	input nLDS,					// For watchdog
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	output nHALT,				// Todo
	output nRESET,
	input nRST
);

	// Tests...
	assign BFLIP = TMS0;			// Inverted ?
	assign nLATCH_X_A = LD1;
	assign nLATCH_X_B = LD2;
	assign nWE_ODD_A = WE[0];
	assign nWE_ODD_B = WE[1];
	assign nWE_EVEN_A = WE[2];
	assign nWE_EVEN_B = WE[3];
	
	wire RBA, RBB;
	
	// -------------------------------- Alpha68k logic --------------------------------
	
	wire [3:0] P10_OUT;
	wire [3:0] N10_OUT;
	wire [3:0] P11_OUT;
	wire [3:0] N11_OUT;
	wire PLUS_ONE;
	
	wire [7:0] LB_EVEN_A_ADDR;
	wire [7:0] LB_EVEN_B_ADDR;
	wire [7:0] LB_ODD_A_ADDR;
	wire [7:0] LB_ODD_B_ADDR;
	wire [11:0] LB_EVEN_A_DATA;
	wire [11:0] LB_EVEN_B_DATA;
	wire [11:0] LB_ODD_A_DATA;
	wire [11:0] LB_ODD_B_DATA;
	
	reg [7:0] SPR_PAL_REG_A;
	reg [7:0] SPR_PAL_REG_B;
	reg [3:0] FIX_PAL_REG;
	
	reg [7:0] FIXD_REG_A;
	reg [7:0] FIXD_REG_B;
	
	wire [3:0] FIX_COLOR;
	wire [3:0] SPR_COLOR;
	wire [3:0] COLOR;
	wire [7:0] SPR_PAL;
	
	wire [7:0] PAL;
	
	wire SNKCLK_26;	// TODO
	wire SNKCLK_40;	// TODO
	wire nBFLIP;
	wire nLATCH_X;		// TODO
	reg [7:0] SPRX;
	wire K2_1;			// TODO
	wire K8_6;			// TODO
	wire P6_16;			// TODO
	wire HFLIP;			// TODO
	wire TODO_FIXCLK;	// TODO
	wire PACLK;			// TODO
	reg [11:0] PA_VIDEO;
	
	assign PA = PA_VIDEO;	// CPU acces switch here !
	
	assign nBFLIP = ~BFLIP;
	
	// G3 (374): nOE seems used !
	always @(posedge nLATCH_X)
	begin
		SPRX <= PBUS[15:8];	// SPRX should be part of P_BUS
	end
	
	// G5:C
	// assign PLUS_ONE = ~?;
	
	assign {P10_C4, P10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign P11_OUT = SPRX[7:4] + P10_C4;		// P11_C4 apparently not used
	
	assign {N10_C4, N10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign N11_OUT = SPRX[7:4] + N10_C4;		// N11_C4 apparently not used
	
	// K2
	assign K2_4 = K2_1 ? 1'b1 : nLATCH_X;	// TODO
	assign K2_7 = K2_1 ? nLATCH_X : 1'b1;
	assign K2_9 = K2_1 ? K8_6 : 1'b1;		// TODO
	assign K2_12 = K2_1 ? 1'b1 : K8_6;		// TODO
	
	// K5:C
	assign nLOAD_X_A = K2_7 & K2_12;
	assign nLOAD_X_B = K2_4 & K2_9;		// To check !
	
	// P6:C & P6:D
	assign UPDOWN_A = ~(nBFLIP & HFLIP);
	assign UPDOWN_B = ~(BFLIP & HFLIP);
	
	// Counters:
	hc669_dual P13P12(CLK_EVEN_A, nLOAD_X_A, UPDOWN_A, {P11_OUT, P10_OUT}, LB_EVEN_B_ADDR[7:0]);
	hc669_dual N13N12(CLK_EVEN_B, nLOAD_X_B, UPDOWN_B, {N11_OUT, N10_OUT}, LB_EVEN_A_ADDR[7:0]);
	hc669_dual K12L13(CLK_EVEN_A, nLOAD_X_A, UPDOWN_A, {SPRX[7:4], SPRX[3:0]} , LB_ODD_B_ADDR[7:0]);	// ?
	hc669_dual L12M13(CLK_EVEN_B, nLOAD_X_B, UPDOWN_B, {SPRX[7:4], SPRX[3:0]} , LB_ODD_A_ADDR[7:0]);	// ?
	
	// Sprite palette latch G6 (273):
	always @(posedge 1'bz)	// TODO
	begin
		// Is nMR used ?
		SPR_PAL_REG_A <= PBUS[23:16];	// SPR_PAL should be part of P_BUS
	end
	// Sprite palette latch G1 (273):
	always @(posedge 1'bz)	// TODO
	begin
		// Is nMR used ?
		SPR_PAL_REG_B <= SPR_PAL_REG_A;
	end
	
	// J6 (174) TODO, no nMR
	always @(posedge 1'bz)
		FIX_PAL_REG <= PBUS[19:16];	// FIX_PAL should be part of P_BUS
	
	// TODO: Z state in read mode
	// HC367s - 12'b111111111111 are caused by pullups (see PCB), allows for clearing
	assign LB_EVEN_A_DATA = nOE_P18P20 ? 12'b111111111111 : {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]};
	assign LB_EVEN_B_DATA = nOE_P19P21 ? 12'b111111111111 : {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]};
	assign LB_ODD_A_DATA = nOE_M18N18 ? 12'b111111111111 : {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]};
	assign LB_ODD_B_DATA = nOE_M19N19 ? 12'b111111111111 : {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]};
	
	// ORs
	assign nOE_P18P20 = RBA | nWE_EVEN_A;
	assign nOE_P19P21 = RBB | nWE_EVEN_B;
	assign nOE_M18N18 = RBA | nWE_ODD_A;
	assign nOE_M19N19 = RBB | nWE_ODD_B;
	
	// FIX stuff, FIX/SPR mux and PA output
	
	// L5
	always @(posedge TODO_FIXCLK)
		FIXD_REG_A <= FIXD;
	// M5
	always @(posedge TODO_FIXCLK)
		FIXD_REG_B <= FIXD_REG_A;
	
	// M4 Odd/even tile pixel demux
	assign FIX_COLOR = SNKCLK_40 ? {FIXD_REG_B[7], FIXD_REG_B[5], FIXD_REG_B[3], FIXD_REG_B[1]} :
												{FIXD_REG_B[6], FIXD_REG_B[4], FIXD_REG_B[2], FIXD_REG_B[0]};
	// N4 & M6 Opacity detection
	assign nSPR_FIX_SW = |{FIX_COLOR};
	
	assign MUX_BA = {P6_16, SNKCLK_40};
	
	// K15 & L15 Sprite color bits mux
	assign SPR_COLOR = (MUX_BA == 2'b00) ? LB_EVEN_B_DATA[3:0] :
								(MUX_BA == 2'b01) ? LB_ODD_B_DATA[3:0] :
								(MUX_BA == 2'b10) ? LB_EVEN_A_DATA[3:0] :
								LB_ODD_A_DATA[3:0];
	
	// J12 Sprite/fix color bits mux
	assign COLOR = nSPR_FIX_SW ? FIX_COLOR : SPR_COLOR;
								
	// N15, P15, K13, M15 Sprite palette bits mux
	assign SPR_PAL = (MUX_BA == 2'b00) ? LB_EVEN_B_DATA[11:4] :
							(MUX_BA == 2'b01) ? LB_ODD_B_DATA[11:4] :
							(MUX_BA == 2'b10) ? LB_EVEN_A_DATA[11:4] :
							LB_ODD_A_DATA[11:4];
	
	// H12 & H9 Sprite/fix palette bits mux
	assign PAL = nSPR_FIX_SW ? {4'b0000, FIX_PAL_REG} : SPR_PAL;
	
	// H10 & H11 Palette RAM address latches
	// nOE is used !
	always @(posedge PACLK)
	begin
		PA_VIDEO <= {PAL, COLOR};
	end

	
	// --------------------------------------------------------------------------------
	
	
	// $400000~$7FFFFF why not use nPAL ?
	assign nPAL_ACCESS = |{A23Z, ~A22Z};	// |nAS ?
	
	// Todo: Wrong, nRESET is sync'd to frame start
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);

	/*
	linebuffer LB1(CK[0], WE[0], PCK1, PBUS[15:8], LBDATA_A_E, TMS0);
	linebuffer LB2(CK[1], WE[1], PCK1, PBUS[15:8], LBDATA_A_O, TMS0);
	linebuffer LB3(CK[2], WE[2], PCK2, PBUS[15:8], LBDATA_B_E, ~TMS0);
	linebuffer LB4(CK[3], WE[3], PCK2, PBUS[15:8], LBDATA_B_O, ~TMS0);
	
	assign LBDATA_A_E = TMS0 ? {GAD, SPR_PAL} : 12'bzzzzzzzzzzzz;
	assign LBDATA_A_O = TMS0 ? {GBD, SPR_PAL} : 12'bzzzzzzzzzzzz;
	assign LBDATA_B_E = TMS0 ? 12'bzzzzzzzzzzzz : {GAD, SPR_PAL};
	assign LBDATA_B_O = TMS0 ? 12'bzzzzzzzzzzzz : {GBD, SPR_PAL};
	
	assign LBDATA_OUT = TMS0 ?
								CLK_1MB ?
									LBDATA_B_O :	// TMS0,1MB=11
									LBDATA_B_E		// TMS0,1MB=10
								:
								CLK_1MB ?
									LBDATA_A_O :	// TMS0,1MB=01
									LBDATA_A_E;		// TMS0,1MB=00

	assign FIX_PIXEL = CLK_1MB ? FIX_DATA[7:4] : FIX_DATA[3:0];		// Opposite ?
	assign FIX_OPAQUE = |{FIX_PIXEL};
	
	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -FIX pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ?
					CHBL ? 12'b000000000000 :
					FIX_OPAQUE ? {FIX_PAL, FIX_PIXEL} :
					LBDATA_OUT :
					M68K_ADDR_L;
	
	// Todo: Compare with Alpha68k schematic, maybe identical
	// Todo: Check sync of 1H1, 1HB on real hw
	// Does this work with PCK* signals ?
	wire nS1H1;
	assign nS1H1 = ~S1H1;
	always @(posedge S1H1 or posedge nS1H1)
	begin
		if (S1H1)
		begin
			// Latch 2 pixels and palette
			FIX_DATA <= FIXD;
			FIX_PAL <= PBUS[19:16];
		end
		else
		begin
			// Only latch 2 new pixels
			FIX_DATA <= FIXD;
		end
	end
	*/

endmodule

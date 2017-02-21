`timescale 1ns/1ns

// All pins listed OK

// Signal to latch fix palette ? posedge 1MB + PCK2 ?
// Signal to latch sprite palette ? posedge 1MB + PCK1 ?
// Signal to latch fix data ? 8 pixel delay = 4 bytes = 6M/8 ?
// Signal to latch x position ? S1H1 + ?

module neo_b1(
	input CLK_6MB,				// 1px
	input CLK_1MB,				// 3MHz 2px Even/odd pixel selection ?
	
	input [23:0] PBUS,		// Used for X position, SPR palette # and FIX palette #
	input [7:0] FIXD,			// 2 fix pixels
	input PCK1,					// What for ?
	input PCK2,					// What for ?
	input CHBL,					// Force PA to zeros
	input BNKB,					// What for ? Watchdog ? PA ?
	input [3:0] GAD, GBD,	// 2 sprite pixels
	input [3:0] WE,			// LB writes
	input [3:0] CK,			// LB address counter clocks
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Load x positions
	input SS1, SS2,			// Up/Down for LB address counters ?
	input S1H1,					// 3MHz 2px Even/odd pixel selection ?
	
	input A23Z, A22Z,
	output [11:0] PA,			// Palette address bus
	
	input nLDS,					// For watchdog
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	output nHALT,				// Todo
	output nRESET,
	input nRST
);

	// Testing...
	// Connects to Alpha68k stuff
	
	reg BFLIP;
	wire J8_12;
	
	// This might be in LSPC, BFLIP = TMS0
	always @(posedge SNKCLK_26)
		BFLIP <= J8_12;
	
	assign nBFLIP = ~BFLIP;
	
	// BFLIP = 0 : B OUTPUT, A WRITE
	// BFLIP = 1 : A OUTPUT, B WRITE
	
	assign nLATCH_X_A = LD1;
	assign nLATCH_X_B = LD2;
	assign nWE_ODD_A = WE[0];
	assign nWE_ODD_B = WE[1];
	assign nWE_EVEN_A = WE[2];
	assign nWE_EVEN_B = WE[3];
	
	// ?
	assign CLK_OB_EA = CK[0];
	assign CLK_OA_EB = CK[1];
	// Some CK[] might be RBA and RBB !
	
	// Opposite ?
	assign nLOAD_X_A = LD1;
	assign nLOAD_X_B = LD2;

	// ?
	assign SNKCLK_40 = CLK_1MB;	// Or S1H1 ?
	
	
	
	
	wire RBA, RBB;
	
	// -------------------------------- Alpha68k logic --------------------------------
	
	// +1 adders
	wire [3:0] P10_OUT;
	wire [3:0] N10_OUT;
	wire [3:0] P11_OUT;
	wire [3:0] N11_OUT;
	wire PLUS_ONE;
	
	// Line buffers address and data
	wire [7:0] LB_EVEN_A_ADDR;
	wire [7:0] LB_EVEN_B_ADDR;
	wire [7:0] LB_ODD_A_ADDR;
	wire [7:0] LB_ODD_B_ADDR;
	wire [11:0] LB_EVEN_A_DATA;
	wire [11:0] LB_EVEN_B_DATA;
	wire [11:0] LB_ODD_A_DATA;
	wire [11:0] LB_ODD_B_DATA;
	
	// Byte delays
	reg [7:0] SPR_PAL_REG_A;
	reg [7:0] SPR_PAL_REG_B;
	reg [7:0] FIXD_REG_A;
	reg [7:0] FIXD_REG_B;
	
	reg [3:0] FIX_PAL_REG;
	
	wire [3:0] FIX_COLOR;
	wire [3:0] SPR_COLOR;
	wire [3:0] COLOR;
	wire [7:0] SPR_PAL;
	wire [7:0] PAL;
	
	wire FIX_OPAQUE;
	
	wire SNKCLK_26;	// TODO
	wire nLATCH_X;		// TODO
	reg [7:0] SPRX;
	wire HFLIP;			// TODO
	wire TODO_FIXCLK;	// TODO
	wire CLK_PA;		// TODO
	wire nPA_OE;		// TODO
	reg [11:0] PA_VIDEO_REG;
	wire [11:0] PA_VIDEO;
	
	assign PA = PA_VIDEO;	// CPU acces switch here !
	
	// G3 (374): nOE seems used !
	always @(posedge nLATCH_X)
	begin
		SPRX <= PBUS[15:8];	// SPRX should be part of P_BUS
	end
	
	// G5:C
	// assign PLUS_ONE = ~?;
	
	// Both of these output the exact same thing, something must be wrong
	assign {P10_C4, P10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign P11_OUT = SPRX[7:4] + P10_C4;	// P11_C4 apparently not used
	assign {N10_C4, N10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign N11_OUT = SPRX[7:4] + N10_C4;	// N11_C4 apparently not used
	
	// P6:C and P6:D
	assign DIR_OB_EA = ~(nBFLIP & HFLIP);	// TODO: Check if really HFLIP
	assign DIR_OA_EB = ~(BFLIP & HFLIP);	// TODO: Check if really HFLIP
	
	// LB address counters:
	hc669_dual P13P12(CLK_OB_EA, nLOAD_X_A, DIR_OB_EA, {P11_OUT, P10_OUT}, LB_EVEN_B_ADDR);
	hc669_dual N13N12(CLK_OA_EB, nLOAD_X_B, DIR_OA_EB, {N11_OUT, N10_OUT}, LB_EVEN_A_ADDR);
	hc669_dual K12L13(CLK_OB_EA, nLOAD_X_A, DIR_OB_EA, SPRX, LB_ODD_B_ADDR);	// ?
	hc669_dual L12M13(CLK_OA_EB, nLOAD_X_B, DIR_OA_EB, SPRX, LB_ODD_A_ADDR);	// ?
	
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
	
	// J6 (174) CLK TODO, no nMR
	always @(posedge 1'bz)
		FIX_PAL_REG <= PBUS[19:16];	// FIX_PAL should be part of P_BUS
	
	linebuffer LB1(nOE_P18P20, nWE_EVEN_A,
						LB_EVEN_A_ADDR, {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]});
	linebuffer LB2(nOE_P19P21, nWE_EVEN_B,
						LB_EVEN_B_ADDR, {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]});
	linebuffer LB3(nOE_M18N18, nWE_ODD_A,
						LB_ODD_A_ADDR, {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]});
	linebuffer LB4(nOE_M19N19, nWE_ODD_B,
						LB_ODD_B_ADDR, {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]});
	
	// N4 and N7 ORs
	assign nOE_P18P20 = RBA | nWE_EVEN_A;
	assign nOE_P19P21 = RBB | nWE_EVEN_B;
	assign nOE_M18N18 = RBA | nWE_ODD_A;
	assign nOE_M19N19 = RBB | nWE_ODD_B;
	
	// M12 is in LSPC
	// J5 is in LSPC
	// N6 is in LSPC
	// P6 is in LSPC
	
	// FIX stuff, FIX/SPR mux and PA output
	
	always @(posedge TODO_FIXCLK)
	begin
		FIXD_REG_A <= FIXD;			// L5
		FIXD_REG_B <= FIXD_REG_A;	// M5
	end
	
	// M4 Odd/even tile pixel demux
	assign FIX_COLOR = SNKCLK_40 ? {FIXD_REG_B[7], FIXD_REG_B[5], FIXD_REG_B[3], FIXD_REG_B[1]} :
												{FIXD_REG_B[6], FIXD_REG_B[4], FIXD_REG_B[2], FIXD_REG_B[0]};
	
	// N4 & M6 Opacity detection
	assign FIX_OPAQUE = |{FIX_COLOR};
	
	assign MUX_BA = {BFLIP, SNKCLK_40};
	
	// K15 & L15 Sprite color bits mux
	assign SPR_COLOR = (MUX_BA == 2'b00) ? LB_EVEN_B_DATA[3:0] :
								(MUX_BA == 2'b01) ? LB_ODD_B_DATA[3:0] :
								(MUX_BA == 2'b10) ? LB_EVEN_A_DATA[3:0] :
								LB_ODD_A_DATA[3:0];
	
	// J12 Sprite/fix color bits mux
	assign COLOR = FIX_OPAQUE ? FIX_COLOR : SPR_COLOR;
								
	// N15, P15, K13, M15 Sprite palette bits mux
	assign SPR_PAL = (MUX_BA == 2'b00) ? LB_EVEN_B_DATA[11:4] :
							(MUX_BA == 2'b01) ? LB_ODD_B_DATA[11:4] :
							(MUX_BA == 2'b10) ? LB_EVEN_A_DATA[11:4] :
							LB_ODD_A_DATA[11:4];
	
	// H12 & H9 Sprite/fix palette bits mux
	assign PAL = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG} : SPR_PAL;
	
	// H10 & H11 Palette RAM address latches
	// nOE is used, certainly to gate outputs during CPU access
	assign PA_VIDEO = nPA_OE ? 12'bzzzzzzzzzzzz : PA_VIDEO_REG;
	always @(posedge CLK_PA)
	begin
		PA_VIDEO_REG <= {PAL, COLOR};
	end
	
	// --------------------------------------------------------------------------------
	
	
	// $400000~$7FFFFF why not use nPAL ?
	assign nPAL_ACCESS = |{A23Z, ~A22Z};	// |nAS ?
	
	// Todo: Wrong, nRESET is sync'd to frame start
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);
	
	/*
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

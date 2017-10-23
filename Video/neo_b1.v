`timescale 1ns/1ns

// All pins listed OK

// Signal to latch fix palette ? posedge 1MB + PCK2 ?
// Signal to latch sprite palette ? posedge 1MB + PCK1 ?

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
	input SS1, SS2,			// Buffer select
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

	wire [11:0] PA_VIDEO;
	wire [3:0] FIX_COLOR;
	wire [3:0] COLOR;
	wire [7:0] PAL;
	
	wire [1:0] MUX_BA;
	
	wire RBA, RBB;

	// Byte delays
	reg [7:0] SPR_PAL_REG_A;
	reg [7:0] SPR_PAL_REG_B;

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

	// Palette index latch
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
	
	// Fix data pipeline
	always @(posedge CLK_1MB)
	begin
		FIXD_REG_A <= FIXD;
		FIXD_REG_B <= FIXD_REG_A;
		FIXD_REG_C <= FIXD_REG_B;
	end
	
	assign FIX_COLOR = CLK_1MB ? FIXD_REG_C[3:0] : FIXD_REG_C[7:4];
	assign FIX_OPAQUE = |{FIX_COLOR};
	assign COLOR = FIX_OPAQUE ? FIX_COLOR : SPR_COLOR;
	assign PAL = FIX_OPAQUE ? {4'b0000, FIX_PAL_REG_B} : SPR_PAL;
	assign PA_VIDEO = CHBL ? 12'h000 : {PAL, COLOR};
	
	// Connects to Alpha68k stuff
	
	// This might be in LSPC, BFLIP = TMS0
	//always @(posedge SNKCLK_26)
	//	BFLIP <= J8_12;	// Line number bit0 (SNKCLK_19)
	
	assign BFLIP = TMS0;
	assign nBFLIP = ~BFLIP;
	
	// BFLIP = 0 : B OUTPUT, A WRITE
	// BFLIP = 1 : A OUTPUT, B WRITE
	
	assign nWE_ODD_A = WE[0];
	assign nWE_EVEN_A = WE[1];
	assign nWE_ODD_B = WE[2];
	assign nWE_EVEN_B = WE[3];
	
	// ?
	//assign CLK_OB_EA = CK[0];
	//assign CLK_OA_EB = CK[1];
	// Some CK[] might be RBA and RBB !
	assign RBA = CK[2];
	assign RBB = CK[3];
	
	// Opposite ?
	assign nLOAD_X_A = LD1;
	assign nLOAD_X_B = LD2;
	
	// -------------------------------- Alpha68k logic and additions --------------------------------
	
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
	reg [7:0] FIXD_REG_A;
	reg [7:0] FIXD_REG_B;
	reg [7:0] FIXD_REG_C;
	
	reg [3:0] FIX_PAL_REG_A;
	reg [3:0] FIX_PAL_REG_B;

	wire [3:0] SPR_COLOR;
	wire [7:0] SPR_PAL;
	
	wire SNKCLK_26;	// TODO
	wire nLATCH_X;		// TODO
	reg [7:0] SPRX;
	wire HFLIP;			// TODO
	wire TODO_FIXCLK;	// TODO
	//wire CLK_PA;		// TODO
	wire nPA_OE;		// TODO
	//reg [11:0] PA_VIDEO_REG;
	//wire [11:0] PA_VIDEO;
	reg PAL_SWITCH;	// Good ?
	
	// G3 (374): nOE seems used !
	always @(posedge S1H1)	// nLATCH_X on Alpha68k
	begin
		if (PAL_SWITCH)
			SPRX <= PBUS[15:8];
	end
	
	// G5:C
	assign PLUS_ONE = ~1'b1;	// TODO: Wrong !
	
	// Both of these output the exact same thing, something must be wrong
	assign {P10_C4, P10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign P11_OUT = SPRX[7:4] + P10_C4;	// P11_C4 apparently not used
	assign {N10_C4, N10_OUT} = SPRX[3:0] + PLUS_ONE;
	assign N11_OUT = SPRX[7:4] + N10_C4;	// N11_C4 apparently not used
	
	// P6:C and P6:D
	// Render: Count up (X ->>>>)
	// Output: ???
	assign DIR_OB_EA = 1;	//~(nBFLIP & 1);		// TODO: Probably whole display h-flip
	assign DIR_OA_EB = 1;	//~(BFLIP & 1);		// TODO: Probably whole display h-flip
	
	// LB address counters:
	hc669_dual P13P12(CK[3], nLOAD_X_B, DIR_OB_EA, {P11_OUT, P10_OUT}, LB_EVEN_B_ADDR);
	hc669_dual N13N12(CK[1], nLOAD_X_A, DIR_OA_EB, {N11_OUT, N10_OUT}, LB_EVEN_A_ADDR);
	hc669_dual K12L13(CK[2], nLOAD_X_B, DIR_OB_EA, SPRX, LB_ODD_B_ADDR);	// ?
	hc669_dual L12M13(CK[0], nLOAD_X_A, DIR_OA_EB, SPRX, LB_ODD_A_ADDR);	// ?
	
	// Sprite palette latch G6 (273):
	/*always @(posedge PCK2)	// TODO: Wrong !
	begin
		// Is nMR used ?
		SPR_PAL_REG_A <= PBUS[23:16];	// SPR_PAL should be part of P_BUS
	end
	// Sprite palette latch G1 (273):
	always @(posedge PCK2)	// TODO: Wrong !
	begin
		// Is nMR used ?
		SPR_PAL_REG_B <= SPR_PAL_REG_A;
	end*/
	
	linebuffer LB1(nOE_P18P20, nWE_EVEN_A,
						LB_EVEN_A_ADDR, {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]}, LB_EVEN_A_DATA);
	linebuffer LB2(nOE_P19P21, nWE_EVEN_B,
						LB_EVEN_B_ADDR, {SPR_PAL_REG_B, GAD[1], GAD[0], GAD[3], GAD[2]}, LB_EVEN_B_DATA);
	linebuffer LB3(nOE_M18N18, nWE_ODD_A,
						LB_ODD_A_ADDR, {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]}, LB_ODD_A_DATA);
	linebuffer LB4(nOE_M19N19, nWE_ODD_B,
						LB_ODD_B_ADDR, {SPR_PAL_REG_B, GBD[1], GBD[0], GBD[3], GBD[2]}, LB_ODD_B_DATA);
	
	// N4 and N7 ORs
	assign nOE_P18P20 = RBA | nWE_EVEN_A;
	assign nOE_P19P21 = RBB | nWE_EVEN_B;
	assign nOE_M18N18 = RBA | nWE_ODD_A;
	assign nOE_M19N19 = RBB | nWE_ODD_B;
	
	// M12 is in LSPC
	// J5 is in LSPC
	// N6 is in LSPC
	// P6 is in LSPC
	
	// Maybe SS* instead of BFLIP
	// Maybe S1H1 instead of BFLIP
	assign MUX_BA = {BFLIP, CLK_1MB};
	
	// K15 & L15 Sprite color bits mux
	assign SPR_COLOR = (MUX_BA == 2'b00) ? LB_ODD_A_DATA[3:0] :
								(MUX_BA == 2'b01) ? LB_EVEN_A_DATA[3:0] :
								(MUX_BA == 2'b10) ? LB_ODD_B_DATA[3:0] :
								LB_EVEN_B_DATA[3:0];
								
	// N15, P15, K13, M15 Sprite palette bits mux
	assign SPR_PAL = (MUX_BA == 2'b00) ? LB_ODD_A_DATA[11:4] :
							(MUX_BA == 2'b01) ? LB_EVEN_A_DATA[11:4] :
							(MUX_BA == 2'b10) ? LB_ODD_B_DATA[11:4] :
							LB_EVEN_B_DATA[11:4];
	
	//assign PA = CHBL ? 12'h000 : {PAL, COLOR};
	
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
	
	// Note: nRESET is sync'd to frame start
	// To check: BNKB might have to be inverted (see Alpha68k K7:A)
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_U, M68K_ADDR_L, BNKB, nHALT, nRESET, nRST);
	
	// Priority for palette address bus (PA):
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -FIX pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ? PA_VIDEO : M68K_ADDR_L;

endmodule

`timescale 1ns/1ns

module neo_b1(
	input CLK_6MB,
	input CLK_1MB,				// Even/odd pixel selection ?
	input [23:0] PBUS,
	input [7:0] FIXD,
	input PCK1,					// What for ?
	input PCK2,					// What for ?
	input CHBL,
	input BNKB,
	input [3:0] GAD, GBD,
	input [3:0] WE,			// LB writes
	input [3:0] CK,			// LB clocks
	input TMS0,					// LB flip, watchdog ?
	input LD1, LD2,			// Latch x position of sprite from P bus ?
	input SS1, SS2,			// """""
	input S1H1,					// ?
	input A23Z, A22Z,
	output reg [11:0] PA,
	input nLDS,					// For watchdog
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	output nHALT,				// Todo
	output nRESET,
	input nRST
);

	/*
	reg [7:0] SPR_PAL;			// Needs to be registered, as palette shows up on P bus only every 4 pixels
	reg [3:0] FIX_PAL;
	reg [7:0] FIX_DATA;
	
	wire [11:0] LBDATA_A_E;
	wire [11:0] LBDATA_A_O;
	wire [11:0] LBDATA_B_E;
	wire [11:0] LBDATA_B_O;
	wire [11:0] LBDATA_OUT;		// Muxed
	
	wire [3:0] FIX_PIXEL;
	wire FIX_OPAQUE;
	
	wire nPAL_ACCESS;
	*/
	
	
	// -------------------------------- Alpha68k logic --------------------------------
	
	wire [3:0] P10_A;
	wire [3:0] N10_A;
	wire [3:0] P11_A ;
	wire [3:0] N11_A;
	wire [3:0] P10_OUT;
	wire [3:0] N10_OUT;
	wire [3:0] P11_OUT;
	wire [3:0] N11_OUT;
	
	wire [7:0] LB_EVEN_A_ADDR;
	wire [7:0] LB_EVEN_B_ADDR;
	wire [7:0] LB_ODD_A_ADDR;
	wire [7:0] LB_ODD_B_ADDR;
	
	reg [7:0] SPR_PAL_REG;
	
	wire [11:0] LB_EVEN_A_DATA;
	wire [11:0] LB_EVEN_B_DATA;
	wire [11:0] LB_ODD_A_DATA;
	wire [11:0] LB_ODD_B_DATA;
	
	wire [5:0] P18_OUT;
	wire [5:0] P20_OUT;
	wire [5:0] P19_OUT;
	wire [5:0] P21_OUT;
	wire [5:0] M18_OUT;
	wire [5:0] N18_OUT;
	wire [5:0] M19_OUT;
	wire [5:0] N19_OUT;
	
	reg [7:0] FIXD_REG_A;
	reg [7:0] FIXD_REG_B;
	
	wire [3:0] FIX_COLOR;
	wire [3:0] SPR_COLOR;
	wire [3:0] COLOR;
	wire [7:0] SPR_PAL;
	
	reg [3:0] FIX_PAL_REG;
	
	wire [7:0] PAL;
	
	wire G5_8;	// TODO
	wire BUFF_FLIP;	// TODO
	wire CLK_RENDER;	// TODO
	wire CLK_SPR_PAL;	// TODO
	wire nAB;			// TODO
	wire MUX_AB;		// TODO
	
	
	// 1 pixel offset generator:
	assign P10_A = 4'bzzzz;	// TODO
	assign N10_A = P10_A;
	
	assign P10_C0 = G5_8;	// TODO
	assign N10_C0 = G5_8;	// TODO
	
	assign {P10_C4, P10_OUT} = P10_A + P10_C0;
	assign {N10_C4, N10_OUT} = N10_A + N10_C0;
	
	
	assign P11_A = 4'bzzzz;	// TODO
	assign N11_A = P11_A;
	
	assign P11_C0 = P10_C4;
	assign N11_C0 = N10_C4;
	
	assign {P11_C4, P11_OUT} = P11_A + P11_C0;		// P11_C4 apparently not used
	assign {N11_C4, N11_OUT} = N11_A + N11_C0;		// N11_C4 apparently not used
	
	// Counters:
	hc669 P13(CLK_EVEN_A, 1'b0, nLOAD_EVEN_A, UP_EVEN_A, P10_OUT, LB_EVEN_B_ADDR[3:0], P13_CARRY);
	hc669 P12(CLK_EVEN_A, P13_CARRY, nLOAD_EVEN_A, UP_EVEN_A, P11_OUT, LB_EVEN_B_ADDR[7:4], );	// Carry apparently unused
	hc669 N13(CLK_EVEN_B, 1'b0, nLOAD_EVEN_B, UP_EVEN_B, N10_OUT, LB_EVEN_A_ADDR[3:0], N13_CARRY);
	hc669 N12(CLK_EVEN_B, N13_CARRY, nLOAD_EVEN_B, UP_EVEN_B, N11_OUT, LB_EVEN_A_ADDR[7:4], );	// Carry apparently unused

	hc669 K12(CLK_EVEN_A, 1'b0, nLOAD_EVEN_A, UP_EVEN_A, P10_A, LB_ODD_B_ADDR[3:0], K12_CARRY);
	hc669 L13(CLK_EVEN_A, K12_CARRY, nLOAD_EVEN_A, UP_EVEN_A, P11_A, LB_ODD_B_ADDR[7:4], );	// Carry apparently unused
	hc669 L12(CLK_EVEN_B, 1'b0, nLOAD_EVEN_B, UP_EVEN_B, P10_A, LB_ODD_A_ADDR[3:0], L12_CARRY);
	hc669 M13(CLK_EVEN_B, L12_CARRY, nLOAD_EVEN_B, UP_EVEN_B, P11_A, LB_ODD_A_ADDR[7:4], );	// Carry apparently unused
	
	// M12:
	assign RBA = BUFF_FLIP ? CLK_CLEAR : 1'b0;
	assign RBB = BUFF_FLIP ? 1'b0 : CLK_CLEAR;
	assign CLK_EVEN_B = BUFF_FLIP ? CLK_RENDER : CLK_CLEAR;
	assign CLK_EVEN_A = BUFF_FLIP ? CLK_CLEAR : CLK_RENDER;
	
	// Sprite palette latch G1 (273):
	always @(posedge CLK_SPR_PAL)
	begin
		// Is nMR used ?
		SPR_PAL_REG <= PBUS[23:16];	// SPR_PAL should be part of P_BUS
	end
	
	// TODO: Z state in read mode
	assign LB_EVEN_A_DATA = {P18_OUT, P20_OUT};
	assign LB_EVEN_B_DATA = {P19_OUT, P21_OUT};
	assign LB_ODD_A_DATA = {M18_OUT, N18_OUT};
	assign LB_ODD_B_DATA = {M19_OUT, N19_OUT};
	// HC367s - 6'b111111 are caused by pullups (see PCB), allows for clearing
	assign P18_OUT = nOE_P18P20 ? 6'b111111 : SPR_PAL_REG[7:2];
	assign P20_OUT = nOE_P18P20 ? 6'b111111 : {SPR_PAL_REG[1:0], GAD[1], GAD[0], GAD[3], GAD[2]};
	assign P19_OUT = nOE_P19P21 ? 6'b111111 : SPR_PAL_REG[7:2];
	assign P21_OUT = nOE_P19P21 ? 6'b111111 : {SPR_PAL_REG[1:0], GAD[1], GAD[0], GAD[3], GAD[2]};
	
	assign M18_OUT = nOE_M18N18 ? 6'b111111 : SPR_PAL_REG[7:2];
	assign N18_OUT = nOE_M18N18 ? 6'b111111 : {SPR_PAL_REG[1:0], GBD[1], GBD[0], GBD[3], GBD[2]};
	assign M19_OUT = nOE_M19N19 ? 6'b111111 : SPR_PAL_REG[7:2];
	assign N19_OUT = nOE_M19N19 ? 6'b111111 : {SPR_PAL_REG[1:0], GBD[1], GBD[0], GBD[3], GBD[2]};
	
	// ORs
	assign nOE_P18P20 = RBA | nWE_EVEN_A;
	assign nOE_P19P21 = RBB | nWE_EVEN_B;
	assign nOE_M18N18 = RBA | nWE_ODD_A;
	assign nOE_M19N19 = RBB | nWE_ODD_B;
	
	// N6 quad mux
	assign nWE_ODD_A = BUFF_FLIP ? nODD_WE : nCLEAR_WE;
	assign nWE_ODD_B = BUFF_FLIP ? nCLEAR_WE : nODD_WE;
	assign nWE_EVEN_A = BUFF_FLIP ? nEVEN_WE : nCLEAR_WE;
	assign nWE_EVEN_B = BUFF_FLIP ? nCLEAR_WE : nEVEN_WE;
	
	// NANDs TODO
	assign nODD_WE = 1'bz;
	assign nEVEN_WE = 1'bz;
	
	// J5 TODO
	assign nCLEAR_WE = 1'bz;
	assign CLK_CLEAR = 1'bz;
	
	// FIX stuff, FIX/SPR mux and PA output
	
	// L5 TODO
	always @(posedge 1'bz)
	begin
		// Is nMR used ?
		FIXD_REG_A <= FIXD;
	end
	
	// M5 TODO
	always @(posedge 1'bz)
	begin
		// Is nMR used ?
		FIXD_REG_B <= FIXD_REG_A;
	end
	
	// M4 Odd/even tile pixel demux
	assign FIX_COLOR = nAB ? {FIXD_REG_B[7], FIXD_REG_B[5], FIXD_REG_B[3], FIXD_REG_B[1]} :
										{FIXD_REG_B[6], FIXD_REG_B[4], FIXD_REG_B[2], FIXD_REG_B[0]};
									
	// K15 & L15 Sprite color bits mux
	assign SPR_COLOR = (MUX_AB == 2'b00) ? LB_EVEN_B_DATA[3:0] :
								(MUX_AB == 2'b01) ? LB_ODD_B_DATA[3:0] :
								(MUX_AB == 2'b10) ? LB_EVEN_A_DATA[3:0] :
								LB_ODD_A_DATA[3:0];
	
	// J12 Sprite/fix color bits mux
	assign COLOR = nSPR_FIX_SW ? FIX_COLOR : SPR_COLOR;
								
	// N15, P15, K13, M15 Sprite palette bits mux
	assign SPR_PAL = (MUX_AB == 2'b00) ? LB_EVEN_B_DATA[11:4] :
							(MUX_AB == 2'b01) ? LB_ODD_B_DATA[11:4] :
							(MUX_AB == 2'b10) ? LB_EVEN_A_DATA[11:4] :
							LB_ODD_A_DATA[11:4];
	
	// J6 (174) TODO
	always @(posedge 1'bz)
	begin
		// Is nMR used ?
		FIX_PAL_REG <= PBUS[19:16];	// FIX_PAL should be part of P_BUS
	end
	
	// H12 & H9 Sprite/fix palette bits mux
	assign PAL = nSPR_FIX_SW ? {4'b0000, FIX_PAL_REG} : SPR_PAL;
	
	// H10 & H11 Palette RAM address latches TODO
	always @(posedge 1'bz)
	begin
		// Is nMR used ?
		PA <= {PAL, COLOR};
	end
	
	// Certainly comes from 2, muxed 4-input OR with M4 nAB TODO
	assign nSPR_FIX_SW = 1'bz;

	
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

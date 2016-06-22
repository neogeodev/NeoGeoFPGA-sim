`timescale 10ns/10ns

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
	output [11:0] PA,
	input nLDS,					// For watchdog
	input RW,
	input nAS,
	input [21:17] M68K_ADDR_WD,
	input [12:1] M68K_ADDR_PAL,
	output nHALT,				// Todo
	output nRESET,
	input nRST
);

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
	
	// $400000~$7FFFFF why not use nPAL ?
	assign nPAL_ACCESS = |{A23Z, ~A22Z, nAS};
	
	// Todo: Wrong, nRESET is sync'd to frame start
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_WD, M68K_ADDR_PAL, BNKB, nHALT, nRESET, nRST);

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
	
	// Priority for palette address bus PA:
	// -CPU over everything else (?)
	// -CHBL (priority over CPU ?)
	// -FIX pixel if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ?
					CHBL ? 12'b000000000000 :
					FIX_OPAQUE ? {FIX_PAL, FIX_PIXEL} :
					LBDATA_OUT :
					M68K_ADDR_PAL;
	
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

endmodule

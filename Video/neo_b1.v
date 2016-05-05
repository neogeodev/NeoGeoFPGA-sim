`timescale 10ns/10ns

module neo_b1(
	input CLK_6MB,
	input CLK_1MB,				// What for ?
	input [23:0] PBUS,
	input [7:0] FIXD,
	input PCK1,					// What for ?
	input PCK2,					// What for ?
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
	input [11:0] M68K_ADDR_PAL,
	output nHALT,				// Todo
	output nRESET,
	input nRST,					// Reset button and reset gen on AES, VCCON on MVS ?
	input [8:0] HCOUNT		// Todo: REMOVE HCOUNT, used here but shouldn't. Hack to replace proper CLK_1MB ?
);

	reg [7:0] SPR_PAL;		// Needs to be registered, as palette shows up on P bus only every 4 pixels
	reg [3:0] FIX_PAL;
	reg [7:0] FIX_DATA;
	
	wire [11:0] LBDATA_A_E;
	wire [11:0] LBDATA_A_O;
	wire [11:0] LBDATA_B_E;
	wire [11:0] LBDATA_B_O;
	wire [11:0] LBDATA;		// Muxed
	
	wire [3:0] FIX_PIXEL;
	wire FIX_OPAQUE;
	
	wire nPAL_ACCESS;
	
	// $400000~$7FFFFF why not use nPAL ?
	assign nPAL_ACCESS = |{A23Z, ~A22Z, nAS};
	
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_WD, TMS0, nHALT, nRESET, nRST);

	// Is WE used as OE when in output mode ? (=CK)
	// assign LBDATA1 = LB_A_W ? {SPR_PAL, GAD} : 12'bzzzzzzzzzzzz;
	linebuffer LB1(CK[0], WE[0], PCK2, PBUS[15:8], LBDATA_A_E, TMS0);
	linebuffer LB2(CK[1], WE[1], PCK2, PBUS[15:8], LBDATA_A_O, TMS0);
	linebuffer LB3(CK[2], WE[2], PCK2, PBUS[15:8], LBDATA_B_E, ~TMS0);
	linebuffer LB4(CK[3], WE[3], PCK2, PBUS[15:8], LBDATA_B_O, ~TMS0);
	
	// Line buffer: clear value for now. This is inherited from the Alpha68k system
	assign LBDATA = 12'hFFF;

	assign FIX_HALF = HCOUNT[0]; 	// Todo: fix this. CLK_1MB ?
	assign FIX_PIXEL = FIX_HALF ? FIX_DATA[7:4] : FIX_DATA[3:0];
	assign FIX_OPAQUE = |{FIX_PIXEL};
	
	// Priority for palette address bus PA:
	// -CPU over everything else
	// -FIXD_HALF if opaque
	// -Line buffer (sprites) output is last
	assign PA = nPAL_ACCESS ?
					FIX_OPAQUE ? {FIX_PAL, FIX_PIXEL} :
					LBDATA :
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

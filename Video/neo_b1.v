`timescale 10ns/10ns

module neo_b1(
	input CLK_6MB,
	input CLK_1MB,
	input [23:0] PBUS,
	input [7:0] FIXD,
	input PCK1,
	input PCK2,
	input [3:0] GAD, GBD,
	input [3:0] WE,
	input [3:0] CK,
	input TMS0,
	input LD1,
	input LD2,
	input SS1,
	input SS2,
	input S1H1,
	input A23Z, A22Z,
	output [11:0] PA,
	input nLDS,
	input RW,
	input [20:16] M68K_ADDR_WD,
	input [11:0] M68K_ADDR_PAL,
	output nHALT,
	output nRESET,
	input VCCON
);

	// TODO: Output M68K_ADDR_BOT to PA if palette i/o

	reg [7:0] SPR_PAL;
	reg [3:0] FIX_PAL;
	reg [7:0] FIX_DATA;
	
	wire [11:0] LBDATA1;
	wire [11:0] LBDATA2;
	wire [11:0] LBDATA3;
	wire [11:0] LBDATA4;
	
	reg [11:0] DEBUG_FIX_PIXEL;
	
	// $400000~$7FFFFF why not use nPAL ?
	assign nPAL_ACCESS = |{A23Z, ~A22Z};
	
	// TODO: CLK
	watchdog WD(nLDS, RW, A23Z, A22Z, M68K_ADDR_WD, CLK, nHALT, nRESET, VCCON);

	// Is WE used as OE when in output mode ? (=CK)

	/*linebuffer LB1(CK[0], WE[0], PCK2, PBUS[15:8], LBDATA1, TMS0);
	linebuffer LB2(CK[1], WE[1], PCK2, PBUS[15:8], LBDATA2, TMS0);
	linebuffer LB3(CK[2], WE[2], PCK2, PBUS[15:8], LBDATA3, ~TMS0);
	linebuffer LB4(CK[3], WE[3], PCK2, PBUS[15:8], LBDATA4, ~TMS0);*/
	
	// Priority for palette address bus PA:
	// CPU over everything else
	// FIXD_HALF opaque
	// Line buffer (sprites) output is last
	
	wire [3:0] FIXD_HALF;

	assign HALF = CLK_1MB; // ?
	assign FIXD_HALF = HALF ? FIX_DATA[7:4] : FIX_DATA[3:0];
	assign PA = nPAL_ACCESS ? (|{FIXD_HALF}) ? DEBUG_FIX_PIXEL : LBDATA1 : M68K_ADDR_PAL;
	
	// Line buffer clear value, for now
	assign LBDATA1 = 12'hFFF;
	//assign LBDATA1 = TMS0 ? {GAD, SPR_PAL} : 12'bzzzzzzzzzzzz;	// TODO
	
	// posedge 6MB: set PA
	always @(posedge CLK_6MB)
	begin
		DEBUG_FIX_PIXEL <= {FIX_PAL, FIXD_HALF};
	end
	
	// Probably wrong, needs real hw observations
	wire nS1H1;
	assign nS1H1 = ~S1H1;
	always @(posedge S1H1 or posedge nS1H1)
	begin
		if (S1H1)
		begin
			FIX_DATA <= FIXD;
			FIX_PAL <= PBUS[19:16];
		end
		else
		begin
			FIX_DATA <= FIXD;
			// Test
		end
	end
	
	// Todo
	/*always @(posedge PCK2)
	begin
		SPR_PAL <= PBUS[23:16];
	end*/

endmodule

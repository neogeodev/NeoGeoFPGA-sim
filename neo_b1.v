`timescale 10ns/10ns

module neo_b1(
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
	output [11:0] PA
);

	reg [7:0] SPR_PAL;
	reg [3:0] FIX_PAL;

	// Is WE used as OE when in output mode ? (=CK)

	linebuffer LB1(CK[0], WE[0], PCK2, PBUS[15:8], LBDATA1, TMS0);
	linebuffer LB2(CK[1], WE[1], PCK2, PBUS[15:8], LBDATA2, TMS0);
	linebuffer LB3(CK[2], WE[2], PCK2, PBUS[15:8], LBDATA3, ~TMS0);
	linebuffer LB4(CK[3], WE[3], PCK2, PBUS[15:8], LBDATA4, ~TMS0);
	
	// if FIXD !=0, replace output
	assign PA = (|FIXD) ? {FIX_PAL, FIXD} : LBDATA1;
	
	assign LBDATA1 = TMS0 ? {GAD, SPR_PAL} : 12'bzzzzzzzzzzzz;	// TODO
	
	always @(posedge PCK1)
	begin
		FIX_PAL <= PBUS[19:16];
	end
	
	always @(posedge PCK2)
	begin
		SPR_PAL <= PBUS[23:16];
	end

endmodule

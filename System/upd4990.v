`timescale 1ns/1ns

module upd4990(
	input XTAL,
	input CS, OE,
	input CLK,
	input DATA_IN,
	input STROBE,
	output reg TP,
	output DATA_OUT	// Open drain !
);

	// Todo, low priority for now
	
	wire CLKG, STROBEG;	// Gated by CS

	assign CLKG = CS & CLK;
	assign STROBEG = CS & STROBE;

	// DEBUG begin
	always
		#5000 TP = !TP;		// 10ms - Should be 1Hz -> 500000ns half period
		
	always @(posedge CLKG)
		if (CS) $display("RTC clocked in data bit '%B'", DATA_IN);
		
	always @(posedge STROBEG)
		if (CS) $display("RTC strobed");
	// DEBUG end
	
endmodule

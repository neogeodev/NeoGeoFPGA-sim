`timescale 1ns/1ns

module upd4990(
	input XTAL,
	input CS, OE,
	input CLK,
	input DATA_IN,
	output TP,
	output DATA_OUT	// Open drain !
);

	wire CLKG;	// CLK gated

	assign CLKG = CS & CLK;

	// Todo, low priority for now
	
endmodule

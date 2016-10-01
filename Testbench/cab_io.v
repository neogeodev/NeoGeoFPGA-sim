`timescale 1ns/1ns

// SIMULATION
// Latches and buffers on the 68K bus for MVS cab I/Os
// 273s and 245s on the verification board
// Signals: nBITWD0, nDIPRD0, nLED_LATCH, nLED_DATA

module cab_io(
	input [7:4] M68K_ADDR,
	inout [7:0] M68K_DATA,
	output [3:0] EL_OUT,
	output [8:0] LED_OUT1,
	output [8:0] LED_OUT2
);
	
	assign EL_OUT = {LEDLATCH[0], LEDDATA[2:0]};
	assign LED_OUT1 = {LEDLATCH[1], LEDDATA};
	assign LED_OUT2 = {LEDLATCH[2], LEDDATA};
	
endmodule

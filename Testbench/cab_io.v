`timescale 1ns/1ns

// SIMULATION
// Latches and buffers on the 68K bus for MVS cab I/Os
// 273s and 245s on the verification board
// Signals: nBITWD0, nDIPRD0, nLED_LATCH, nLED_DATA

module cab_io(
	input nDIPRD0,
	input nLED_LATCH,
	input nLED_DATA,
	input [7:0] DIPSW,
	input [7:4] M68K_ADDR,
	inout [7:0] M68K_DATA,
	output [3:0] EL_OUT,
	output [8:0] LED_OUT1,
	output [8:0] LED_OUT2
);

	reg [2:0] LEDLATCH;
	reg [7:0] LEDDATA;
	
	always @(posedge nLED_LATCH)
	begin
		LEDLATCH <= M68K_DATA[5:3];		// REG_LEDLATCHES
	end
	
	always @(posedge nLED_DATA)
	begin
		LEDDATA <= M68K_DATA[7:0];			// REG_LEDDATA
	end
	
	assign EL_OUT = {LEDLATCH[0], LEDDATA[2:0]};
	assign LED_OUT1 = {LEDLATCH[1], LEDDATA};
	assign LED_OUT2 = {LEDLATCH[2], LEDDATA};
	
	// $300001~?, odd bytes REG_DIPSW
	// $300081~?, odd bytes TODO
	assign M68K_DATA = (nDIPRD0) ? 8'bzzzzzzzz :
								(M68K_ADDR[7]) ? 8'b11111111 : DIPSW;
	
endmodule

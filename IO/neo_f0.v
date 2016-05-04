`timescale 1ns/1ns

module neo_f0(
	input nDIPRD1,					// "IN3"
	input nBITWD0,
	//input [7:0] DIPSW,
	input [6:3] M68K_ADDR,
	inout [7:0] M68K_DATA,
	input SYSTEMB,
	output [5:0] nSLOT,
	output SLOTA, SLOTB, SLOTC,
	output nLED_LATCH, nLED_DATA
	//output [3:0] EL_OUT,
	//output [8:0] LED_OUT1,
	//output [8:0] LED_OUT2
);

	// These might have to be positive logic to match clock polarity of used chips
	assign nLED_LATCH = (M68K_ADDR[6:4] == 3'b011) ? nBITWD0 : 1'b1;
	assign nLED_DATA = (M68K_ADDR[6:4] == 3'b100) ? nBITWD0 : 1'b1;
	
	/*always @(posedge nBITWD0)	// ?
	begin
		if (M68K_ADDR[6:4] == 3'b011) LEDLATCH <= M68K_DATA[5:3];		// REG_LEDLATCHES
		if (M68K_ADDR[6:4] == 3'b100) LEDDATA <= M68K_DATA[7:0];			// REG_LEDDATA
	end*/

	reg [2:0] REG_RTCCTRL;		// Todo
	
	reg [2:0] SLOTS;

	// REG_STATUS_A (NEO-F0) $320001~?, odd bytes TODO
	// IN3: Output IN300~IN304 to D0~D4 and CALTP/CALDOUT to D6/D7 (read $320001)
	assign M68K_DATA = (nDIPRD1) ? 8'bzzzzzzzz : 8'b11111111;
	
	always @(posedge nBITWD0)	// ?
	begin
		if (M68K_ADDR[5:3] == 3'b010) SLOTS <= M68K_DATA[2:0];			// REG_SLOT
		if (M68K_ADDR[5:3] == 3'b101) REG_RTCCTRL <= M68K_DATA[2:0];	// REG_RTCCTRL
	end
	
	assign {SLOTC, SLOTB, SLOTA} = SYSTEMB ? 3'b000 : SLOTS;	// Not sure ?
	
	assign nSLOT = SYSTEMB ? 6'b111111 :
						(SLOTS == 3'b000) ? 6'b111110 :
						(SLOTS == 3'b001) ? 6'b111101 :
						(SLOTS == 3'b010) ? 6'b111011 :
						(SLOTS == 3'b011) ? 6'b110111 :
						(SLOTS == 3'b100) ? 6'b101111 :
						(SLOTS == 3'b101) ? 6'b011111 :
						6'b111111;	// Not sure ?
	
endmodule

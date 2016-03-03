`timescale 10ns/10ns

module neo_f0(
	input nDIPRD0,
	input nDIPRD1,					// "IN3"
	input nBITWD0,
	input [7:0] DIPSW,
	input [6:3] M68K_ADDR,
	inout [7:0] M68K_DATA,
	input SYSTEMB,
	output [5:0] SLOT,
	output SLOTA, SLOTB, SLOTC,
	output [3:0] EL_OUT,
	output [8:0] LED_OUT1,
	output [8:0] LED_OUT2
);

	reg [2:0] LEDLATCH;
	reg [7:0] LEDDATA;
	reg [2:0] REG_RTCCTRL;		// Todo
	
	reg [2:0] SLOTS;

	// $300001~?, odd bytes REG_DIPSW
	// $300081~?, odd bytes TODO
	assign M68K_DATA = (nDIPRD0) ? (M68K_ADDR[6]) ? 8'b11111111 :
															DIPSW : 8'bzzzzzzzz;
	// REG_STATUS_A (NEO-F0) $320001~?, odd bytes TODO
	// IN3: Output IN300~IN304 to D0~D4 and CALTP/CALDOUT to D6/D7 (read $320001)
	assign M68K_DATA = (nDIPRD1) ? 8'b11111111 : 8'bzzzzzzzz;
	
	always @(nBITWD0)
	begin
		if (M68K_ADDR[5:3] == 3'b010) SLOTS <= M68K_DATA[2:0];			// REG_SLOT
		if (M68K_ADDR[5:3] == 3'b011) LEDLATCH <= M68K_DATA[5:3];		// REG_LEDLATCHES
		if (M68K_ADDR[5:3] == 3'b100) LEDDATA <= M68K_DATA[7:0];			// REG_LEDDATA
		if (M68K_ADDR[5:3] == 3'b101) REG_RTCCTRL <= M68K_DATA[2:0];	// REG_RTCCTRL
	end
	
	assign EL_OUT = {LEDLATCH[0], LEDDATA[2:0]};
	assign LED_OUT1 = {LEDLATCH[1], LEDDATA};
	assign LED_OUT2 = {LEDLATCH[2], LEDDATA};
	
	assign {SLOTC, SLOTB, SLOTA} = SYSTEMB ? 3'b000 : SLOTS;	// Not sure ?
	
	assign SLOT = SYSTEMB ? 6'b111111 :
						(SLOTS == 3'b000) ? 6'b111110 :
						(SLOTS == 3'b001) ? 6'b111101 :
						(SLOTS == 3'b010) ? 6'b111011 :
						(SLOTS == 3'b011) ? 6'b110111 :
						(SLOTS == 3'b100) ? 6'b101111 :
						(SLOTS == 3'b101) ? 6'b011111 :
						6'b111110;	// Not sure ?
	
endmodule

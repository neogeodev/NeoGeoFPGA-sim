`timescale 1ns/1ns

module cab_io(
	input nBITWD0,
	input nDIPRD0,
	input [7:0] DIPSW,
	input M68K_ADDR_6,
	inout [5:3] M68K_ADDR,
	inout [7:0] M68K_DATA,
	output [7:0] EL_OUT,
	output [7:0] LED_OUT1,
	output [7:0] LED_OUT2
);

	reg [2:0] LEDLATCH;
	reg [7:0] LEDDATA;
	
	always @(posedge nBITWD0)	// ?
	begin
		if (M68K_ADDR[5:3] == 3'b011) LEDLATCH <= M68K_DATA[5:3];		// REG_LEDLATCHES
		if (M68K_ADDR[5:3] == 3'b100) LEDDATA <= M68K_DATA[7:0];			// REG_LEDDATA
	end
	
	assign EL_OUT = {LEDLATCH[0], LEDDATA[2:0]};
	assign LED_OUT1 = {LEDLATCH[1], LEDDATA};
	assign LED_OUT2 = {LEDLATCH[2], LEDDATA};
	
	// $300001~?, odd bytes REG_DIPSW
	// $300081~?, odd bytes TODO
	assign M68K_DATA = (nDIPRD0) ? 8'bzzzzzzzz :
								(M68K_ADDR_6) ? 8'b11111111 : DIPSW;
	
endmodule

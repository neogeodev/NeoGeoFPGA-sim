`timescale 1ns/1ns

module watchdog(
	input nLDS, RW,
	input A23Z, A22Z,
	input [21:17] M68K_ADDR_U,
	input [12:1] M68K_ADDR_L,
	input WDCLK,
	output nHALT,
	output nRESET,
	input nRST
);

	reg [3:0] WDCNT;
	
	// IMPORTANT:
	// nRESET is an open-collector output on B1, so that the 68k can drive it (RESET instruction)
	// The line has a 4.7k pullup (schematics page 1)
	// nRESET changes state on posedge nBNKB (posedge mclk), but takes a slightly variable amount of time to
	// return high after it is released. Low during 8 frames, released during 8 frames.
	assign nRESET = WDCNT[3];
	assign nHALT = 1'b1;			// Todo
	
	// 300001 (LDS)
	// 0011000xxxx0000000000001
	assign WDKICK = &{~|{nLDS, RW}, ~|{A23Z, A22Z}, M68K_ADDR_U[21:20], ~|{M68K_ADDR_U[19:17], M68K_ADDR_L[12:1]}};

	// posedge WDCLK: 
	// posedge WDKICK: not sure.
	always @(posedge WDCLK or posedge WDKICK or negedge nRST)
	begin
		if (!nRST)
			WDCNT <= 4'b0000;
		else
		begin
			if (WDKICK)
				WDCNT <= 4'b1000;
			else
				WDCNT <= WDCNT + 1;
		end
	end

endmodule

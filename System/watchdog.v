`timescale 1ns/1ns

module watchdog(
	input nLDS, RW,
	input A23Z, A22Z,
	input [21:17] M68K_ADDR,
	input CLK,
	output nHALT,
	output nRESET,
	input VCCON					// TODO: Important for WD initialization !
);

	reg [10:0] WDCNT;			// ?
	
	assign nRESET = 1'bz; 	// ~WDCNT[10] ?
	assign nHALT = 1'b1; 	//
	
	// 300001 (LDS)
	// 0011000xxxx0000000000001
	assign WDKICK = &{~|{nLDS, RW}, ~|{A23Z, A22Z}, M68K_ADDR[21:20], ~|{M68K_ADDR[19:17]}};
	
	always @(posedge CLK or posedge WDKICK)
	begin
		if (WDKICK)
			WDCNT <= 11'b00000000000;
		else
			WDCNT <= WDCNT + 1;
	end

endmodule

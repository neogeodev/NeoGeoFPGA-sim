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

	reg [10:0] WDCNT;
	
	assign nRESET = WDCNT[10];
	assign nHALT = 1'b1;			// Todo
	
	// 300001 (LDS)
	// 0011000xxxx0000000000001
	assign WDKICK = &{~|{nLDS, RW}, ~|{A23Z, A22Z}, M68K_ADDR_U[21:20], ~|{M68K_ADDR_U[19:17], M68K_ADDR_L[12:1]}};
	
	always @(posedge WDCLK or posedge WDKICK)
	begin
		if (!nRST)
			WDCNT <= 11'b00000000000;
		else
		begin
			if (WDKICK)
				WDCNT <= 11'b10000000000;
			else
				WDCNT <= WDCNT + 1;
		end
	end

endmodule

`timescale 1ns/1ns

module watchdog(
	input nLDS, RW,
	input A23Z, A22Z,
	input [20:16] M68K_ADDR,
	input CLK,
	output nHALT,
	output nRESET,
	input VCCON				// TODO: Important for WD initialization !
);

	reg [21:0] WDCNT;		// ?
	
	assign nRESET = 1'bz; // Debug WDCNT[21];
	assign nHALT = WDCNT[21];
	
	// 300001 (LDS)
	// !!!!!!!
	// 0011000xxxx0000000000001
	
	assign WDKICK = &{~|{nLDS, RW}, ~|{A23Z, A22Z}, M68K_ADDR[20:19], ~|{M68K_ADDR[18:16]}};
	
	always @(posedge CLK)
	begin
		if (WDKICK | ~VCCON)
			WDCNT <= 22'h3FFFFF;
		else
		begin
			if (WDCNT)
				WDCNT <= WDCNT - 1;
		end
	end
	
	// 3FFFFF ? 22bits = 0.34952525s
	// 1545144 ($1793B8) reset wait 0.128762s
	// 2649159 ($286C47) reset duration ? = 0.22076325s
	
	// 384px video mclk: 1536 = 7812.5Hz (0.000128s) = 1005
	// 1024: 0.131072s -> 2ms reset ?
	// 2048: 133ms reset ?
	
	// Clocked by 8MB ? (FFFFF = 0.131071875s)

endmodule

`timescale 1ns/1ns

module c1_wait(
	input CLK_68KCLK, nAS,
	input nROM_ZONE, nPORT_ZONE, nCARD_ZONE,
	input nROMWAIT, nPWAIT0, nPWAIT1, PDTACK,
	output nDTACK
);

	reg [1:0] WAIT_CNT;
	
	//assign nPDTACK = ~(nPORT_ZONE | PDTACK);		// Really a NOR ? May stall CPU if PDTACK = GND

	assign nDTACK = nAS | |{WAIT_CNT};					// Is it nVALID instead of nAS ?
	
	//assign nCLK_68KCLK = ~nCLK_68KCLK;
	
	always @(negedge CLK_68KCLK)
	begin
		if (!nAS)
		begin
			// Count down only when nAS low
			if (WAIT_CNT) WAIT_CNT <= WAIT_CNT - 1'b1;
		end
		else
		begin
			if (!nROM_ZONE)
				WAIT_CNT <= ~nROMWAIT;				// 0~1 or 1~2 wait cycles ?
			else if (!nPORT_ZONE)
				WAIT_CNT <= ~{nPWAIT0,nPWAIT1};	// Needs checking
			else if (!nCARD_ZONE)
				WAIT_CNT <= 3;
			else
				WAIT_CNT <= 3;
		end
	end
	
endmodule

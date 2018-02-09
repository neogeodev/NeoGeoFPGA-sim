`timescale 1ns/1ns

module resetp(
	input CLK_24MB,
	input RESET,
	output RESETP
);

	// nRESET  ""|_________|""""
	// nRESETP """"""""""""|_|""
	
	FDM O52(CLK_24MB, RESET, O52_Q, );
	FDM O49(CLK_24MB, O52_Q, , O49_nQ);
	
	assign RESETP = ~&{O49_nQ, O52_Q};
	
endmodule

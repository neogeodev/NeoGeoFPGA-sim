`timescale 1ns/1ns

module resetp(
	input CLK_24M,
	input nRESET,
	output nRESETP
);

	// nRESET  ""|_________|""""
	// nRESETP """"""""""""|_|""
	
	reg nRESET_Q;
	
	// Edge detection
	always @(negedge CLK_24M)
	begin
		nRESET_Q <= nRESET;
	end
	
	assign nRESETP = ~(!nRESET_Q & nRESET);
	
endmodule

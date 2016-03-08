`timescale 1ns/1ns

module c1_wait(
	input CLK_68KCLK,
	input nROMWAIT, nPWAIT0, nPWAIT1, nPDTACK,
	output reg nDTACK
);

	reg [2:0] WAIT_CNT;

	// Wait cycle gen
	always @(posedge CLK_68KCLK)
	begin
		nDTACK <= 0;	// TODO
	end
	
endmodule

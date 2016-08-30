`timescale 1ns/1ns

// 120ns 32768*8bit RAM

module sram_u(
	input [14:0] ADDR,
	inout [7:0] DATA,
	input nCE,
	input nOE,
	input nWE
);

	reg [7:0] RAMDATA[0:32767];
	
	initial begin
		//$readmemh("raminit_sram_u.txt", RAMDATA);
	end

	assign #120 DATA = (!nCE && !nOE) ? RAMDATA[ADDR] : 8'bzzzzzzzz;

	always @(nCE or nWE)
		if (!nCE && !nWE)
			#30 RAMDATA[ADDR] <= DATA;
	
	always @(nWE or nCE)
		if (!nWE && !nOE)
			$display("ERROR: SRAMU: nOE and nWE are both active !");

endmodule

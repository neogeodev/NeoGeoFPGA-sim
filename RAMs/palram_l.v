`timescale 1ns/1ns

// 100ns 8192*8bit RAM

module palram_l(
	input [12:0] ADDR,
	inout [7:0] DATA,
	input nCE,
	input nOE,
	input nWE
);

	reg [7:0] RAMDATA[0:8191];
	
	initial begin
		$readmemh("raminit_pall.txt", RAMDATA);
	end

	assign #100 DATA = (!nCE && !nOE) ? RAMDATA[ADDR] : 8'bzzzzzzzz;

	always @(nCE or nWE)
		if (!nCE && !nWE)
			#10 RAMDATA[ADDR] <= DATA;
	
	always @(nWE or nCE)
		if (!nWE && !nOE)
			$display("ERROR: PRAML: nOE and nWE are both active !");

endmodule

`timescale 1ns/1ns

// 120ns 32768*8bit RAM

module ram68k_u(
	input [14:0] ADDR,
	inout [7:0] DATA,
	input nCE,
	input nOE,
	input nWE
);

	reg [7:0] RAMDATA[0:32767];
	wire [7:0] DATAOUT;
	
	integer k;
	initial begin
		for (k = 0; k < 32767; k = k + 1)
			RAMDATA[k] = k & 255;
		//$readmemh("raminit_68kram_u.txt", RAMDATA);
	end

	assign #120 DATA_OUT = RAMDATA[ADDR];
	assign DATA = (nCE | nOE) ? DATA_OUT : 8'bzzzzzzzz;

	always @(nCE or nWE)
		if (!nCE && !nWE)
			#30 RAMDATA[ADDR] <= DATA;
	
	always @(nWE or nCE)
		if (!nWE && !nOE)
			$display("ERROR: RAM68KU: nOE and nWE are both active !");

endmodule

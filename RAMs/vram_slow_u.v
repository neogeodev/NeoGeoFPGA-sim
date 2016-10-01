`timescale 1ns/1ns

// 120ns 32768*8bit RAM

module vram_slow_u(
	input [14:0] ADDR,
	inout [7:0] DATA,
	input nCE,
	input nOE,
	input nWE
);

	reg [7:0] RAMDATA[0:32767];
	wire [7:0] DATA_OUT;
	
	initial begin
		$readmemh("raminit_vram_slowu.txt", RAMDATA);
	end

	assign #120 DATA_OUT = RAMDATA[ADDR];
	assign DATA = (!nCE && !nOE) ? DATA_OUT : 8'bzzzzzzzz;

	always @(nCE or nWE)
		if (!nCE && !nWE)
			#30 RAMDATA[ADDR] <= DATA;
	
	always @(nWE or nCE)
		if (!nWE && !nOE)
			$display("ERROR: VRAMLU: nOE and nWE are both active !");

endmodule

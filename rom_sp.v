`timescale 10ns/10ns

// 120ns 128k*16bit ROM

module rom_sps2(
	input [15:0] ADDR,
	output [15:0] OUT,
	input nOE
);

	reg [15:0] ROMDATA[0:131071];

	initial begin
		$readmemh("rom_sps2.txt", ROMDATA);
	end

	assign #12 OUT = nOE ? 16'bzzzzzzzzzzzzzzzz : ROMDATA[ADDR];

endmodule

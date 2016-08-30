`timescale 1ns/1ns

// 120ns 65536*8bit ROM

module rom_l0(
	input [15:0] ADDR,
	output [7:0] OUT,
	input nCE
);

	reg [7:0] ROMDATA[0:65535];

	initial begin
		$readmemh("rom_l0.txt", ROMDATA);
	end

	assign #120 OUT = nCE ? 8'bzzzzzzzz : ROMDATA[ADDR];

endmodule

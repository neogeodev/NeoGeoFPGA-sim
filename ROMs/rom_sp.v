`timescale 1ns/1ns

// 120ns 128k*16bit ROM

module rom_sps2(
	input [15:0] ADDR,
	output [15:0] OUT,
	input nOE
);

	reg [15:0] ROMDATA[0:131071];
	wire [15:0] DATA;

	initial begin
		$readmemh("rom_sps2.txt", ROMDATA);
	end

	assign #120 DATA = ROMDATA[ADDR][15:0];					// 120ns from address valid to data valid
	assign #50 OUT = nOE ? 16'bzzzzzzzzzzzzzzzz : DATA;	// 50ns from OE to data valid

endmodule

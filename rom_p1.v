`timescale 10ns/10ns

// 120ns 256k*16bit ROM

module rom_p1(
	input [16:0] ADDR,
	output [15:0] OUT,
	input nROMOE
);

	reg [15:0] ROMDATA[0:262143];

	initial begin
		$readmemh("rom_p1.txt", ROMDATA);
	end

	assign #12 OUT = nROMOE ? 16'bzzzzzzzzzzzzzzzz : ROMDATA[ADDR];

endmodule

`timescale 10ns/10ns

// 100ns 16bit ROM

module rom_p1(
	input [17:0] ADDR,
	output [15:0] OUT,
	input nROMOE
);

	reg [15:0] ROMDATA[0:262143];

	initial begin
		$readmemh("rom_p1.txt", ROMDATA);
	end

	assign #10 OUT = nROMOE ? 16'bzzzzzzzzzzzzzzzz : ROMDATA[ADDR];

endmodule

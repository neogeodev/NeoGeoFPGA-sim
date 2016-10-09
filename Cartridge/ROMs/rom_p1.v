`timescale 1ns/1ns

// 120ns 512k*16bit (256kB) ROM

module rom_p1(
	input [17:0] ADDR,
	output [15:0] OUT,
	input nCE,
	input nOE
);

	reg [15:0] ROMDATA[0:262143];
	wire [15:0] DATAOUT;

	initial begin
		$readmemh("rom_p1.txt", ROMDATA);
	end

	assign #12 DATAOUT = ROMDATA[ADDR];		// TODO: Should be 120
	assign OUT = (nCE | nOE) ? 16'bzzzzzzzzzzzzzzzz : DATAOUT;

endmodule

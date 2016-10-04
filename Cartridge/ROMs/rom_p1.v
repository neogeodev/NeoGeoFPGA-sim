`timescale 1ns/1ns

// 120ns 256k*16bit ROM

module rom_p1(
	input [16:0] ADDR,
	output [15:0] OUT,
	input nCE,
	input nOE
);

	reg [15:0] ROMDATA[0:262143];
	wire [15:0] DATAOUT;

	initial begin
		$readmemh("rom_p1.txt", ROMDATA);
	end

	assign #12 DATAOUT = ROMDATA[ADDR];
	assign OUT = (nCE | nOE) ? 16'bzzzzzzzzzzzzzzzz : DATAOUT;

endmodule

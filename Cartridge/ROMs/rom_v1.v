`timescale 1ns/1ns

// 100ns 512k*8bit ROM

module rom_v1(
	input [18:0] ADDR,
	output [7:0] OUT,
	input nROMOE
);

	reg [7:0] ROMDATA[0:524287];
	wire [7:0] DATAOUT;

	initial begin
		$readmemh("rom_v1.txt", ROMDATA);
	end

	assign #100 DATAOUT = ROMDATA[ADDR];
	assign OUT = nROMOE ? 8'bzzzzzzzz : DATAOUT;

endmodule

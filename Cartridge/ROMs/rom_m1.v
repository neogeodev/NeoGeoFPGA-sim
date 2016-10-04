`timescale 10ns/10ns

// 100ns 128k*8bit ROM

module rom_m1(
	input [15:0] ADDR,
	output [7:0] OUT,
	input nCE,
	input nOE
);

	reg [7:0] ROMDATA[0:65535];
	wire [7:0] DATAOUT;

	initial begin
		$readmemh("rom_m1.txt", ROMDATA);
	end

	assign #100 DATAOUT = ROMDATA[ADDR];
	assign OUT = (nCE | nOE) ? 8'bzzzzzzzz : DATAOUT;

endmodule

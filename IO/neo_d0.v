`timescale 1ns/1ns

module neo_d0(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_6MB,
	output CLK_1MB,
	input [21:0] M68K_ADDR,
	input nBITWD0,
	input [5:0] M68K_DATA,
	output [23:0] CDA,
	output reg [2:0] P1_OUT,
	output reg [2:0] P2_OUT
);

	// Clock divider part
	clocks CLK(CLK_24M, nRESETP, CLK_12M, CLK_68KCLK, CLK_68KCLKB, CLK_6MB, CLK_1MB);

	// nCARDZONE: 8xxxxx Bxxxxx (3FFFFF) 22 bits
	// CDA: 24 bits
	reg [2:0] CDBANK;
	
	wire [1:0] CDB;
	
	assign CDB = CDBANK[2] ? 2'b11 :
						CDBANK[1] ? 2'b10 :
						CDBANK[0] ? 2'b01 :
						2'b00;
	
	assign CDA = {CDB, M68K_ADDR[21:0]};
	
	always @(negedge nBITWD0)
	begin
		if (!M68K_ADDR[3])
		begin
			// REG_POUTPUT
			P1_OUT <= M68K_DATA[2:0];
			P2_OUT <= M68K_DATA[5:3];
		end
		else
		begin
			// REG_CRDBANK
			CDBANK <= M68K_DATA[2:0];
		end
	end
	
endmodule

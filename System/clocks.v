`timescale 10ns/10ns

module clocks(
	input CLK_24M,
	input nRESETP,
	output CLK_12M,
	output CLK_68KCLK,
	output CLK_68KCLKB,
	output CLK_8M,
	output CLK_6MB,
	output CLK_4M,
	output CLK_4MB,
	output CLK_1MB
);

	reg [2:0] CLKDIV;
	reg [1:0] CLKDIV_D3;
	reg [1:0] CLKDIV2;
	
	always @(posedge CLK_24M or posedge ~nRESETP)
	begin
		if (!nRESETP)
		begin
			CLKDIV <= 0;
			CLKDIV_D3 <= 0;
			CLKDIV2 <= 0;
		end
		else
		begin
			CLKDIV <= CLKDIV + 1;
			
			if (CLKDIV_D3 == 3)
			begin
				CLKDIV_D3 <= 0;
				CLKDIV2 <= CLKDIV2 + 1;
			end
			else
				CLKDIV_D3 <= CLKDIV_D3 + 1;
		end
	end
	
	assign CLK_12M = CLKDIV[0];			// ?
	assign CLK_68KCLK = CLKDIV[0];		// ?
	assign CLK_68KCLKB = ~CLK_68KCLK;
	assign CLK_8M = CLKDIV2[0];
	assign CLK_6MB = ~CLKDIV[1];
	assign CLK_4M = CLKDIV2[1];
	assign CLK_4MB = ~CLKDIV2[1];
	assign CLK_1MB = ~CLKDIV[2];
	
endmodule

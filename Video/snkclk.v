`timescale 1ns/1ns

module snkclk(
	input CLK_6MB,	//P2		// 6M
	input nRESET,	// Which pin is this ? No reset ?
	output P8, 		//P40,	// 3M(1MB)
	output P26,	 	//P39,	// 1.5M
	output P7, 		//P38,	// 750k
	output P25, 	//P37,	// 375k
	output P6, 		//P36,	// 187k
	output P24, 	//P35,	// 94k
	output P5, 		//P34,	// 47k
	output P4,		// Gated HSYNC
	output P11,		// BNKB
	output P20,
	output reg P22,
	output P23,
	output [7:0] LINE,	// P12~P19
	output reg ACTIVE,	// 9th bit in REG_LSPCMODE line counter, seems to be kept internal in SNKCLK
	output P31,
	output P32,
	output P33
);

	reg [8:0] DIV_PIXEL;
	reg [2:0] DIV_LINE_LOW;
	reg [4:0] DIV_LINE_HIGH;
	reg [4:0] DIV_HSYNC;
	
	assign P20 = ~DIV_PIXEL[8];
	assign P23 = |{DIV_PIXEL[8:7]};
	assign P31 = DIV_PIXEL[6] & DIV_PIXEL[8];
	assign P32 = ~P20;
	assign P33 = DIV_PIXEL[7] ^ P31;
	
	assign P8 = DIV_PIXEL[0];
	assign P26 = DIV_PIXEL[1];
	assign P7 = DIV_PIXEL[2];
	assign P25 = DIV_PIXEL[3];
	assign P6 = DIV_PIXEL[4];
	assign P24 = DIV_PIXEL[5];
	assign P5 = DIV_PIXEL[6];
	assign P4 = ACTIVE & |{DIV_HSYNC[4:1]};
	assign P11 = |{DIV_LINE_HIGH[4:1]} & ~&{DIV_LINE_HIGH[4:1]};
	assign LINE = {DIV_LINE_HIGH, DIV_LINE_LOW};

	always @(posedge CLK_6MB or negedge nRESET)
	begin
		if (!nRESET)
		begin
			DIV_PIXEL <= 9'd0;
			DIV_LINE_LOW <= 3'd0;
			DIV_LINE_HIGH <= 5'd0;
			ACTIVE <= 1'b1;
			DIV_HSYNC <= 5'd5;		// Value on reset ?
		end
		else
		begin
			if (DIV_PIXEL == 9'd383)
			begin
				// One line done
				DIV_PIXEL <= 9'd0;
				
				if (DIV_LINE_LOW == 3'b111)
				begin
					DIV_LINE_LOW <= 3'd0;
					if (DIV_LINE_HIGH == 5'b11111)
					begin
						if (!ACTIVE)	// Must start at 1
						begin
							DIV_LINE_HIGH <= 5'd0;
							DIV_HSYNC <= 5'd5;		// Value on reset ?
						end
						ACTIVE <= ~ACTIVE;
					end
					else
						DIV_LINE_HIGH <= DIV_LINE_HIGH + 1'b1;
				end
				else
					DIV_LINE_LOW <= DIV_LINE_LOW + 1'b1;
			end
			else
				DIV_PIXEL <= DIV_PIXEL + 1'b1;
				
			if (DIV_PIXEL[2:0] == 3'b111)
				P22 <= P20;
			
			if (DIV_PIXEL[3:0] == 4'b1111)
			begin
				if (DIV_HSYNC == 5'd23)
					DIV_HSYNC <= 5'd0;
				else
					DIV_HSYNC <= DIV_HSYNC + 1'b1;
			end
		end
	end

endmodule

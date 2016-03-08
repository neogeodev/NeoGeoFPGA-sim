`timescale 10ns/10ns

module p_cycle(
	input CLK_24M,
	input HSYNC,
	input [16:0] FIX_ADDR,
	input [3:0] FIX_PAL,
	input [24:0] SPR_ADDR,
	input [7:0] SPR_PAL,
	input [7:0] SPR_XPOS,
	input [15:0] L0_ADDR,
	
	output PCK1, PCK2,
	output LOAD,
	output reg nVCS,
	output reg [7:0] L0_DATA,
	inout [23:0] PBUS
);

	// 25 bits = 33554431
	// 32bits/address: 4 bytes
	// 1sprtile = 128 bytes
	// /4 = 32
	// 1048576 tiles

	reg [4:0] CYCLE_P;		// Both
	reg [3:0] CYCLE_PCK;		// Neg
	reg [3:0] CYCLE_LOAD;	// Pos
	
	reg [23:16] PBUS_U;		// inout
	reg [15:0] PBUS_L;		// out
	
	assign nCLK_24M = ~CLK_24M;
	
	assign PBUS = {PBUS_U, PBUS_L};
	
	assign PCK2 = ~|{CYCLE_PCK[3:0]};							// 0
	assign PCK1 = (CYCLE_PCK[3:0] == 4'b1000) ? 1 : 0;		// 8
	assign LOAD = CYCLE_LOAD[2] & CYCLE_LOAD[1];				// 6-7 14-15
	
	// 28px backporch
	
	always @(posedge CLK_24M or posedge nCLK_24M)
	begin
		if (HSYNC)
		begin
			CYCLE_P <= 0;
			CYCLE_LOAD <= 0;
			CYCLE_PCK <= 0;
		end
		else
		begin
			CYCLE_P <= CYCLE_P + 1;
			if (CLK_24M)
				CYCLE_LOAD <= CYCLE_LOAD + 1;		// Pos
			else
				CYCLE_PCK <= CYCLE_PCK + 1;		// Neg
			
			// Can nVCS be assigned from CYCLE_L instead ?
			if (CYCLE_LOAD == 9) nVCS <= 1'b0;
			if (CYCLE_LOAD == 14) nVCS <= 1'b1;
			
			case (CYCLE_P)
				0, 1, 2 :
				begin
					// FIXT
					PBUS_L <= {FIX_ADDR[4], FIX_ADDR[2:0], FIX_ADDR[16:5]};
					PBUS_U <= 8'b00000000;			// z?
					//S2H1 <= FIX_ADDR[3];
				end
				3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13:
				begin
					// FF0000
					PBUS_L <= 16'b0000000000000000;
					PBUS_U <= 8'b11111111;			// Probably z
				end
				14, 15:
				begin
					// FP
					PBUS_L <= 16'b0000000000000000;
					PBUS_U <= {4'b0000, FIX_PAL};
				end
				16, 17, 18:
				begin
					// SPRT
					PBUS_L <= SPR_ADDR[20:5];
					PBUS_U <= {SPR_ADDR[24:21], SPR_ADDR[3:0]};
					//CA4 <= SPR_ADDR[4];
				end
				19, 20, 21, 22, 23, 24, 25, 26, 27, 28:
				begin
					// L0
					PBUS_L <= L0_ADDR;
					PBUS_U <= 8'bzzzzzzzz;
				end
				29:
				begin
					// Special case, so probably wrong. Read from L0
					L0_DATA <= PBUS_U;
				end
				30, 31:
				begin
					// SP
					PBUS_L <= {SPR_XPOS, 8'b00000000};
					PBUS_U <= SPR_PAL;
				end
			endcase
		end
	end

endmodule

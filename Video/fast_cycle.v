`timescale 1ns/1ns

module fast_cycle(
	input CLK_24M,
	input nRESETP,
	
	input [8:0] V_COUNT,
	input CHBL,
	input BFLIP,
	
	output reg [8:0] ATTR_XPOS,
	output reg [8:0] RENDER_IDX,
	output reg [4:0] TILE_IDX,
	output reg [3:0] TILE_LINE,
	output reg [11:0] ATTR_SHRINK,
	
	input [10:0] REG_VRAMMOD,
	input RELOAD_REQ,
	
	input [10:0] CPU_ADDR,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_ZONE,
	input CPU_WRITE,
	output CPU_WRITE_ACK
);

	reg [10:0] CPU_ADDR_FAST;
	
	// Fast VRAM is 35ns, so at least 1mclk needed between address set and data valid
	
	reg ATTR_STICKY;
	reg [5:0] ATTR_SIZE;		// 4+1 ?

	reg [4:0] CYCLE_FAST;	// 32 cycles of CLK_24M, 10 states
	
	reg [6:0] LIST_WRITE_COUNTER;
	reg [6:0] LIST_READ_COUNTER;
	
	reg [8:0] PARSE_COUNTER;	// Sprite number
	reg [8:0] PARSE_LATCH_A;	// Sprite number
	reg [8:0] PARSE_LATCH_B;	// Sprite number
	wire [8:0] PARSE_LATCH_MUX;
	
	wire [10:0] PARSE_READ_ADDR;
	wire [10:0] PARSE_WRITE_ADDR;
	wire [10:0] PARSE_ADDR;
	wire [10:0] SCB2_ADDR;
	wire [10:0] SCB3_ADDR;
	wire [10:0] SCB4_ADDR;
	wire [10:0] RENDER_ADDR;
	
	wire [7:0] Y_ADDED;
	wire [3:0] RENDER_LINE;
	
	wire [10:0] C;		// Fast VRAM address
	wire [15:0] F;		// Fast VRAM data
	
	wire nCWE;
	reg nCWE_CPU;
	reg nCWE_LIST;
	reg RELOAD_CPU_ADDR;
	
	reg [1:0] PARSE_MODE;
	
	vram_fast_u VRAMUU(C, F[15:8], 1'b0, 1'b0, nCWE);
	vram_fast_l VRAMUL(C, F[7:0], 1'b0, 1'b0, nCWE);
	
	assign TEST = (CYCLE_FAST == 5'd0) ? 1'b1 : 1'b0;
	always @(posedge RELOAD_REQ or posedge TEST)
	begin
		if (RELOAD_REQ)
			RELOAD_CPU_ADDR <= 1'b1;
		else
			RELOAD_CPU_ADDR <= 1'b0;
	end
	
	assign CPU_WRITE_ACK = nCWE_CPU | ~CPU_ZONE;		// Does this work ?
	
	// Fast VRAM address generator
	assign PARSE_WRITE_ADDR = {3'd6, ~BFLIP, LIST_WRITE_COUNTER};	// $600+ or $680+
	assign PARSE_READ_ADDR = {2'd1, PARSE_COUNTER};				// $200~$3FF
	assign RENDER_ADDR = {3'd6, BFLIP, LIST_READ_COUNTER};	// $600+ or $680+
	assign SCB2_ADDR = {2'd0, RENDER_IDX};		// $000~$1FF (shrinking values)
	assign SCB3_ADDR = {2'd1, RENDER_IDX};		// $200~$3FF (Y, sticky bit and height)
	assign SCB4_ADDR = {2'd2, RENDER_IDX};		// $400~$5FF (X positions)
	
	assign PARSE_ADDR = PARSE_MODE[1] ? PARSE_WRITE_ADDR : PARSE_READ_ADDR;
	
	// Cycle order is good at least: CPU, 5 parse, read active list, SCB2, SCB3, SCB4
	assign C = ((CYCLE_FAST >= 5'd00) && (CYCLE_FAST <= 5'd03)) ? RENDER_ADDR :	// Read active list (TODO)
					((CYCLE_FAST >= 5'd04) && (CYCLE_FAST <= 5'd06)) ? SCB2_ADDR :		// SCB2 (TODO)
					((CYCLE_FAST >= 5'd07) && (CYCLE_FAST <= 5'd09)) ? SCB3_ADDR :		// SCB3 (TODO)
					((CYCLE_FAST >= 5'd10) && (CYCLE_FAST <= 5'd12)) ? SCB4_ADDR :		// SCB4 (TODO)
					((CYCLE_FAST >= 5'd13) && (CYCLE_FAST <= 5'd15)) ? CPU_ADDR_FAST : // CPU
					PARSE_ADDR;		// 5x parse (TODO)
	
	assign F = nCWE ? 16'bzzzzzzzzzzzzzzzz :
					((CYCLE_FAST >= 5'd13) && (CYCLE_FAST <= 5'd15)) ? CPU_WRDATA :	// CPU
					{7'd0, PARSE_LATCH_MUX};
	
	assign PARSE_LATCH_MUX = PARSE_MODE[0] ? PARSE_LATCH_B : PARSE_LATCH_A;
	
	assign nCWE = ((CYCLE_FAST >= 5'd13) && (CYCLE_FAST <= 5'd15)) ? nCWE_CPU : 
						((CYCLE_FAST >= 5'd16) && (CYCLE_FAST <= 5'd31)) ? nCWE_LIST : 
						1'b1;
	
	assign nCLK_24M = ~CLK_24M;
	
	// Sprite line comparator
	assign {Y_CARRY, Y_ADDED} = F[14:7] + V_COUNT[7:0] + 1'b1;	// F[14:7] is SPRITE_Y[7:0]
	assign SIG1 = Y_CARRY;	// ^ F[15];										// F[15] is SPRITE_Y[8]
	
	assign RENDER_LINE = Y_ADDED[3:0];	// Alpha68k: this is synchronized to 1.5M_RAW
	
	always @(posedge CLK_24M or posedge nCLK_24M)		// Use P bus cycle counter ?
	begin
		if (!nRESETP)
		begin
			CYCLE_FAST <= 5'd0;
			PARSE_MODE <= 2'd0;
			nCWE_LIST <= 1'b1;
		end
		else
		begin
			CYCLE_FAST <= CYCLE_FAST + 1'b1;
			
			// Reset sprite parsing counters each line, probably not related to CHBL
			if (CHBL)
			begin
				LIST_WRITE_COUNTER <= 7'd0;
				LIST_READ_COUNTER <= 7'd0;
				PARSE_COUNTER <= 9'd0;
			end
			
				case (CYCLE_FAST)
					5'd14:
					begin
						// End-1 of CPU cycle
						CPU_RDDATA <= F;
						if (!nCWE_CPU)
							CPU_ADDR_FAST <= CPU_ADDR_FAST + REG_VRAMMOD;
						nCWE_CPU <= 1'b1;
					end
					
					5'd19, 5'd22, 5'd25, 5'd28, 5'd31:
					begin
						// End of parse cycles
						if (PARSE_MODE[1])
							nCWE_LIST <= 1'b0;
						else
							PARSE_COUNTER <= PARSE_COUNTER + 1'b1;
					end
					
					5'd18, 5'd21, 5'd24, 5'd27, 5'd30:
					begin
						// End-1 of parse cycles
						//PARSE_MODE
						//00: Set latch 1 -> 01
						//01: Set latch 2 -> 10
						//10: Write 1 to list -> 11
						//11: Write 2 to list -> 00
						
						if (PARSE_MODE[1])
							nCWE_LIST <= 1'b1;
						
						// What happens when only one sprite matches on a line ?:
						// When is latch 1 written to the list if latch 2 is never set ?
						
						case (PARSE_MODE)
							2'b00:
							begin
								if (SIG1)
								begin
									PARSE_LATCH_A <= PARSE_COUNTER;
									PARSE_MODE <= 2'b01;
								end
							end
							
							2'b01:
							begin
								if (SIG1)
								begin
									PARSE_LATCH_B <= PARSE_COUNTER;
									PARSE_MODE <= 2'b10;
								end
							end
							
							2'b10:
							begin
								// Combi only ?
								PARSE_MODE <= 2'b11;
								LIST_WRITE_COUNTER <= LIST_WRITE_COUNTER + 1'b1;
							end
							
							2'b11:
							begin
								// Combi only ?
								PARSE_MODE <= 2'b00;
								LIST_WRITE_COUNTER <= LIST_WRITE_COUNTER + 1'b1;
							end
						endcase
						
						// For a 1-tile-high sprite:
						// How does height affect match ?
						// HEIGHT = 1        0 0001			8BIT CARRY		SIG1 (CARRY ^ SPRITE_Y[8])
						// 496 + 0 = 496		1 1111 0000		0					1
						// 496 + 1 = 497		1 1111 0001		0					1
						// 496 + 2 = 498		1 1111 0010		0					1
						// 496 + 3 = 499		1 1111 0011		0					1
						// 496 + 4 = 500		1 1111 0100		0					1
						// 496 + 5 = 501		1 1111 0101		0					1
						// 496 + 6 = 502		1 1111 0110		0					1
						// 496 + 7 = 503		1 1111 0111		0					1
						// 496 + 8 = 504		1 1111 1000		0					1
						// 496 + 9 = 505		1 1111 1001		0					1
						// 496 + 10 = 506		1 1111 1010		0					1
						// 496 + 11 = 507		1 1111 1011		0					1
						// 496 + 12 = 508		1 1111 1100		0					1
						// 496 + 13 = 509		1 1111 1101		0					1
						// 496 + 14 = 510		1 1111 1110		0					1
						// 496 + 15 = 511		1 1111 1111		0					1
						// 496 + 16 = 512		1 0000 0000		1					0
						// 496 + 17 = 513		1 0000 0001		1					0
						// 496 + 18 = 514		1 0000 0010		1					0
					end
					5'd02:
					begin
						// End of active list read for render cycle
						RENDER_IDX <= F;
					end
					5'd05:
					begin
						// End of SCB2 read cycle
						ATTR_SHRINK <= F[11:0];
					end
					5'd08:
					begin
						// End of SCB3 read cycle
						ATTR_STICKY <= F[6];
						ATTR_SIZE <= F[5:0];
						TILE_IDX <= {~Y_CARRY, Y_ADDED[7:4]};	// Tilemap index
						TILE_LINE <= RENDER_LINE;
					end
					5'd11:
					begin
						// End of SCB4 read cycle, start of CPU cycle
						ATTR_XPOS <= F[15:7];
						
						LIST_READ_COUNTER <= LIST_READ_COUNTER + 1'b1;
						
						if (RELOAD_CPU_ADDR)
							CPU_ADDR_FAST <= CPU_ADDR;
						nCWE_CPU <= ~(CPU_WRITE & CPU_ZONE);
					end
				endcase
		end
	end

endmodule

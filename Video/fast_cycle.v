`timescale 1ns/1ns

module fast_cycle(
	input CLK_24M,
	input nRESETP,
	
	input [8:0] V_COUNT,
	input CHBL,
	input BFLIP,
	
	output reg [8:0] SPR_ATTR_XPOS,
	output reg [8:0] SPR_RENDER_IDX,
	output reg [4:0] SPR_TILE_IDX,
	output reg [3:0] SPR_TILE_LINE,
	output reg [11:0] SPR_ATTR_SHRINK,
	
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
	
	reg SPR_ATTR_STICKY;
	reg [5:0] SPR_ATTR_SIZE;	// 4 ?
	//reg [8:0] SPR_ATTR_YPOS;

	reg [4:0] CYCLE_FAST;		// 32 cycles of CLK_24M, 10 states
	
	reg [6:0] AL_FILL_COUNTER;
	reg [6:0] AL_READ_COUNTER;
	
	reg [8:0] SPR_PARSE_COUNTER;
	//reg [8:0] SPR_RENDER_IDX;
	
	wire [10:0] PARSE_ADDR;
	wire [10:0] SCB2_ADDR;
	wire [10:0] SCB3_ADDR;
	wire [10:0] SCB4_ADDR;
	wire [10:0] RENDER_ADDR;
	
	wire [7:0] Y_ADDED;
	
	wire [10:0] C;		// Fast VRAM address
	wire [15:0] F;		// Fast VRAM data
	
	reg nCWE;
	reg RELOAD_CPU_ADDR;
	
	reg MATCHED;
	reg ADVANCE;
	reg WRITING;
	
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
	
	assign CPU_WRITE_ACK = nCWE;	// Does this work ?
	
	
	assign SCB2_ADDR = {2'b00, SPR_RENDER_IDX};		// $000~$1FF (shrinking values)
	assign SCB3_ADDR = {2'b01, SPR_RENDER_IDX};		// $200~$3FF (Y, sticky bit and height)
	assign SCB4_ADDR = {2'b10, SPR_RENDER_IDX};		// $400~$5FF (X positions)
	
	assign PARSE_ADDR = WRITING ? {3'b110, BFLIP, AL_FILL_COUNTER} :
										{2'b01, SPR_PARSE_COUNTER};	// $200~$3FF or $600+
	assign RENDER_ADDR = {3'b110, ~BFLIP, AL_READ_COUNTER};	// $600+
	
	// TODO: Cycle sync with the rest is wrong
	// Cycle order is good at least: CPU, 5 parse, read active list, SCB2, SCB3, SCB4
	assign C = ((CYCLE_FAST >= 5'd00) && (CYCLE_FAST <= 5'd02)) ? CPU_ADDR_FAST : // CPU
					((CYCLE_FAST >= 5'd03) && (CYCLE_FAST <= 5'd18)) ? PARSE_ADDR :	// 5x parse (TODO)
					((CYCLE_FAST >= 5'd19) && (CYCLE_FAST <= 5'd22)) ? RENDER_ADDR :	// Read active list (TODO)
					((CYCLE_FAST >= 5'd23) && (CYCLE_FAST <= 5'd25)) ? SCB2_ADDR :		// SCB2 (TODO)
					((CYCLE_FAST >= 5'd26) && (CYCLE_FAST <= 5'd28)) ? SCB3_ADDR :		// SCB3 (TODO)
					SCB4_ADDR;																			// SCB4 (TODO)

	assign F = nCWE ? 16'bzzzzzzzzzzzzzzzz :
					((CYCLE_FAST >= 5'd00) && (CYCLE_FAST <= 5'd02)) ? CPU_WRDATA : // CPU
					{7'd0, SPR_PARSE_COUNTER};
	
	assign nCLK_24M = ~CLK_24M;
	
	assign {Y_CARRY, Y_ADDED} = F[14:7] + V_COUNT[7:0] + 1'b1;	// F[14:7] is SPRITE_Y[7:0]
	assign SIG1 = Y_CARRY ^ F[15];										// F[15] is SPRITE_Y[8]
	
	wire [8:0] SPR_RENDER_LINE;
	assign SPR_RENDER_LINE = F[14:7] + V_COUNT[7:0];
	
	// Todo: Wrong cycles, sync/clock hack again.
	always @(posedge CLK_24M or posedge nCLK_24M)		// Use P bus cycle counter ?
	begin
		if (CHBL)	// !nRESETP ? Resync cycle just on reset pulse (cycle continues during reset, right ?)
		begin
			CYCLE_FAST <= 5'd0;
			MATCHED <= 1'b0;
			AL_FILL_COUNTER <= 7'd0;
			AL_READ_COUNTER <= 7'd0;
			SPR_PARSE_COUNTER <= 9'd0;
			ADVANCE <= 1'b0;
			WRITING <= 1'b0;
		end
		else
		begin
			case (CYCLE_FAST)
				5'd1:		// TESTING 1, was 2
				begin
					// End of CPU cycle
					CPU_RDDATA <= F;
					if (!nCWE)
						CPU_ADDR_FAST <= CPU_ADDR_FAST + REG_VRAMMOD;
					nCWE <= 1'b1;
				end
				
				5'd5, 5'd8, 5'd11, 5'd14, 5'd17:
				begin
					// End-1 of parse cycles
					ADVANCE <= 1'b1;
					
					if (!nCWE)
					begin
						MATCHED <= 1'b0;
						nCWE <= 1'b1;		// Return to normal
					end
					else
					begin
						// Latch if we need to write the current sprite to the active list at next parsing cycle
						MATCHED <= SIG1;
					end
					
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
				5'd21:
				begin
					// End of active list read cycle (should be 22 ?)
					SPR_RENDER_IDX <= F;
				end
				5'd24:
				begin
					// End of SCB2 read cycle (should be 25 ?)
					SPR_ATTR_SHRINK <= F[11:0];
				end
				5'd27:
				begin
					// End of SCB3 read cycle (should be 28 ?)
					SPR_ATTR_STICKY <= F[6];
					SPR_ATTR_SIZE <= F[5:0];
					SPR_TILE_IDX <= SPR_RENDER_LINE[8:4];
					SPR_TILE_LINE <= SPR_RENDER_LINE[3:0];
				end
				5'd31:
				begin
					// End of SCB4 read cycle, start of CPU cycle
					SPR_ATTR_XPOS <= F[15:7];
					
					AL_READ_COUNTER <= AL_READ_COUNTER + 1'b1;
					if (RELOAD_CPU_ADDR)
						CPU_ADDR_FAST <= CPU_ADDR;
					nCWE <= ~(CPU_WRITE & CPU_ZONE);
				end
			endcase
			
			// The sprite match logic and active list filling works but must be way simpler
			if (ADVANCE)
			begin
				ADVANCE <= 1'b0;
				if (MATCHED)
				begin
					// We need to write the index of the last parsed sprite to the active list
					// This cycle should output the active list address
					// And the last parsed sprite index as data
					WRITING <= 1'b1;
					nCWE <= 1'b0;
				end
				else
					SPR_PARSE_COUNTER <= SPR_PARSE_COUNTER + 1'b1;
				
				if (WRITING)
				begin
					WRITING <= 1'b0;
					AL_FILL_COUNTER <= AL_FILL_COUNTER + 1'b1;
				end
			end
			
			CYCLE_FAST <= CYCLE_FAST + 1'b1;
		end
	end

endmodule

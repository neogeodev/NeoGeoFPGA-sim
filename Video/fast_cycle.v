`timescale 1ns/1ns

module fast_cycle(
	input CLK_24M,
	input nRESETP,
	
	input [10:0] CPU_ADDR_WR,
	input [10:0] CPU_ADDR_RD,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_ZONE,
	input CPU_RW
);

	// Fast VRAM is 35ns, so at least 1mclk needed between address set and data valid
	// Todo: CPU access if zone=1
	
	reg [11:0] SPR_ATTR_SHRINK;
	reg [8:0] SPR_ATTR_YPOS;
	reg SPR_ATTR_STICKY;
	reg [5:0] SPR_ATTR_SIZE;	// 4 ?
	reg [8:0] SPR_ATTR_XPOS;

	reg [4:0] CYCLE_FAST;		// 32 cycles of CLK_24M, 10 states
	
	reg [8:0] SPR_PARSEIDX;
	reg [8:0] SPR_RENDERIDX;
	
	wire [10:0] YMATCH_ADDR;
	wire [10:0] SCB2_ADDR;
	wire [10:0] SCB3_ADDR;
	wire [10:0] SCB4_ADDR;
	//wire [10:0] RENDER_ADDR;
	
	reg CPU_RW_LATCHED;
	
	wire [10:0] C;		// High VRAM address
	wire [15:0] F;		// High VRAM data
	
	
	assign nCWE = (CPU_RW_LATCHED | ~CPU_ZONE | (CYCLE_FAST >= 5'd03));		// TODO: Verify on hw
	
	vram_fast_u VRAMUU(C, F[15:8], 1'b0, 1'b0, nCWE);
	vram_fast_l VRAMUL(C, F[7:0], 1'b0, 1'b0, nCWE);
	
	assign YMATCH_ADDR = {2'b00, SPR_PARSEIDX};	// $0000~$01FF
	assign SCB2_ADDR = {2'b00, SPR_RENDERIDX};	// $0000~$01FF
	assign SCB3_ADDR = {2'b01, SPR_RENDERIDX};	// $0200~$03FF
	assign SCB4_ADDR = {2'b10, SPR_RENDERIDX};	// $0400~$05FF
	
	// TODO: Cycle sync with the rest is wrong
	// Cycle order is good at least: CPU, 5 parse, read active list, SCB2, SCB3, SCB4
	assign C = ((CYCLE_FAST >= 5'd00) && (CYCLE_FAST <= 5'd02)) ? 
						(CPU_RW_LATCHED) ? CPU_ADDR_RD : CPU_ADDR_WR :						// CPU
					((CYCLE_FAST >= 5'd03) && (CYCLE_FAST <= 5'd18)) ? YMATCH_ADDR :	// Parse (TODO)
					((CYCLE_FAST >= 5'd19) && (CYCLE_FAST <= 5'd22)) ? 11'd0 :			// Read list (TODO)
					((CYCLE_FAST >= 5'd23) && (CYCLE_FAST <= 5'd25)) ? SCB2_ADDR :		// SCB2 (TODO)
					((CYCLE_FAST >= 5'd26) && (CYCLE_FAST <= 5'd28)) ? SCB3_ADDR :		// SCB3 (TODO)
					SCB4_ADDR;																			// SCB4 (TODO)
	
	assign F = (((CYCLE_FAST >= 5'd00) && (CYCLE_FAST <= 5'd02)) && (~CPU_RW_LATCHED & CPU_ZONE)) ?
					CPU_WRDATA : 16'bzzzzzzzzzzzzzzzz;
	
	//TODO: display lists
	//assign AL1_ADDR = {4'b1100, SPR_PARSEIDX};	// $0600
	//assign AL2_ADDR = {4'b1101, SPR_PARSEIDX};	// $0680
	
	assign nCLK_24M = ~CLK_24M;
	// Todo: Wrong cycles, sync/clock hack again.
	always @(posedge CLK_24M or posedge nCLK_24M)		// Use P bus cycle counter ?
	begin
		if (!nRESETP)
		begin
			CYCLE_FAST <= 0;	// Resync cycle just on reset pulse (cycle continues during reset, right ?)
		end
		else
		begin
			case (CYCLE_FAST)
				5'd1:
				begin
					// End of CPU cycle (should be 2 ?)
					if (CPU_RW_LATCHED)
						CPU_RDDATA <= F;	// Read: latch data
				end
				5'd5:
				begin
					// End of parse cycle A (should be 6 ?)
					/*
					SPR_PARSEIDX <= SPR_PARSEIDX + 1;			// This is conditional !
					// How is clearing of the rest of the active list done ? Just fill with 0's after parsing up to 127 ?
					// SPR_PARSEIDX up to 383, then fill with 0's ?
					*/
				end
				5'd21:
				begin
					// End of active list read cycle (should be 22 ?)
				end
				// ...
				5'd24:
				begin
					// End of SCB2 read cycle (should be 25 ?)
				end
				5'd27:
				begin
					// End of SCB3 read cycle (should be 28 ?)
				end
				5'd30:
				begin
					// End of SCB4 read cycle (should be 31 ?)
				end
				5'd31:
				begin
					// Merged with previous ?
					SPR_RENDERIDX <= SPR_RENDERIDX + 1;
					
					if (!CPU_RW_LATCHED)
						CPU_RW_LATCHED <= 1'b1;		// Do writes only once. Ugly, probably simpler.
					else
						CPU_RW_LATCHED <= CPU_RW;	// Avoids CPU_RW changing during VRAM CPU access cycle (not verified on hw)
				end
			endcase
			
			CYCLE_FAST <= CYCLE_FAST + 1'b1;
		end
	end

endmodule

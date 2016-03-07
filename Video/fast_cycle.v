`timescale 10ns/10ns

module fast_cycle(
	input CLK_24M,
	
	input [10:0] CPU_ADDR,
	output reg [15:0] CPU_RDDATA,
	input [15:0] CPU_WRDATA,
	input CPU_PENDING,
	input CPU_ZONE,
	input CPU_RW
);

	// Todo: CPU access if pending=1, zone=1

	reg [4:0] CYCLE;	// 32 cycles of CLK_624M, 10 states
	
	reg [8:0] SPR_PARSEIDX;
	reg [8:0] SPR_RENDERIDX;
	
	wire [10:0] YMATCH_ADDR;
	
	wire [10:0] SCB2_ADDR;
	wire [10:0] SCB3_ADDR;
	wire [10:0] SCB4_ADDR;
	wire [10:0] RENDER_ADDR;
	
	assign YMATCH_ADDR = {2'b00, SPR_PARSEIDX};	// $0000
	
	assign SCB2_ADDR = {2'b00, SPR_RENDERIDX};	// $0000
	assign SCB3_ADDR = {2'b01, SPR_RENDERIDX};	// $0200
	assign SCB4_ADDR = {2'b10, SPR_RENDERIDX};	// $0400
	
	//assign AL1_ADDR = {4'b1100, SPR_PARSEIDX};	// $0600
	//assign AL2_ADDR = {4'b1101, SPR_PARSEIDX};	// $0680

	wire [10:0] C;		// High VRAM address
	wire [15:0] F;		// High VRAM data
	
	// Warning: Update this according to cycle order if changed !
	
	// 29, 30, 31 reserved for CPU access
	assign C = (!CYCLE[4]) ? YMATCH_ADDR : (&{CYCLE[4:3]} & |{CYCLE[2:1]}) ? CPU_ADDR : RENDER_ADDR;
	
	// ((HCOUNT / 8) << 5) | ((VCOUNT & 255) / 8)
	//assign FIXVRAM_ADDR = {4'b1110, HCOUNT[8:3], VCOUNT[7:3]};
	
	// SPR_IDX   /------- --xxxxx! [4:0]
	// SPR_NB    /xxxxxxx xx-----! [8:0]
	//assign SPRVRAM_ADDR = {SPR_NB, SPR_IDX};
	
	assign nCLK_24M = ~CLK_24M;
	
	always @(posedge CLK_24M or posedge nCLK_24M)		// negedge ?
	begin
		CYCLE <= CYCLE + 1;
		case (CYCLE)
			0, 4, 7, 10, 13:
			begin
				if (CYCLE == 3) // 6, 9, 12, 15
				// Parsing cycles
				SPR_PARSEIDX <= SPR_PARSEIDX + 1;			// This is conditional !
				// How is clearing of the rest of the active list done ? Just fill with 0's after parsing up to 127 ?
				// SPR_PARSEIDX up to 383, then fill with 0's ?
			end
			16, 20, 23, 26:
			begin
				// Rendering cycles
				// Todo
			end
			30: SPR_RENDERIDX <= SPR_RENDERIDX + 1;
		endcase
	end

	vram_fast_u VRAMUU(C, F[15:8], nCWE, 1'b0, 1'b0);
	vram_fast_l VRAMUL(C, F[7:0], nCWE, 1'b0, 1'b0);

endmodule

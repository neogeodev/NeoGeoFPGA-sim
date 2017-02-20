`timescale 1ns/1ns

module lspc_regs(
	input nRESET,
	
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	
	input nLSPOE,
	input nLSPWE,
	
	input [2:0] AA_COUNT,
	
	output [15:0] REG_LSPCMODE,
	
	output reg [31:0] TIMERLOAD,		// Reload value
	output reg TIMERSTOP,				// Timer pause in top and bottom of display in PAL mode (LSPC2)
	output reg [15:0] REG_VRAMMOD,
	output reg [2:0] TIMERINT_MODE,	// Timer interrupt mode
	output reg TIMERINT_EN,				// Timer interrupt enable
	output reg [7:0] AA_SPEED,			// Auto-animation speed
	output reg AA_DISABLE,				// Auto-animation disable
	
	output reg IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3
);

	wire [15:0] REG_LSPCMODE;
	
	// Read
	// Todo: See if 3'b000 is right (3'b111 ?)
	assign REG_LSPCMODE = {VCOUNT, 3'b000, VIDEO_MODE, AA_COUNT};
	
	// Read
	// Todo: See if M68K_ADDR[3] is used or not (msvtech.txt says no, MAME says yes)
	// Todo: See if ~nLSPWE is used
	assign M68K_DATA = (nLSPOE | ~nLSPWE) ? 16'bzzzzzzzzzzzzzzzz :
								(M68K_ADDR[2] == 1'b0) ? CPU_VRAM_READ_BUFFER :		// $3C0000,$3C0002,$3C0008,$3C000A
								(M68K_ADDR[1] == 1'b0) ? REG_VRAMMOD :					// 3C0004/3C000C
								REG_LSPCMODE;													// 3C0006/3C000E
	
	// Write to $3C000C
	always @(nLSPWE or nRESET)
	begin
		if (!nRESET)
		begin
			{IRQ_R3, IRQ_R2, IRQ_R1} <= 3'b111;		// Todo: Cold boot starts off with IRQ3
			{IRQ_S2, IRQ_S1} <= 2'b00;
		end
		else
		begin
			// $3C000C: Interrupt ack
			if ((!nLSPWE) && (M68K_ADDR[3:1] == 3'b110))
				{IRQ_R3, IRQ_R2, IRQ_R1} <= M68K_DATA[2:0];
			else
				{IRQ_R3, IRQ_R2, IRQ_R1} <= 3'b000;
		end
	end
	
	
	always @(negedge nLSPWE or negedge nRESET)	// ?
	begin
		if (!nRESET)
		begin
			// Something ?
		end
		else
		begin
			case (M68K_ADDR[3:1])
				// $3C0000: Set address
				3'b000 :
				begin
					// Read happens as soon as address is set (CPU access slot defaults to "read" all the time ?)
					//$display("VRAM set address to 0x%H", M68K_DATA);	// DEBUG
					{CPU_VRAM_ZONE, CPU_VRAM_ADDR} <= M68K_DATA;			// Ugly, probably simpler
					CPU_VRAM_ADDRESS_BUFFER <= M68K_DATA;					// Ugly, probably simpler
					CPU_RW <= 1'b1;		// To check: Default operation after address set is read ?
				end
				// $3C0002: Write data
				3'b001 :
				begin
					//$display("VRAM write data 0x%H @ 0x%H", M68K_DATA, {CPU_VRAM_ZONE, CPU_VRAM_ADDR});	// DEBUG
					CPU_VRAM_WRITE_BUFFER <= M68K_DATA;
					CPU_VRAM_ADDRESS_BUFFER <= CPU_VRAM_ADDR;
					CPU_VRAM_ADDR <= CPU_VRAM_ADDR + REG_VRAMMOD[14:0];	// Todo: Wrong, sign is used and addr MSB is kept
					CPU_RW <= 1'b0;		// Operation: write
				end
				// $3C0004: Set modulo
				3'b010 : 
				begin
					$display("VRAM set modulo to 0x%H", M68K_DATA);		// DEBUG
					REG_VRAMMOD <= M68K_DATA;
				end
				// $3C0006: Set mode
				3'b011 :
				begin
					$display("LSPC set mode to 0x%H", M68K_DATA);	// DEBUG
					AA_SPEED <= M68K_DATA[15:8];
					TIMERINT_MODE <= M68K_DATA[7:5];
					TIMERINT_EN <= M68K_DATA[4];
					AA_DISABLE <= M68K_DATA[3];
					// Todo: is [2:0] registered or NC ?
				end
				// $3C0008: Set timer reload MSB
				3'b100 :
				begin
					$display("LSPC set timer reload MSB to 0x%H", M68K_DATA);	// DEBUG
					TIMERLOAD[31:16] <= M68K_DATA;
				end
				// $3C000A: Set timer reload LSB
				3'b101 :
				begin
					$display("LSPC set timer reload LSB to 0x%H", M68K_DATA);	// DEBUG
					TIMERLOAD[15:0] <= M68K_DATA;
					if (TIMERINT_MODE[0]) TIMER <= TIMERLOAD;		// Relative mode
				end
				// $3C000C: Interrupt ack
				3'b110 :
				begin
					$display("LSPC ack interrupt 0x%H", M68K_DATA[2:0]);	// DEBUG
					// Done in combi. logic above
				end
				// $3C000E: Timer fix for PAL mode
				3'b111 :
				begin
					$display("LSPC set timer stop (PAL) to %B", M68K_DATA[0]);	// DEBUG
					TIMERSTOP <= M68K_DATA[0];
				end
			endcase
		end
	end

endmodule

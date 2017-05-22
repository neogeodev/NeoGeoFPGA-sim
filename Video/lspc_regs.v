`timescale 1ns/1ns

module lspc_regs(
	input nRESET,
	input CLK_24M,
	
	input [3:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	
	input nLSPOE,
	input nLSPWE,
	
	input PCK1,
	
	input [2:0] AA_COUNT,
	input [7:0] V_COUNT,
	input VIDEO_MODE,
	
	output [15:0] REG_LSPCMODE,
	
	output reg CPU_VRAM_ZONE,
	output CPU_WRITE_REQ,
	output reg [14:0] CPU_VRAM_ADDR,
	output reg [15:0] CPU_VRAM_WRITE_BUFFER,
	output RELOAD_REQ_SLOW,
	output RELOAD_REQ_FAST,
	
	output reg [31:0] TIMER_LOAD,		// Timer reload value
	output reg TIMER_PAL_STOP,			// Timer pause in top and bottom of display in PAL mode (LSPC2)
	output reg [15:0] REG_VRAMMOD,
	output reg [2:0] TIMER_MODE,		// Timer mode
	output reg TIMER_IRQ_EN,			// Timer interrupt enable
	output reg [7:0] AA_SPEED,			// Auto-animation speed
	output reg AA_DISABLE,				// Auto-animation disable
	
	output reg IRQ_S1, IRQ_R1, IRQ_S2, IRQ_R2, IRQ_R3
);
	
	// Read
	// Todo: See if 3'b000 is right (3'b111 ?)
	assign REG_LSPCMODE = {V_COUNT, 3'b000, VIDEO_MODE, AA_COUNT};
	
	assign CPU_WRITE_REQ = ((M68K_ADDR[3:1] == 3'b001) && (!nLSPWE)) ? 1'b1 : 1'b0;
	
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
	
	assign RELOAD_REQ_SLOW = ((M68K_ADDR[3:1] == 3'b000) && !nLSPWE) ? ~M68K_DATA[15] : 1'b0;
	assign RELOAD_REQ_FAST = ((M68K_ADDR[3:1] == 3'b000) && !nLSPWE) ? M68K_DATA[15] : 1'b0;
	
	always @(posedge CLK_24M or negedge nRESET)	// Is this really synchronous ?
	begin
		if (!nRESET)
		begin
			// Something ?
		end
		else
		begin
			if (!nLSPWE)
			begin
				case (M68K_ADDR[3:1])
					// $3C0000: Set address
					3'b000 :
					begin
						// Read happens as soon as address is set (CPU access slot defaults to "read" all the time ?)
						//$display("VRAM set address to 0x%H", M68K_DATA);	// DEBUG
						{CPU_VRAM_ZONE, CPU_VRAM_ADDR} <= M68K_DATA;
					end
					// $3C0002: Write data
					3'b001 :
					begin
						//$display("VRAM write data 0x%H @ 0x%H", M68K_DATA, {CPU_VRAM_ZONE, CPU_VRAM_ADDR});	// DEBUG
						CPU_VRAM_WRITE_BUFFER <= M68K_DATA;
						//CPU_VRAM_ADDRESS_BUFFER <= CPU_VRAM_ADDR;
						//CPU_VRAM_ADDR <= CPU_VRAM_ADDR + REG_VRAMMOD[14:0];	// Todo: Wrong, sign is used and addr MSB is kept
						//CPU_WRITE <= 1'b1;		// Operation: write
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
						$display("LSPC set timer mode to %b, timer irq to %b, AA disable to %b, AA speed to 0x%H",
									M68K_DATA[7:5], M68K_DATA[4], M68K_DATA[3], M68K_DATA[15:8]);	// DEBUG
						AA_SPEED <= M68K_DATA[15:8];
						TIMER_MODE <= M68K_DATA[7:5];
						TIMER_IRQ_EN <= M68K_DATA[4];
						AA_DISABLE <= M68K_DATA[3];
						// Todo: is [2:0] registered or NC ?
					end
					// $3C0008: Set timer reload MSB
					3'b100 :
					begin
						$display("LSPC set timer reload MSB to 0x%H", M68K_DATA);	// DEBUG
						TIMER_LOAD[31:16] <= M68K_DATA;
					end
					// $3C000A: Set timer reload LSB
					3'b101 :
					begin
						$display("LSPC set timer reload LSB to 0x%H", M68K_DATA);	// DEBUG
						TIMER_LOAD[15:0] <= M68K_DATA;
						if (TIMER_MODE[0])
						begin
							$display("LSPC reloaded timer to 0x%H", {TIMER_LOAD[31:16], M68K_DATA});		// DEBUG
							//TIMER <= {TIMER_LOAD[31:16], M68K_DATA};		// Relative mode
						end
					end
					// $3C000C: Interrupt ack
					3'b110 :
					begin
						$display("LSPC ack interrupt %d", M68K_DATA[2:0]);	// DEBUG
						// Done in combi. logic above
					end
					// $3C000E: Timer fix for PAL mode
					3'b111 :
					begin
						$display("LSPC set timer stop for PAL mode to %B", M68K_DATA[0]);	// DEBUG
						TIMER_PAL_STOP <= M68K_DATA[0];
					end
				endcase
			end
		end
	end

endmodule

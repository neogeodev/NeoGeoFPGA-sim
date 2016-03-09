`timescale 1ns/1ns

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
	wire [3:0] CYCLE_PCK;	// Neg
	reg [3:0] CYCLE_LOAD;	// Pos
	
	reg [23:16] PBUS_U;		// inout
	reg [15:0] PBUS_L;		// out
	
	assign nCLK_24M = ~CLK_24M;
	
	assign PBUS = {PBUS_U, PBUS_L};
	
	assign PCK2 = ~|{CYCLE_PCK[3:0]};							// 0
	assign PCK1 = (CYCLE_PCK[3:0] == 4'b1000) ? 1 : 0;		// 8
	assign LOAD = CYCLE_LOAD[2] & CYCLE_LOAD[1];				// 6-7 14-15
	
	// 28px backporch
	
	/*
	Guess work:
	Logical order of things to render 8 fix pixels:
	
	             v                               v                               v
	             00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF
	MCLK:        .'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'
	Slow VRAM:   |FIXMAP |...    |...    |...    |FIXMAP |...    |...    |...    |FIXMAP |...    |...    |...
	Read VRAM:   ______||______??______??______??______||______??______??______??______||______??______??______??
	P bus:             ###-----------FP                ###-----------FP                ###-----------FP
	Latch:       ________|_______________________________|_______________________________|_______________________
	S2H1 change: ________|_______________|_______________|_______________|_______________|_______________|_______
	                     '-----------,                   '-----------,                   '-----------,
	B1 latch:    ____|_______________|_______________|_______________|_______________|_______________|___________
	(B1 latch is >> by mclk/2 ?)
	
	Set low VRAM address in fix map
		(min 3mclk)
		Read low VRAM data to get tile #							Get fix palette #
		Make fix ROM address from fix tile #
			Put fix ROM address on P bus							!
				(delay 1mclk)											( 7mclk ) -> fix pal in B1
				Latch address in 273 with PCK2 (negedge)
					(min 5mclk, probably 6)
					Read fix ROM data to get 2 pixels
					Latch data in B1 (tile # and palette) with S1H1
		ASYNC:(Switch pixel pair with S2H1
					(min 5mclk, probably 6)
					Read fix ROM data to get 2 pixels
					Latch data in B1 (tile # and palette) with S1H1)
	
	3+1+6+6 = 16 / 16 :)
	P bus fix tile to B1 =	min. 6, probably 7
	P bus fix pal to B1 =	7
	
	S ROM read: 3MHz (333.3ns), since 2 pixels per byte
	Bootleg ROM is 200ns, so at least 5 mclk between address set and read. Is it 6 ?
	
                    Prefetch...     Active display...
					                     v
	24M          6 7 8 9 A B C D E F 0 1 2 3 4 5 6 7 8 9 A B C D E F 0 1 2 3 4 5 6 7 8 9 A B C D E F
	
	On screen:
	Tile idx                      ...|                               0                               |
	FixRom addr                   ...|       16      |       24      |       0       |       8       |
	
	Realtime:
	Tile idx         |                               0                               |               1
	Half             |               0               |
	FixRom addr      |       16      |       24      |       0       |       8       ...
	
	HCOUNT ?         |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |   8   |   9   |
	Pixel#           |  -2   |  -1   |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |
	6MB              |___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''| (posedge)
	6M               |'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|
	S1H1(B1LATCH)    ____________|'''''''''''''''|_______________|'''''''''''''''|___________________| (posedge)
	FIXD             ////////////    ////////////    ////////////    ////////////    ////////////
	S2H1(ADDR)       |       0       |       1       |       0       |       1       |       0       |
	PCK2             |_____________|'|_____________________________|'|_____________________________|'| (negedge)
	FIXADDR                      |||||||                         |||||||
                    ?               ?               ?               ?               ?               ?
	
	If HCOUNT=0 on active display start:
		S2H1 = HCOUNT[1]; (ok)
		S1H1 = div2 from negedge of 6M ?
	*/
	
	assign CYCLE_PCK = CYCLE_P[4:1];
	
	always @(posedge CLK_24M or posedge nCLK_24M)
	begin
		if (HSYNC)
		begin
			CYCLE_P <= 0;
			CYCLE_LOAD <= 0;
		end
		else
		begin
			CYCLE_P <= CYCLE_P + 1;
			if (CLK_24M)
				CYCLE_LOAD <= CYCLE_LOAD + 1;		// Pos
			//else
			//	CYCLE_PCK <= CYCLE_PCK + 1;		// Neg
			
			// Can nVCS be assigned from CYCLE_L instead ?
			if (CYCLE_LOAD == 9) nVCS <= 1'b0;
			if (CYCLE_LOAD == 14) nVCS <= 1'b1;
			
			case (CYCLE_P)
				31, 0, 1 :
				begin
					// FIXT
					PBUS_L <= {FIX_ADDR[4], FIX_ADDR[2:0], FIX_ADDR[16:5]};
					PBUS_U <= 8'b00000000;			// z?
					//S2H1 <= FIX_ADDR[3];
				end
				2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12:
				begin
					// FF0000
					PBUS_L <= 16'b0000000000000000;
					PBUS_U <= 8'b11111111;			// Probably z
				end
				13, 14:
				begin
					// FP
					PBUS_L <= 16'b0000000000000000;
					PBUS_U <= {4'b0000, FIX_PAL};
				end
				15, 16, 17:
				begin
					// SPRT
					PBUS_L <= SPR_ADDR[20:5];
					PBUS_U <= {SPR_ADDR[24:21], SPR_ADDR[3:0]};
					//CA4 <= SPR_ADDR[4];
				end
				18, 19, 20, 21, 22, 23, 24, 25, 26, 27:
				begin
					// L0
					PBUS_L <= L0_ADDR;
					PBUS_U <= 8'bzzzzzzzz;
				end
				28:
				begin
					// Special case, so probably wrong. Read from L0
					L0_DATA <= PBUS_U;
				end
				39, 30:
				begin
					// SP
					PBUS_L <= {SPR_XPOS, 8'b00000000};
					PBUS_U <= SPR_PAL;
				end
			endcase
		end
	end

endmodule

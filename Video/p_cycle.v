`timescale 1ns/1ns

module p_cycle(
	input nRESET,
	input CLK_24M,
	
	input [15:0] S_ROM_ADDR,
	input [3:0] FIX_PAL,
	input [23:0] C_ROM_ADDR,
	input [7:0] SPR_PAL,
	
	input [7:0] SPR_XPOS,
	input [15:0] L0_ROM_ADDR,
	
	output nVCS,
	output reg [7:0] L0_DATA,
	
	inout [23:0] PBUS		// Isim isn't happy with splitted PBUS inout/output apparently
);

	// L0_DATA might be latched on LOAD posedge

	reg [3:0] P_CYCLE_P;
	reg [3:0] P_CYCLE_N;

	// Time slot sequencing
	always @(posedge CLK_24M)
	begin
		if (!nRESET)
			P_CYCLE_P <= 0;
		else
			P_CYCLE_P <= P_CYCLE_P + 1'b1;
	end
	always @(negedge CLK_24M)
	begin
		if (!nRESET)
			P_CYCLE_N <= 0;
		else
			P_CYCLE_N <= P_CYCLE_N + 1'b1;
	end
	
	// Simplified P bus data, for now
	assign PBUS = ((P_CYCLE_P == 4'd8) || (P_CYCLE_N == 4'd7)) ? {8'bzzzzzzzz, S_ROM_ADDR} :		// FT OK
						((P_CYCLE_P >= 4'd9) && (P_CYCLE_P <= 4'd13)) ? {8'bzzzzzzzz, SPR_XPOS, 8'h00}:	// X OK
						((P_CYCLE_P == 4'd14) || (P_CYCLE_N == 4'd14)) ? {4'h0, FIX_PAL, 16'h0000} :	// FP OK
						((P_CYCLE_P == 4'd0) || (P_CYCLE_N == 4'd15)) ? C_ROM_ADDR :						// ST OK
						((P_CYCLE_P >= 4'd1) && (P_CYCLE_P <= 4'd5)) ? {8'bzzzzzzzz, L0_ROM_ADDR} :	// L0 OK
						((P_CYCLE_P == 4'd6) || (P_CYCLE_N == 4'd6)) ? {SPR_PAL, 16'h0000} :				// SP OK
						24'bxxxxxxxxxxxxxxxxxxxxxxxx;	// Shouldn't happen
						
	assign nVCS = ((P_CYCLE_P >= 4'd1) && (P_CYCLE_P <= 4'd5)) ? 1'b0 : 1'b1;
	
	always @(posedge CLK_24M)
	begin
		/*case (CYCLE_P)
			0: {PBUS_U, PBUS_L} <= C_ADDR_OUT;		// Sprite ROM address - Is CA4 latched here or free-running ?
			3: {PBUS_U, PBUS_L} <= {8'bzzzzzzzz, L0_ROM_ADDR};	// L0 ROM address
			13: {PBUS_U, PBUS_L} <= {SPR_PAL, SPR_XPOS, 8'b00000000};	// Sprite palette and X position
			16: {PBUS_U, PBUS_L} <= {8'bzzzzzzzz, S_ROM_ADDR};	// Fix ROM address - Is S2H1 latched here or free-running ?
			19: {PBUS_U, PBUS_L} <= 24'hFF0000;		// FF0000 ? Maybe PBUS_U is z ?
			29: {PBUS_U, PBUS_L} <= {4'b0000, FIX_PAL, 16'b0000000000000000};	// Fix palette
		endcase*/
	end

endmodule

	/*
	Guess work:
	Logical order of things to render 8 fix pixels:
	
	Todo: 24mclk-P cycle should be inverted !
	
	Todo: Palette RAM is 100ns, which means at least 3mclk between B1 output and 6MB rising edge !
	
	             v                               v                               v
	             00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF00112233445566778899AABBCCDDEEFF
	MCLK:        .'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'.'
	Slow VRAM:   |FIXMAP |...    |...    |...    |FIXMAP |...    |...    |...    |FIXMAP |...    |...    |...
	Read VRAM:   ______||______??______??______??______||______??______??______??______||______??______??______??
	P bus:             ###-----------FP                ###-----------FP                ###-----------FP
	Latch:       ________|_______________________________|_______________________________|_______________________
	Fix addr:            ?               ?               ?               ?               ?               ?
	S2H1 change: ________|_______0_______|_______1_______|_______0_______|_______1_______|_______0_______|_______
	                     '-----------,                   '-----------,                   '-----------,
	B1 latch:    ____|_______________|_______________|_______________|_______________|_______________|___________
	
	6MB          |'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___|'''|___
	Pixel out:   |       |       |       |   0   |   1   |   2   |   3   |   4   |   5   |   6   |   7   |       
	
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

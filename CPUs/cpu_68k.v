`timescale 1ns/1ns

module cpu_68k(
	input CLK_68KCLK,
	input nRESET,
	input IPL1, IPL0,
	output [23:1] M68K_ADDR,
	output [15:0] M68K_DATA,
	output nLDS, nUDS,
	output nAS,
	output M68K_RW
);

	reg [31:0] AO68KDATA_IN;
	wire [31:0] AO68KDATA_OUT;
	wire [31:2] AO68KADDR;
	reg [2:0] M68K_ACCESS_CNT;
	reg AO68KDTACK;
	wire [3:0] AO68KSIZE;
	
	// DEBUG, concat for display in ISim only
	wire [23:0] ADDR_BYTE;
	assign ADDR_BYTE = {M68K_ADDR, nUDS};
	
	// Damn Wishbone, longword access adapter...
	always @(negedge CLK_68KCLK)
	begin
		if (nAS)
		begin
			M68K_ACCESS_CNT <= 3'b000;
			AO68KDTACK <= 1'b0;
		end
		else
		begin
			if (&{AO68KSIZE[3:0]})
			begin
				if (!M68K_ACCESS_CNT[2])
				begin
					AO68KDATA_IN[31:16] <= M68K_DATA;
				end
				else
				begin
					if (M68K_ACCESS_CNT[1:0] == 2'b10) AO68KDTACK <= 1'b1;
					if (M68K_ACCESS_CNT[1:0] == 2'b11) AO68KDTACK <= 1'b0;	// ?
					AO68KDATA_IN[15:0] <= M68K_DATA;
				end
			end
			else
			begin
				if (M68K_ACCESS_CNT[1:0] == 2'b10) AO68KDTACK <= 1'b1;
				AO68KDATA_IN <= {16'b0, M68K_DATA};
			end
			M68K_ACCESS_CNT <= M68K_ACCESS_CNT + 1'b1;
		end
	end
	
	assign M68K_DATA = (~M68K_RW) ? AO68KDATA_OUT[15:0] : 16'bzzzzzzzzzzzzzzzz;
	
	// 1000: 01 UDS
	// 0100: 01 LDS
	// 0010: 00 UDS
	// 0001: 00 LDS
	// 1100: 01 UDS+LDS
	// 0011: 00 UDS+LDS
	// 1111: 00 ???
	assign nUDS = ~(AO68KSIZE[3] | AO68KSIZE[1]);
	assign nLDS = ~(AO68KSIZE[2] | AO68KSIZE[0]);
	
	assign M68K_ADDR = (&{AO68KSIZE[3:0]}) ? {AO68KADDR[23:2], M68K_ACCESS_CNT[2]} : {AO68KADDR[23:2], &{AO68KSIZE[1:0]}};
	
	assign nAS = ~AO68KAS;
	assign M68K_RW = ~AO68KWE;
	
	ao68000 AO68K(
		.CLK_I(CLK_68KCLK),
		.reset_n(nRESET),

		.CYC_O(),						// ?
		.ADR_O(AO68KADDR),
		.DAT_O(AO68KDATA_OUT),
		.DAT_I(AO68KDATA_IN),
		.SEL_O(AO68KSIZE),
		.STB_O(AO68KAS),
		.WE_O(AO68KWE),

		.ACK_I(AO68KDTACK),
		.ERR_I(1'b0),					// See ao68000 doc
		.RTY_I(1'b0),

		// TAG_TYPE: TGC_O
		.SGL_O(),
		.BLK_O(),
		.RMW_O(),

		// TAG_TYPE: TGA_O
		.CTI_O(),
		.BTE_O(),

		// TAG_TYPE: TGC_O
		.fc_o(),

		//****************** OTHER
		/* interrupt acknowlege:
		* ACK_I: interrupt vector on DAT_I[7:0]
		* ERR_I: spurious interrupt
		* RTY_I: autovector
		*/
		.ipl_i({1'b1, IPL1, IPL0}),
		.reset_o(),
		.blocked_o()
	);
	
endmodule

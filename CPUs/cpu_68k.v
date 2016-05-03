`timescale 1ns/1ns

module cpu_68k(
	input CLK_68KCLK,
	input nRESET,
	input IPL1, IPL0,
	input nDTACK,
	output [23:1] M68K_ADDR,
	inout [15:0] M68K_DATA,
	output nLDS, nUDS,
	output nAS,
	output M68K_RW
);

wire [15:0] TG68K_DATAIN;
wire [15:0] TG68K_DATAOUT;
wire [31:0] TG68K_ADDR;
wire [24:0] DEBUG_ADDR;

assign M68K_DATA = M68K_RW ? 16'bzzzzzzzzzzzzzzzz : TG68K_DATAOUT;
assign TG68K_DATAIN = M68K_RW ? M68K_DATA : 16'bzzzzzzzzzzzzzzzz;

assign M68K_ADDR = TG68K_ADDR[23:1];

assign DEBUG_ADDR = {M68K_ADDR, 1'b0};

tg68 TG68K(
		.clk(CLK_68KCLK),
		.reset(nRESET),
		.clkena_in(1'b1),
		.data_in(TG68K_DATAIN),
		.IPL(3'b111),
		.dtack(nDTACK),
		.addr(TG68K_ADDR),
		.data_out(TG68K_DATAOUT),
		.as(nAS),
		.uds(nUDS),
		.lds(nLDS),
		.rw(M68K_RW)
		);

/*	reg [31:0] AO68KDATA_IN;
	wire [31:0] AO68KDATA_OUT;
	wire [31:2] AO68KADDR;
	
	reg [1:0] M68K_ACCESS_DELAY;
	reg M68K_ACCESS_NWORD;
	
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
			M68K_ACCESS_DELAY <= 2'b00;
			AO68KDTACK <= 1'b0;
			M68K_ACCESS_NWORD <= 1'b0;
		end
		else
		begin
			if (AO68KDTACK)
			begin
				AO68KDTACK <= 1'b0;
				M68K_ACCESS_NWORD <= 1'b0;
			end
			if (&{AO68KSIZE[3:0]})			// Longword
			begin
				if (M68K_ACCESS_DELAY == 2'b10)
				begin
					if (!M68K_ACCESS_NWORD)
					begin
						AO68KDATA_IN[31:16] <= M68K_DATA;
						M68K_ACCESS_NWORD <= 1'b1;
					end
					else
					begin					
						AO68KDATA_IN[15:0] <= M68K_DATA;
						AO68KDTACK <= 1'b1;
					end
					M68K_ACCESS_DELAY <= 2'b00;
				end
				else
					M68K_ACCESS_DELAY <= M68K_ACCESS_DELAY + 1'b1;
			end
			if (AO68KSIZE == 4'b0011)			// Word
			begin
				if (M68K_ACCESS_DELAY == 2'b10)
				begin
					AO68KDATA_IN[31:16] <= 16'b0000000000000000;
					AO68KDATA_IN[15:0] <= M68K_DATA;
					AO68KDTACK <= 1'b1;
					M68K_ACCESS_DELAY <= 2'b00;
				end
				else
					M68K_ACCESS_DELAY <= M68K_ACCESS_DELAY + 1'b1;
			end
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
	
	assign M68K_ADDR = (&{AO68KSIZE[3:0]}) ? {AO68KADDR[23:2], M68K_ACCESS_NWORD} : {AO68KADDR[23:2], &{AO68KSIZE[1:0]}};
	
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
		
		// interrupt acknowlege:
		// ACK_I: interrupt vector on DAT_I[7:0]
		// ERR_I: spurious interrupt
		// RTY_I: autovector
		.ipl_i(3'b000),	// {1'b1, IPL1, IPL0} DEBUG
		.reset_o(),
		.blocked_o()
	);*/
	
endmodule

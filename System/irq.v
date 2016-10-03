`timescale 1ns/1ns

module irq(
	input IRQ_S1, IRQ_R1,
	input IRQ_S2, IRQ_R2,
	input IRQ_S3, IRQ_R3,
	output IPL0, IPL1
);

	reg Q1, Q2, Q3;

	/*
	// SR latch 1
	assign IRQ_S1_PRIO = IRQ_S1 & ~IRQ_R1;	// Reset has priority over set ?
	assign Q1N = ~|{IRQ_S1_PRIO, Q1};
	assign Q1 = ~|{IRQ_R1, Q1N};
	
	// SR latch 2
	assign IRQ_S2_PRIO = IRQ_S2 & ~IRQ_R2;	// Reset has priority over set ?
	assign Q2N = ~|{IRQ_S2_PRIO, Q2};
	assign Q2 = ~|{IRQ_R2, Q2N};
	
	// SR latch 3
	assign IRQ_S3_PRIO = IRQ_S3 & ~IRQ_R3;	// Reset has priority over set ?
	assign Q3N = ~|{IRQ_S3_PRIO, Q3};
	assign Q3 = ~|{IRQ_R3, Q3N};
	*/
	
	always @(posedge IRQ_S1 or posedge IRQ_R1)
	begin
		if (IRQ_R1)
			Q1 <= 1'b0;
		else
			Q1 <= 1'b1;
	end
	
	always @(posedge IRQ_S2 or posedge IRQ_R2)
	begin
		if (IRQ_R2)
			Q2 <= 1'b0;
		else
			Q2 <= 1'b1;
	end
	
	always @(posedge IRQ_S3 or posedge IRQ_R3)
	begin
		if (IRQ_R3)
			Q3 <= 1'b0;
		else
			Q3 <= 1'b1;
	end
	
	// Interrupt priority encoder (is priority right ?)
	// IRQ  IPL
	// xx1:  00 COLDBOOT
	// x10:  01 HBL
	// 100:  10 VBL
	// 000:  11 No interrupt
	assign IPL0 = ~(Q1 | (Q3 & ~Q2));
	assign IPL1 = ~(Q1 | Q2);

endmodule

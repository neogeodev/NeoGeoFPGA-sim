`timescale 1ns/1ns

module irq(
	input [2:0] IRQ,
	output IPL0, IPL1
);

	// VBL, HBL, COLDBOOT
	// Interrupt priority encoder
	// IRQ  IPL
	// xx0:  00
	// x01:  01
	// 011:  10
	// 111:  11
	assign IPL0 = IRQ[0] & (IRQ[2] | ~IRQ[1]);
	assign IPL1 = IRQ[0] & IRQ[1];

endmodule



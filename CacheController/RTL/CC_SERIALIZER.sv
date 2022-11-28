// Copyright (c) 2022 Sungkyunkwan University

module CC_SERIALIZER
(
	input	wire				clk,
	input	wire				rst_n,

	input	wire				fifo_empty_i,
	input	wire				fifo_aempty_i,
	input	wire	[517:0]		fifo_rdata_i,
	output	wire				fifo_rden_o,

    output  wire    [63:0]		rdata_o,
    output  wire            	rlast_o,
    output  wire            	rvalid_o,
    input   wire            	rready_i
);

	// Fill the code here

endmodule

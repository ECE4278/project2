// Copyright (c) 2022 Sungkyunkwan University

module CC_DECODER
(
	input	wire	[31:0]	inct_araddr_i,
	input	wire			inct_arvalid_i,
	output	wire			inct_arready_o,

	input	wire			miss_addr_fifo_afull_i,
	input	wire			miss_req_fifo_afull_i,
	input	wire			hit_flag_fifo_afull_i,
	input	wire			hit_data_fifo_afull_i,

	output	wire	[16:0]	tag_o,
	output	wire	[8:0]	index_o,
	output	wire	[5:0]	offset_o,
	
	output	wire			hs_pulse_o
);

	// Fill the code here

endmodule

module SRAM_DUAL_PORT_ARRAY
(
	input	wire				clk,
	input	wire				rst_n,
	
	input	wire				rden_i,	
	input	wire	[8:0]		raddr_i,
	output	wire	[17:0]		rdata_tag_o,
	output	wire	[511:0]		rdata_data_o,

	input	wire				wren_i,
	input	wire	[8:0]		waddr_i,
	input	wire	[17:0]		wdata_tag_i,
	input	wire	[511:0]		wdata_data_i
);

	reg [17:0]	tag_array[511:0],	rdata_tag;
	reg	[511:0]	data_array[511:0], 	rdata_data;

	always @(posedge clk)
		if (!rst_n) begin
			for(int index = 0; index < 512; index ++)
			begin 
				tag_array[index] <= {18{1'b0}};
			end
		end
		else begin
			if (rden_i) begin
				rdata_tag	<= tag_array[raddr_i];
				rdata_data	<= data_array[raddr_i];
			end
			else begin 
				rdata_tag	<= 'Z;
				rdata_data	<= 'Z;
			end
			
			if (wren_i) begin
				tag_array[waddr_i]	<= wdata_tag_i;
				data_array[waddr_i]	<= wdata_data_i;
			end
		end

	assign rdata_tag_o	= rdata_tag;
	assign rdata_data_o = rdata_data;

endmodule

// Copyright (c) 2022 Sungkyunkwan University

module CC_CFG
(
	input	wire			clk,
	input	wire			rst_n, // _n means active low

	//AMBA APB interface
	input	wire			psel_i,
	input	wire			penable_i,
	input	wire	[11:0]	paddr_i,
	input	wire			pwrite_i,
	input	wire	[31:0]	pwdata_i,
	output	reg				pready_o,
	output	reg		[31:0]	prdata_o,
    output  reg             pslverr_o
);
	reg		[31:0]			rdata;

	always @(posedge clk) begin
		if(!rst_n) begin
			rdata			<= 32'd0;
		end
		else if (psel_i & !penable_i & !pwrite_i) begin
			case (paddr_i)
				'h0: rdata		<= 32'h0001_0101;
				default: rdata	<= 32'd0;
			endcase
		end
	end
	
	assign	pready_o			= 1'b1;
	assign	prdata_o			= rdata;
	assign  pslverr_o           = 1'b0;

endmodule

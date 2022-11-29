`define     IP_VER      32'h000

`define 	  TIMEOUT_DELAY 	10000000

`define     TEST_SIZE    32'h0000_0100
`define     STRIDE       32'h1000_5000

`define     RANDOM_SEED     12123344
`define     TEST_CNT        100

`define		MEM_ADDR_WIDTH	16

module CC_TOP_TB ();
    
    // inject random seed
    initial begin
        $srandom(`RANDOM_SEED);
    end

    bit [31:0]  addr_queue[$];
    bit [31:0]  hit_addr_queue[$];
    bit [63:0]  data_queue[$];
    
    //----------------------------------------------------------
    // clock and reset generation
    //----------------------------------------------------------
    reg                     clk;
    reg                     rst_n;

    //----------------------------------------------------------
    // SRAM wiring
    //----------------------------------------------------------

    wire                    rden;
    wire    [8:0]           raddr;
    wire    [17:0]          rdata_tag;
    wire    [511:0]         rdata_data;

    wire                    wren;
    wire    [8:0]           waddr;
    wire    [17:0]          wdata_tag;
    wire    [511:0]         wdata_data;

    // clock generation
    initial begin
        clk                     = 1'b0;

        forever #10 clk         = !clk;
    end

    // reset generation
    initial begin
        rst_n                   = 1'b0;     // active at time 0

        repeat (3) @(posedge clk);          // after 3 cycles,
        rst_n                   = 1'b1;     // release the resetß
    end

	// timeout
	initial begin
		#`TIMEOUT_DELAY $display("Timeout!");
		$finish;
	end

    // enable waveform dump
    initial begin
        $dumpvars(0, u_DUT);
        $dumpfile("dump.vcd");
    end

    //----------------------------------------------------------
    // Connection between DUT and test modules
    //----------------------------------------------------------
    APB                         apb_if      (.clk(clk));

    INCT_AXI_AR_CH              inct_ar_ch  (.clk(clk));
    INCT_AXI_R_CH               inct_r_ch   (.clk(clk));

    MEM_AXI_AR_CH               #(.ADDR_WIDTH(`MEM_ADDR_WIDTH))
								mem_ar_ch   (.clk(clk));
	wire	[31:`MEM_ADDR_WIDTH]	unused_mem_araddr;
    MEM_AXI_R_CH                mem_r_ch    (.clk(clk));

    CC_TOP  u_DUT (
        .clk                    (clk),
        .rst_n                  (rst_n),

        // APB interface
        .psel_i                 (apb_if.psel),
        .penable_i              (apb_if.penable),
        .paddr_i                (apb_if.paddr[11:0]),
        .pwrite_i               (apb_if.pwrite),
        .pwdata_i               (apb_if.pwdata),
        .pready_o               (apb_if.pready),
        .prdata_o               (apb_if.prdata),
        .pslverr_o              (apb_if.pslverr),

        // AMBA AXI interface between INCT and CC (AR channel)
        .inct_arid_i            (inct_ar_ch.arid),
        .inct_araddr_i          (inct_ar_ch.araddr),
        .inct_arlen_i           (inct_ar_ch.arlen),
        .inct_arsize_i          (inct_ar_ch.arsize),
        .inct_arburst_i         (inct_ar_ch.arburst),
        .inct_arvalid_i         (inct_ar_ch.arvalid),
        .inct_arready_o         (inct_ar_ch.arready),
    
        // AMBA AXI interface between INCT and CC  (R channel)
        .inct_rid_o             (inct_r_ch.rid),
        .inct_rdata_o           (inct_r_ch.rdata),
        .inct_rresp_o           (inct_r_ch.rresp),
        .inct_rlast_o           (inct_r_ch.rlast),
        .inct_rvalid_o          (inct_r_ch.rvalid),
        .inct_rready_i          (inct_r_ch.rready),

        // AMBA AXI interface between memory and CC (AR channel)
        .mem_arid_o             (mem_ar_ch.arid),
        .mem_araddr_o           ({unused_mem_araddr, mem_ar_ch.araddr}),
        .mem_arlen_o            (mem_ar_ch.arlen),
        .mem_arsize_o           (mem_ar_ch.arsize),
        .mem_arburst_o          (mem_ar_ch.arburst),
        .mem_arvalid_o          (mem_ar_ch.arvalid),
        .mem_arready_i          (mem_ar_ch.arready),

        // AMBA AXI interface between memory and CC  (R channel)
        .mem_rid_i              (mem_r_ch.rid),
        .mem_rdata_i            (mem_r_ch.rdata),
        .mem_rresp_i            (mem_r_ch.rresp),
        .mem_rlast_i            (mem_r_ch.rlast),
        .mem_rvalid_i           (mem_r_ch.rvalid),
        .mem_rready_o           (mem_r_ch.rready), 

        // SRAM read port interface
        .rden_o                 (rden),
        .raddr_o                (raddr),
        .rdata_tag_i            (rdata_tag),
        .rdata_data_i           (rdata_data),

        // SRAM write port interface
        .wren_o                 (wren),
        .waddr_o                (waddr),
        .wdata_tag_o            (wdata_tag),
        .wdata_data_o           (wdata_data)
    );

    AXI_SLAVE   				#(
		.ADDR_WIDTH				(`MEM_ADDR_WIDTH)
	) u_mem (
        .clk                    (clk),
        .rst_n                  (rst_n),
        .ar_ch                  (mem_ar_ch),
        .r_ch                   (mem_r_ch)
    );

    SRAM_DUAL_PORT_ARRAY u_sram (
        .clk                    (clk),        
        .rst_n                  (rst_n),        
        .rden_i                 (rden),        
        .raddr_i                (raddr),        
        .rdata_tag_o            (rdata_tag),        
        .rdata_data_o           (rdata_data),        
        .wren_i                 (wren),        
        .waddr_i                (waddr),        
        .wdata_tag_i            (wdata_tag),        
        .wdata_data_i           (wdata_data)             
    );

    //----------------------------------------------------------
    // Testbench starts
    //----------------------------------------------------------
    task test_init();
        int data;
        apb_if.init();
        inct_ar_ch.init();
        inct_r_ch.init();
        @(posedge rst_n); 
        repeat (10) @(posedge clk);

        apb_if.read(`IP_VER, data);
        $display("---------------------------------------------------");
        $display("IP version: %x", data);
        $display("---------------------------------------------------");
    endtask

	// fill the memory with random data
	task mem_fill();
		for (int addr=0; addr<(1<<`MEM_ADDR_WIDTH); addr+=4) begin
            u_mem.write_word(addr, $random);	// write 32b (4B) at a time
		end
	endtask

    task automatic trans_init(int gen_repeat_cnt, int access_repeat_cnt);
        bit [16:0]  tag;
        bit [8:0]   index;
        bit [5:0]   offset;
        bit [31:0]  addr, data_addr, hit_addr;
        bit [63:0]  answer;
        bit [511:0]  data;
        int request_cnt;
        
        $display("Test start =========================================");
        
        request_cnt = 1;
        
		// step 1: cache miss requests
        repeat(gen_repeat_cnt) begin 
            // 1. generate a random address within the range
			addr = $random & {`MEM_ADDR_WIDTH{1'b1}};
			addr[5:0] = 0;		// to simplify, addr starts at a begining of a block
			tag = addr[`MEM_ADDR_WIDTH:15];
			index = addr[14:6];
			offset = addr[5:0];

			// 2. push the address to the address queue
			//    (later, the driver will drive to DUT)
            addr_queue.push_back(addr);

			// 3. push the expected data to the data queue
			//    (a request generates 8 64b data)
            for(int jdx = 0; jdx < 8; jdx++) begin 
                data_addr = addr + ((offset + (jdx << 3)) & 6'b11_1111);
                answer = {u_mem.read_word(data_addr + 4),u_mem.read_word(data_addr)};
                data_queue.push_back(answer);
            end

			// 4. push the address to hit_addr_queue to generate cache hit
			// requests
            hit_addr_queue.push_back(addr);

            $write("%3dth trans || ", request_cnt ++); 
            $write("base address : 0x%08h | ", addr);
            $write("tag : 0x%05h | index : 0x%03h | ", tag, index);
            $write("offset : 0x%02h (%1dth word first)\n", offset, offset >> 3);
        end

		// step 2: cache hit requests
        repeat(gen_repeat_cnt) begin 
			// select one of the pre-requested addresses
            hit_addr = hit_addr_queue.pop_front();
            repeat(access_repeat_cnt / gen_repeat_cnt) begin
                tag = hit_addr[`MEM_ADDR_WIDTH:15];
                index = hit_addr[14:6];
                offset = $random & 32'h0000_0038;
                
                addr_queue.push_back({hit_addr[`MEM_ADDR_WIDTH:6], offset[5:0]});

                for(int jdx = 0; jdx < 8; jdx++) begin 
                    data_addr = hit_addr + ((offset + (jdx << 3)) & 6'b11_1111);
                    answer = {u_mem.read_word(data_addr + 4),u_mem.read_word(data_addr)};
                    data_queue.push_back(answer);
                end

                $write("%3dth trans || ", request_cnt ++); 
                $write("base address : 0x%08h | ", hit_addr);
                $write("tag : 0x%05h | index : 0x%03h | ", tag, index);
                $write("offset : 0x%02h (%1dth word first)\n", offset, offset >> 3);
            end
        end
    endtask

    task drive_ar();
        bit [31:0] addr;
		while (addr_queue.size()!=0) begin
            addr = addr_queue.pop_front();	// pop a request from the queue
            inct_ar_ch.request(addr);		// drive to DUT
        end
    endtask

    task monitor_r();
        bit [63:0] data, answer;
		int req_num = 0; 
        int burst_cur;
        bit last;
		while (data_queue.size()!=0) begin
			req_num++;
            last = 0;
            burst_cur = 0;
            while(!last) begin
                inct_r_ch.receive(data, last);	// receive data from DUT
                answer = data_queue.pop_front();	// pop expected data from the data_queue
                if (answer != data) begin		// compare
                    $write("<< %5dth request [Incorrect] (Burst %1d) : ", req_num, burst_cur);
                    $write("rdata [0x%016h] | answer : [0x%016h] | rlast [%b]\n", data, answer, last);
					@(posedge clk);
					$finish;
                end
                else begin 
                    $write("<< %5dth request [ Correct ] (Burst %1d) : ", req_num, burst_cur);
                    $write("rdata [0x%016h] | answer : [0x%016h] | rlast [%b]\n", data, answer, last);
                end
                burst_cur++;
            end
        end
    endtask

    // main
    initial begin
        int gen_repeat_cnt    = 80;
        int access_repeat_cnt = 800;
        test_init();
		mem_fill();
        trans_init(gen_repeat_cnt, access_repeat_cnt);
        fork
            drive_ar();
            monitor_r();
        join
        $display("Pass the test!");
        $finish;
    end


endmodule
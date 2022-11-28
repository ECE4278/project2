`include "../TB/AXI_TYPEDEF.svh"

interface INCT_AXI_AR_CH
#(
    parameter   ADDR_WIDTH      = `AXI_ADDR_WIDTH,
    parameter   ID_WIDTH        = `AXI_ID_WIDTH
 )
(
    input                       clk
);
    logic                       arvalid;
    logic                       arready;
    logic   [ID_WIDTH-1:0]      arid;
    logic   [ADDR_WIDTH-1:0]    araddr;
    logic   [3:0]               arlen;
    logic   [2:0]               arsize;
    logic   [1:0]               arburst;

    semaphore                   sema;
    initial begin
        sema                    = new(1);
    end

    modport master (
        input           clk,
        input           arready,
        output          arvalid, arid, araddr, arlen, arsize, arburst
    );

    task init();
        arvalid     = 1'b0;
        arid        = {ID_WIDTH{1'b0}};
        araddr      = {ADDR_WIDTH{1'b0}};
        arlen       = 4'd7;
        arsize      = 3'b011;
        arburst     = 2'b10; // WRAP : 'b10
    endtask

    task automatic request(input int addr);
        sema.get(1);
        #1
        arvalid     = 1'b1;
        araddr      = addr;
        @(posedge clk);

        while (arready== 1'b0) begin
            @(posedge clk);
        end

        arvalid     = 1'b0;
        araddr      = 'hX;
        sema.put(1);
    endtask

endinterface

interface INCT_AXI_R_CH
#(
    parameter   DATA_WIDTH      = `AXI_DATA_WIDTH,
    parameter   ID_WIDTH        = `AXI_ID_WIDTH
 )
(
    input                       clk
);
    logic                       rvalid;
    logic                       rready;
    logic   [ID_WIDTH-1:0]      rid;
    logic   [DATA_WIDTH-1:0]    rdata;
    logic   [1:0]               rresp;
    logic                       rlast;

    semaphore                   sema;
    initial begin
        sema                    = new(1);
    end

    modport master (
        input           clk,
        input           rvalid, rid, rdata, rresp, rlast,
        output          rready
    );

    task init();
        rready = 1'b1;
    endtask
    
    task automatic receive(output bit [63:0] data, output int last);
        sema.get(1);
        #1
        rready     = 1'b1;
        @(posedge clk);

        while (rvalid == 1'b0) begin
            @(posedge clk);
        end
        
        data        = rdata;
        last        = rlast;
        rready      = 1'b1;
        sema.put(1);
    endtask

endinterface


interface MEM_AXI_AR_CH
#(
    parameter   ADDR_WIDTH      = `AXI_ADDR_WIDTH,
    parameter   ID_WIDTH        = `AXI_ID_WIDTH
 )
(
    input                       clk
);
    logic                       arvalid;
    logic                       arready;
    logic   [ID_WIDTH-1:0]      arid;
    logic   [ADDR_WIDTH-1:0]    araddr;
    logic   [3:0]               arlen;
    logic   [2:0]               arsize;
    logic   [1:0]               arburst;

endinterface


interface MEM_AXI_R_CH
#(
    parameter   DATA_WIDTH      = `AXI_DATA_WIDTH,
    parameter   ID_WIDTH        = `AXI_ID_WIDTH
 )
(
    input                       clk
);
    logic                       rvalid;
    logic                       rready;
    logic   [ID_WIDTH-1:0]      rid;
    logic   [DATA_WIDTH-1:0]    rdata;
    logic   [1:0]               rresp;
    logic                       rlast;

endinterface


interface APB (
    input                       clk
);
    logic                       psel;
    logic                       penable;
    logic   [31:0]              paddr;
    logic                       pwrite;
    logic   [31:0]              pwdata;
    logic                       pready;
    logic   [31:0]              prdata;
    logic                       pslverr;

    // a semaphore to allow only one access at a time
    semaphore                   sema;
    initial begin
        sema                        = new(1);
    end

    modport master (
        input           clk,
        input           pready, prdata, pslverr,
        output          psel, penable, paddr, pwrite, pwdata
    );

    task init();
        psel                    = 1'b0;
        penable                 = 1'b0;
        paddr                   = 32'd0;
        pwrite                  = 1'b0;
        pwdata                  = 32'd0;
    endtask

    task automatic write(input int addr,
                         input int data);
        // during a write, another threads cannot access APB
        sema.get(1);
        #1
        psel                    = 1'b1;
        penable                 = 1'b0;
        paddr                   = addr;
        pwrite                  = 1'b1;
        pwdata                  = data;
        @(posedge clk);
        #1
        penable                 = 1'b1;
        @(posedge clk);

        while (pready==1'b0) begin
            @(posedge clk);
        end

        psel                    = 1'b0;
        penable                 = 1'b0;
        paddr                   = 'hX;
        pwrite                  = 1'bx;
        pwdata                  = 'hX;

        // release the semaphore
        sema.put(1);
    endtask

    task automatic read(input int addr,
                        output int data);
        // during a read, another threads cannot access APB
        sema.get(1);

        #1
        psel                    = 1'b1;
        penable                 = 1'b0;
        paddr                   = addr;
        pwrite                  = 1'b0;
        pwdata                  = 'hX;
        @(posedge clk);
        #1
        penable                 = 1'b1;
        @(posedge clk);

        while (pready==1'b0) begin
            @(posedge clk);
        end
        data                    = prdata;

        psel                    = 1'b0;
        penable                 = 1'b0;
        paddr                   = 'hX;
        pwrite                  = 1'bx;
        pwdata                  = 'hX;

        // release the semaphore
        sema.put(1);
    endtask

endinterface

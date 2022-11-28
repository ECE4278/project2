// Copyright (c) 2022 Sungkyunkwan University

module CC_FIFO #(
    parameter       FIFO_DEPTH          = 16,
    parameter       DATA_WIDTH          = 32,
    parameter       AFULL_THRESHOLD     = 16,
    parameter       AEMPTY_THRESHOLD    = 0
)
(
    input   wire                        clk,
    input   wire                        rst_n,

    output  wire                        full_o,
    output  wire                        afull_o,
    input   wire                        wren_i,
    input   wire    [DATA_WIDTH-1:0]    wdata_i,

    output  wire                        empty_o,
    output  wire                        aempty_o,
    input   wire                        rden_i,
    output  wire    [DATA_WIDTH-1:0]    rdata_o
);

    localparam  DEPTH_LG2               = $clog2(FIFO_DEPTH);

    reg     [DATA_WIDTH-1:0]            data[FIFO_DEPTH];

    reg                                 full,       full_n,
                                        afull,      afull_n,
                                        empty,      empty_n,
                                        aempty,     aempty_n;
    reg     [DEPTH_LG2:0]               wrptr,      wrptr_n,
                                        rdptr,      rdptr_n;
    reg     [DEPTH_LG2:0]               counter,    counter_n;

    // reset entries to all 0s
    always_ff @(posedge clk)
        if (!rst_n) begin
            full                        <= 1'b0;
            empty                       <= 1'b1;    // empty after as reset

            wrptr                       <= {(DEPTH_LG2+1){1'b0}};
            rdptr                       <= {(DEPTH_LG2+1){1'b0}};

            counter                     <= {(DEPTH_LG2+1){1'b0}};

            for (int i=0; i<FIFO_DEPTH; i++) begin
                data[i]                     <= {DATA_WIDTH{1'b0}};
            end
        end
        else begin
            full                        <= full_n;
            empty                       <= empty_n;

            wrptr                       <= wrptr_n;
            rdptr                       <= rdptr_n;

            counter                     <= counter_n;

            if (wren_i) begin
                data[wrptr[DEPTH_LG2-1:0]]  <= wdata_i;
            end
        end

    always_comb begin
        wrptr_n                     = wrptr;
        rdptr_n                     = rdptr;
        counter_n                   = counter;
        if (wren_i & ~full) begin
            wrptr_n                     = wrptr + 'd1;
            counter_n                   = counter_n + 'd1;
        end

        if (rden_i & ~empty) begin
            rdptr_n                     = rdptr + 'd1;
            counter_n                   = counter_n - 'd1;
        end

        aempty                      = (counter <= AEMPTY_THRESHOLD);
        afull                       = (counter >= AFULL_THRESHOLD);

        empty_n                     = (wrptr_n == rdptr_n);
        full_n                      = (wrptr_n[DEPTH_LG2]!=rdptr_n[DEPTH_LG2])
                                     &(wrptr_n[DEPTH_LG2-1:0]==rdptr_n[DEPTH_LG2-1:0]);
    end

   // synthesis translate_off
   always @(posedge clk) begin
       if (full_o & wren_i) begin
           $display("FIFO overflow");
           @(posedge clk);
           $finish;
       end
   end

   always @(posedge clk) begin
       if (empty_o & rden_i) begin
           $display("FIFO underflow");
           @(posedge clk);
           $finish;
       end
   end
   // synthesis translate_on

    assign  full_o                      = full;
    assign  afull_o                     = afull;
    assign  empty_o                     = empty;
    assign  aempty_o                    = aempty;
    assign  rdata_o                     = data[rdptr[DEPTH_LG2-1:0]];

endmodule

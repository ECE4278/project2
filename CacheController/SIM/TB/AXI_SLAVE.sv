`include "../TB/AXI_TYPEDEF.svh"

module AXI_SLAVE
#(
    parameter ADDR_WIDTH        = `AXI_ADDR_WIDTH,
    parameter ADDR_OFFSET       = `AXI_ADDR_OFFSET,
    parameter DATA_WIDTH        = `AXI_DATA_WIDTH,
    parameter ID_WIDTH          = `AXI_ID_WIDTH,
    parameter AWREADY_DELAY     = 1,
    parameter ARREADY_DELAY     = 1,
    parameter AR2R_DELAY        = 50
)
(
    input   wire                clk,
    input   wire                rst_n,  // _n means active low

    MEM_AXI_AR_CH               ar_ch,
    MEM_AXI_R_CH                r_ch
);

    localparam  DATA_DEPTH      = {(ADDR_WIDTH - 2){1'b1}};
    logic   [31:0]                 mem[DATA_DEPTH];

    function void write_word(int addr, input bit [31:0] wdata);
        mem[addr >> 2]               = wdata;
    endfunction

    function bit [31:0] read_word(int addr);
        read_word               = mem[addr >> 2];
    endfunction

    //----------------------------------------------------------
    // read channel (AR, R)
    //----------------------------------------------------------
    localparam logic [1:0]      S_R_IDLE = 0,
                                S_R_ARREADY = 1,
                                S_R_DELAY = 2,
                                S_R_BURST = 3;
    localparam logic [1:0]      FIXED    = 0,
                                INCR     = 1,
                                WRAP     = 2;

    logic   [1:0]               rstate,             rstate_n;
    logic   [7:0]               rcnt,               rcnt_n;

    logic   [ADDR_WIDTH-1:0]    raddr_base,         raddr_base_n;
    logic   [ADDR_OFFSET:0]     raddr_offset,       raddr_offset_n;
    logic   [ID_WIDTH-1:0]      rid,                rid_n;
    logic   [3:0]               rlen,               rlen_n;

    always_ff @(posedge clk)
        if (!rst_n) begin
            rstate              <= S_R_IDLE;

            rcnt                <= 8'd0;
            raddr_base          <= {ADDR_WIDTH{1'b0}};
            raddr_offset        <= {(ADDR_OFFSET+1){1'b0}};
            rid                 <= {ID_WIDTH{1'b0}};
            rlen                <= 4'd0;
        end
        else begin
            rstate              <= rstate_n;
            rcnt                <= rcnt_n;
            raddr_base          <= raddr_base_n;
            raddr_offset        <= raddr_offset_n;
            rid                 <= rid_n;
            rlen                <= rlen_n;
        end

    always_comb begin
        rstate_n                = rstate;

        rcnt_n                  = rcnt;
        raddr_base_n            = raddr_base  ;
        raddr_offset_n          = raddr_offset;
        rid_n                   = rid;
        rlen_n                  = rlen;

        ar_ch.arready           = 1'b0;
        r_ch.rvalid             = 1'b0;
        r_ch.rlast              = 1'b0;

        case (rstate)
            S_R_IDLE: begin
                if (ar_ch.arvalid) begin
                    if (ARREADY_DELAY == 0) begin
                        raddr_base_n            = ar_ch.araddr & 32'hffff_ffc0;
                        raddr_offset_n          = ar_ch.araddr & 32'h0000_003f;
                        rid_n                   = ar_ch.arid;
                        rlen_n                  = ar_ch.arlen;
                        ar_ch.arready           = 1'b1;

                        rcnt_n                  = AR2R_DELAY - 1;
                        rstate_n                = S_R_DELAY;
                    end
                    else begin
                        rcnt_n                  = ARREADY_DELAY-1;
                        rstate_n                = S_R_ARREADY;
                    end
                end
            end
            S_R_ARREADY: begin
                if (rcnt==0) begin
                    raddr_base_n            = ar_ch.araddr & 32'hffff_ffc0;
                    raddr_offset_n          = ar_ch.araddr & 32'h0000_003f;
                    rid_n                   = ar_ch.arid;
                    rlen_n                  = ar_ch.arlen;
                    ar_ch.arready           = 1'b1;

                    rcnt_n                  = AR2R_DELAY - 1;
                    rstate_n                = S_R_DELAY;
                end
                else begin
                    rcnt_n                  = rcnt - 8'd1;
                end
            end
            S_R_DELAY: begin
                if (rcnt==0) begin
                    rstate_n                = S_R_BURST;
                end
                else begin
                    rcnt_n                  = rcnt - 8'd1;
                end
            end
            S_R_BURST: begin
                r_ch.rvalid             = 1'b1;
                r_ch.rlast              = (rlen==4'd0); 
                r_ch.rdata[31:0]        = read_word(raddr_base + raddr_offset);
                r_ch.rdata[63:32]       = read_word(raddr_base + raddr_offset + 4);
                if (r_ch.rready) begin
                    case (ar_ch.arburst)
                        FIXED: begin 
                            raddr_offset_n  = raddr_offset;
                        end
                        INCR: begin
                            raddr_offset_n  = raddr_offset + (DATA_WIDTH/8); 
                        end
                        WRAP: begin 
                            raddr_offset_n  = (raddr_offset + (DATA_WIDTH/8));
                            raddr_offset_n  = raddr_offset_n & {ADDR_OFFSET{1'b1}};
                        end
                        default:
                            raddr_offset_n     = raddr_offset;
                    endcase
                    if (rlen==4'd0) begin
                        rstate_n                = S_R_IDLE;
                    end
                    else begin
                        rlen_n              = rlen - 4'd1;
                    end
                end
            end
        endcase
    end

    // output assignments
    assign  r_ch.rid            = rid;
    assign  r_ch.rresp          = 2'd0;

endmodule

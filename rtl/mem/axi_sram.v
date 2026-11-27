// =============================================================================
// Module      : axi_sram.v
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Parameterizable full AXI4 on-chip SRAM slave (default 64 KB
//               at 0x0000_0000 - 0x0000_FFFF). Supports independent read and
//               write channels, byte-level WSTRB write enables, and FIXED /
//               INCR / WRAP bursts up to 256 beats.
// =============================================================================
`timescale 1ns / 1ps
`default_nettype none

module axi_sram #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 16,               // 16 bits -> 64 KB address space
    parameter STRB_WIDTH = (DATA_WIDTH / 8),
    parameter ID_WIDTH   = 8
)(
    input  wire                    aclk,
    input  wire                    aresetn,

    // Write Address Channel
    input  wire [ID_WIDTH-1:0]     s_axi_awid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire [7:0]              s_axi_awlen,
    input  wire [2:0]              s_axi_awsize,
    input  wire [1:0]              s_axi_awburst,
    input  wire                    s_axi_awlock,
    input  wire [3:0]              s_axi_awcache,
    input  wire [2:0]              s_axi_awprot,
    input  wire [3:0]              s_axi_awqos,
    input  wire [3:0]              s_axi_awregion,
    input  wire                    s_axi_awvalid,
    output reg                     s_axi_awready,

    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [STRB_WIDTH-1:0]   s_axi_wstrb,
    input  wire                    s_axi_wlast,
    input  wire                    s_axi_wvalid,
    output reg                     s_axi_wready,

    // Write Response Channel
    output reg  [ID_WIDTH-1:0]     s_axi_bid,
    output reg  [1:0]              s_axi_bresp,
    output reg                     s_axi_bvalid,
    input  wire                    s_axi_bready,

    // Read Address Channel
    input  wire [ID_WIDTH-1:0]     s_axi_arid,
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire [7:0]              s_axi_arlen,
    input  wire [2:0]              s_axi_arsize,
    input  wire [1:0]              s_axi_arburst,
    input  wire                    s_axi_arlock,
    input  wire [3:0]              s_axi_arcache,
    input  wire [2:0]              s_axi_arprot,
    input  wire [3:0]              s_axi_arqos,
    input  wire [3:0]              s_axi_arregion,
    input  wire                    s_axi_arvalid,
    output reg                     s_axi_arready,

    // Read Data Channel
    output reg  [ID_WIDTH-1:0]     s_axi_rid,
    output reg  [DATA_WIDTH-1:0]   s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                     s_axi_rlast,
    output reg                     s_axi_rvalid,
    input  wire                    s_axi_rready
);

    localparam WORD_ADDR_LSB = $clog2(STRB_WIDTH);          // 2 for 32-bit
    localparam MEM_WORDS     = (1 << (ADDR_WIDTH - WORD_ADDR_LSB));

    // Memory array (initialized to zero for deterministic simulation)
    reg [DATA_WIDTH-1:0] mem [0:MEM_WORDS-1];

    integer init_idx;
    initial begin
        for (init_idx = 0; init_idx < MEM_WORDS; init_idx = init_idx + 1) begin
            mem[init_idx] = {DATA_WIDTH{1'b0}};
        end
    end

    // Compute next AXI beat byte address for FIXED (00), INCR (01), WRAP (10)
    function [ADDR_WIDTH-1:0] calc_next_addr;
        input [ADDR_WIDTH-1:0] cur_addr;
        input [2:0]            axsize;
        input [1:0]            axburst;
        input [7:0]            axlen;
        reg   [ADDR_WIDTH-1:0] beat_bytes;
        reg   [ADDR_WIDTH-1:0] aligned_addr;
        reg   [ADDR_WIDTH-1:0] wrap_mask;
        begin
            beat_bytes   = ({{(ADDR_WIDTH-1){1'b0}}, 1'b1} << axsize);
            aligned_addr = cur_addr & ~(beat_bytes - {{(ADDR_WIDTH-1){1'b0}}, 1'b1});
            case (axburst)
                2'b00:   calc_next_addr = cur_addr; // FIXED
                2'b10: begin // WRAP
                    wrap_mask = (({{(ADDR_WIDTH-8){1'b0}}, axlen} + {{(ADDR_WIDTH-1){1'b0}}, 1'b1}) << axsize)
                                - {{(ADDR_WIDTH-1){1'b0}}, 1'b1};
                    calc_next_addr = (cur_addr & ~wrap_mask) | ((aligned_addr + beat_bytes) & wrap_mask);
                end
                default: calc_next_addr = aligned_addr + beat_bytes; // INCR
            endcase
        end
    endfunction

    // =========================================================================
    // AXI4 Write Channel FSM
    // =========================================================================
    localparam [1:0]
        WR_IDLE = 2'd0,
        WR_DATA = 2'd1,
        WR_RESP = 2'd2;

    reg [1:0]            wr_state;
    reg [ID_WIDTH-1:0]   wr_id_r;
    reg [ADDR_WIDTH-1:0] wr_addr_r;
    reg [7:0]            wr_len_r;
    reg [7:0]            wr_rem_r;
    reg [2:0]            wr_size_r;
    reg [1:0]            wr_burst_r;

    integer byte_idx;
    wire [ADDR_WIDTH-WORD_ADDR_LSB-1:0] wr_word_idx = wr_addr_r[ADDR_WIDTH-1:WORD_ADDR_LSB];

    always @(posedge aclk) begin
        if (!aresetn) begin
            wr_state      <= WR_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bid     <= {ID_WIDTH{1'b0}};
            s_axi_bresp   <= 2'b00;
            s_axi_bvalid  <= 1'b0;
            wr_id_r       <= {ID_WIDTH{1'b0}};
            wr_addr_r     <= {ADDR_WIDTH{1'b0}};
            wr_len_r      <= 8'd0;
            wr_rem_r      <= 8'd0;
            wr_size_r     <= 3'd2;
            wr_burst_r    <= 2'b01;
        end else begin
            case (wr_state)
                WR_IDLE: begin
                    s_axi_bvalid <= 1'b0;
                    s_axi_wready <= 1'b0;
                    if (s_axi_awvalid && s_axi_awready) begin
                        s_axi_awready <= 1'b0;
                        s_axi_wready  <= 1'b1;
                        wr_id_r       <= s_axi_awid;
                        wr_addr_r     <= s_axi_awaddr;
                        wr_len_r      <= s_axi_awlen;
                        wr_rem_r      <= s_axi_awlen;
                        wr_size_r     <= s_axi_awsize;
                        wr_burst_r    <= s_axi_awburst;
                        wr_state      <= WR_DATA;
                    end else begin
                        s_axi_awready <= 1'b1;
                    end
                end

                WR_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        for (byte_idx = 0; byte_idx < STRB_WIDTH; byte_idx = byte_idx + 1) begin
                            if (s_axi_wstrb[byte_idx]) begin
                                mem[wr_word_idx][byte_idx*8 +: 8] <= s_axi_wdata[byte_idx*8 +: 8];
                            end
                        end

                        if (s_axi_wlast || (wr_rem_r == 8'd0)) begin
                            s_axi_wready <= 1'b0;
                            s_axi_bid    <= wr_id_r;
                            s_axi_bresp  <= 2'b00; // OKAY
                            s_axi_bvalid <= 1'b1;
                            wr_state     <= WR_RESP;
                        end else begin
                            wr_addr_r <= calc_next_addr(wr_addr_r, wr_size_r, wr_burst_r, wr_len_r);
                            wr_rem_r  <= wr_rem_r - 8'd1;
                        end
                    end
                end

                WR_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid  <= 1'b0;
                        s_axi_awready <= 1'b1;
                        wr_state      <= WR_IDLE;
                    end
                end

                default: begin
                    wr_state      <= WR_IDLE;
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b0;
                    s_axi_bvalid  <= 1'b0;
                end
            endcase
        end
    end

    // =========================================================================
    // AXI4 Read Channel FSM
    // =========================================================================
    localparam [0:0]
        RD_IDLE = 1'd0,
        RD_DATA = 1'd1;

    reg                  rd_state;
    reg [ID_WIDTH-1:0]   rd_id_r;
    reg [ADDR_WIDTH-1:0] rd_addr_r;
    reg [7:0]            rd_len_r;
    reg [7:0]            rd_rem_r;
    reg [2:0]            rd_size_r;
    reg [1:0]            rd_burst_r;

    wire [ADDR_WIDTH-1:0] rd_next_addr =
        calc_next_addr(rd_addr_r, rd_size_r, rd_burst_r, rd_len_r);

    always @(posedge aclk) begin
        if (!aresetn) begin
            rd_state      <= RD_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rid     <= {ID_WIDTH{1'b0}};
            s_axi_rdata   <= {DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rlast   <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            rd_id_r       <= {ID_WIDTH{1'b0}};
            rd_addr_r     <= {ADDR_WIDTH{1'b0}};
            rd_len_r      <= 8'd0;
            rd_rem_r      <= 8'd0;
            rd_size_r     <= 3'd2;
            rd_burst_r    <= 2'b01;
        end else begin
            case (rd_state)
                RD_IDLE: begin
                    s_axi_rvalid <= 1'b0;
                    s_axi_rlast  <= 1'b0;
                    if (s_axi_arvalid && s_axi_arready) begin
                        s_axi_arready <= 1'b0;
                        rd_id_r       <= s_axi_arid;
                        rd_addr_r     <= s_axi_araddr;
                        rd_len_r      <= s_axi_arlen;
                        rd_rem_r      <= s_axi_arlen;
                        rd_size_r     <= s_axi_arsize;
                        rd_burst_r    <= s_axi_arburst;
                        s_axi_rid     <= s_axi_arid;
                        s_axi_rdata   <= mem[s_axi_araddr[ADDR_WIDTH-1:WORD_ADDR_LSB]];
                        s_axi_rresp   <= 2'b00; // OKAY
                        s_axi_rlast   <= (s_axi_arlen == 8'd0);
                        s_axi_rvalid  <= 1'b1;
                        rd_state      <= RD_DATA;
                    end else begin
                        s_axi_arready <= 1'b1;
                    end
                end

                RD_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        if (s_axi_rlast || (rd_rem_r == 8'd0)) begin
                            s_axi_rvalid  <= 1'b0;
                            s_axi_rlast   <= 1'b0;
                            s_axi_arready <= 1'b1;
                            rd_state      <= RD_IDLE;
                        end else begin
                            rd_addr_r    <= rd_next_addr;
                            rd_rem_r     <= rd_rem_r - 8'd1;
                            s_axi_rid    <= rd_id_r;
                            s_axi_rdata  <= mem[rd_next_addr[ADDR_WIDTH-1:WORD_ADDR_LSB]];
                            s_axi_rresp  <= 2'b00; // OKAY
                            s_axi_rlast  <= (rd_rem_r == 8'd1);
                            s_axi_rvalid <= 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule

`default_nettype wire

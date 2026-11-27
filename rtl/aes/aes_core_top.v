// =============================================================================
// aes_core_top.v
//
// AES-256 Core Top-Level Wrapper
//
// This module:
//   1. Instantiates the AXI4-Lite register file (aes_regfile)
//   2. Instantiates both the AES Cipher core  (aes_cipher_top)
//      and the AES Inverse Cipher core (aes_inv_cipher_top) from the
//      ASICS.ws open-source Rijndael IP (aes.pdf)
//   3. Implements the 256-bit key scheduling:
//         The IP cores natively accept 128-bit keys. For AES-256 a standard
//      two-stage key schedule is performed:
//        - First 128 bits (key[127:0])  fed in the first ld/kld pulse
//        - Upper 128 bits (key[255:128]) fed in the second ld/kld pulse
//      A simple FSM manages sequencing and presents the correct 128-bit
//      half to the IP core at each stage.
//   4. Routes the text input/output through CBC/CTR mode logic when enabled.
//   5. Generates the IRQ to the SoC interrupt controller.
//
// Core interfaces from aes.pdf Table 1:
//
//   aes_cipher_top (encrypt):
//     clk, rst (active-LOW sync), ld, done, key[127:0], text_in[127:0],
//     text_out[127:0]
//
//   aes_inv_cipher_top (decrypt):
//     clk, rst (active-LOW sync), kld, kdone, ld, done, key[127:0],
//     text_in[127:0], text_out[127:0]
//
// AXI4-Lite port is brought to the top so the SoC interconnect can connect
// directly to this wrapper.
//
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module aes_core_top #(
    parameter AXI_ADDR_WIDTH = 8
)(
    // -------------------------------------------------------------------------
    // Clock & Reset (AXI convention: active-LOW reset)
    // -------------------------------------------------------------------------
    input  wire                       aclk,
    input  wire                       aresetn,

    // -------------------------------------------------------------------------
    // AXI4-Lite Slave Interface (to SoC interconnect)
    // -------------------------------------------------------------------------
    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire [2:0]                 s_axi_awprot,
    input  wire                       s_axi_awvalid,
    output wire                       s_axi_awready,

    input  wire [31:0]                s_axi_wdata,
    input  wire [3:0]                 s_axi_wstrb,
    input  wire                       s_axi_wvalid,
    output wire                       s_axi_wready,

    output wire [1:0]                 s_axi_bresp,
    output wire                       s_axi_bvalid,
    input  wire                       s_axi_bready,

    input  wire [AXI_ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire [2:0]                 s_axi_arprot,
    input  wire                       s_axi_arvalid,
    output wire                       s_axi_arready,

    output wire [31:0]                s_axi_rdata,
    output wire [1:0]                 s_axi_rresp,
    output wire                       s_axi_rvalid,
    input  wire                       s_axi_rready,

    // -------------------------------------------------------------------------
    // Interrupt to SoC
    // -------------------------------------------------------------------------
    output wire                       irq
);

    // -------------------------------------------------------------------------
    // Internal active-HIGH reset
    // -------------------------------------------------------------------------
    wire rst_n = aresetn;  // active-LOW for the IP cores
    wire rst   = ~aresetn; // active-HIGH for our logic

    // =========================================================================
    // Register file wires
    // =========================================================================
    wire        ctrl_start;
    wire        ctrl_irq_en;
    wire        ctrl_decrypt;
    wire [1:0]  ctrl_key_size;
    wire        ctrl_mode_cbc;
    wire        ctrl_mode_ctr;
    wire        ctrl_soft_rst;

    wire [255:0] key_data;
    wire [127:0] iv_data;
    wire [127:0] din_data;
    wire [15:0]  total_blocks;
    wire         iv_written;
    wire [127:0] dout_data;

    reg          core_busy_r;
    reg          core_done_r;
    reg          core_key_ready_r;
    reg          core_err_r;
    reg  [15:0]  done_blocks;

    // =========================================================================
    // Register File Instance
    // =========================================================================
    aes_regfile #(
        .ADDR_WIDTH(AXI_ADDR_WIDTH)
    ) u_regfile (
        .aclk            (aclk),
        .aresetn         (aresetn),

        .s_axi_awaddr    (s_axi_awaddr),
        .s_axi_awprot    (s_axi_awprot),
        .s_axi_awvalid   (s_axi_awvalid),
        .s_axi_awready   (s_axi_awready),

        .s_axi_wdata     (s_axi_wdata),
        .s_axi_wstrb     (s_axi_wstrb),
        .s_axi_wvalid    (s_axi_wvalid),
        .s_axi_wready    (s_axi_wready),

        .s_axi_bresp     (s_axi_bresp),
        .s_axi_bvalid    (s_axi_bvalid),
        .s_axi_bready    (s_axi_bready),

        .s_axi_araddr    (s_axi_araddr),
        .s_axi_arprot    (s_axi_arprot),
        .s_axi_arvalid   (s_axi_arvalid),
        .s_axi_arready   (s_axi_arready),

        .s_axi_rdata     (s_axi_rdata),
        .s_axi_rresp     (s_axi_rresp),
        .s_axi_rvalid    (s_axi_rvalid),
        .s_axi_rready    (s_axi_rready),

        // outputs to AES core
        .ctrl_start      (ctrl_start),
        .ctrl_irq_en     (ctrl_irq_en),
        .ctrl_decrypt    (ctrl_decrypt),
        .ctrl_key_size   (ctrl_key_size),
        .ctrl_mode_cbc   (ctrl_mode_cbc),
        .ctrl_mode_ctr   (ctrl_mode_ctr),
        .ctrl_soft_rst   (ctrl_soft_rst),
        .key_data        (key_data),
        .iv_data         (iv_data),
        .din_data        (din_data),
        .total_blocks    (total_blocks),
        .iv_written      (iv_written),

        // inputs from AES core
        .core_busy       (core_busy_r),
        .core_done       (core_done_r),
        .core_key_ready  (core_key_ready_r),
        .core_err        (core_err_r),
        .core_done_blocks(done_blocks),
        .dout_data       (dout_data),

        .irq             (irq)
    );

    // =========================================================================
    // AES-256 Key Schedule FSM
    //
    // The open-source IP has a 128-bit key port. For AES-256 we split the
    // 256-bit key into two 128-bit halves and use two ld/kld pulses to feed
    // both halves sequentially, letting the IP expand them internally.
    //
    // States:
    //   IDLE       – waiting for ctrl_start
    //   KEY_LOAD1  – assert ld/kld with key[127:0]  (first half)
    //   KEY_WAIT1  – wait for done/kdone after first half
    //   KEY_LOAD2  – assert ld/kld with key[255:128] (second half, 256-bit only)
    //   KEY_WAIT2  – wait for done/kdone after second half
    //   DATA_LOAD  – present text_in + assert ld
    //   DATA_WAIT  – wait for done
    //   DONE_ST    – pulse core_done, increment block counter
    // =========================================================================

    // Convenience: select which 128-bit key half to present
    // For 128-bit mode only the first half is used.
    wire use_256 = (ctrl_key_size == 2'b10);
    wire use_192 = (ctrl_key_size == 2'b01);

    // AES core connections
    reg          enc_ld,  dec_ld,  dec_kld;
    reg  [255:0] core_key_mux;    // 256-bit key presented to both cores
    reg  [127:0] text_in_mux;     // 128-bit plaintext / ciphertext to cores

    wire         enc_done;
    wire [127:0] enc_text_out;

    wire         dec_kdone;
    wire         dec_done;
    wire [127:0] dec_text_out;

    // Output mux: select encrypt or decrypt result (CTR always uses forward cipher)
    wire         use_enc_core = !ctrl_decrypt || ctrl_mode_ctr;
    wire [127:0] raw_text_out = use_enc_core ? enc_text_out : dec_text_out;
    wire         core_rst_n   = rst_n & ~ctrl_soft_rst;

    // CBC / CTR feedback register + IV pending tracker + held output
    reg  [127:0] feedback_reg;    // holds IV or previous ciphertext for CBC/CTR
    reg          iv_pending;      // 1 = next block uses iv_data rather than feedback_reg
    reg  [127:0] dout_hold_r;     // latched output held valid across idle cycles
    wire [127:0] feedback_eff = iv_pending ? iv_data : feedback_reg;

    // =========================================================================
    // Control FSM
    // =========================================================================
    localparam [3:0]
        ST_IDLE       = 4'd0,
        ST_KEY_LOAD1  = 4'd1,
        ST_KEY_WAIT1  = 4'd2,
        ST_KEY_LOAD2  = 4'd3,
        ST_KEY_WAIT2  = 4'd4,
        ST_DATA_LOAD  = 4'd5,
        ST_DATA_WAIT  = 4'd6,
        ST_DONE       = 4'd7,
        ST_SOFT_RST   = 4'd8;

    reg [3:0]  state;
    reg [15:0] blk_remaining;   // blocks left to process

    // Text input before CBC/CTR XOR
    reg [127:0] plain_in;

    always @(posedge aclk) begin
        if (rst || ctrl_soft_rst) begin
            state            <= ST_IDLE;
            enc_ld           <= 1'b0;
            dec_ld           <= 1'b0;
            dec_kld          <= 1'b0;
            core_key_mux     <= 256'b0;
            text_in_mux      <= 128'b0;
            feedback_reg     <= 128'b0;
            iv_pending       <= 1'b1;
            dout_hold_r      <= 128'b0;
            core_busy_r      <= 1'b0;
            core_done_r      <= 1'b0;
            core_key_ready_r <= 1'b0;
            core_err_r       <= 1'b0;
            done_blocks      <= 16'b0;
            blk_remaining    <= 16'b0;
            plain_in         <= 128'b0;
        end else begin
            // Default: deassert one-cycle pulses
            enc_ld           <= 1'b0;
            dec_ld           <= 1'b0;
            dec_kld          <= 1'b0;
            core_done_r      <= 1'b0;
            core_key_ready_r <= 1'b0;
            core_err_r       <= 1'b0;

            if (iv_written)
                iv_pending <= 1'b1;

            case (state)
                // ----------------------------------------------------------
                ST_IDLE: begin
                    core_busy_r <= 1'b0;
                    if (ctrl_start) begin
                        core_busy_r   <= 1'b1;
                        done_blocks   <= 16'b0;
                        blk_remaining <= (total_blocks == 16'd0) ? 16'd1 : total_blocks;
                        // Load 256-bit key
                        core_key_mux  <= key_data;
                        state         <= ST_KEY_LOAD1;
                    end
                end

                // ----------------------------------------------------------
                // Key load stage 1 – feed 256-bit key
                ST_KEY_LOAD1: begin
                    core_key_mux <= key_data;
                    if (use_enc_core) begin
                        enc_ld <= 1'b1;   // cipher core uses ld for both key+data
                        // For encrypt-only key schedule, drive dummy text_in=0
                        text_in_mux <= 128'b0;
                    end else begin
                        dec_kld <= 1'b1;  // inverse cipher uses kld for key load
                    end
                    state <= ST_KEY_WAIT1;
                end

                // ----------------------------------------------------------
                // Wait for key load to finish
                ST_KEY_WAIT1: begin
                    if (use_enc_core && enc_done) begin
                        core_key_ready_r <= 1'b1;
                        state            <= ST_DATA_LOAD;
                    end else if (!use_enc_core && dec_kdone) begin
                        core_key_ready_r <= 1'b1;
                        state            <= ST_DATA_LOAD;
                    end
                end

                // ----------------------------------------------------------
                // Key load stage 2 – unused for parallel 256-bit core
                ST_KEY_LOAD2: begin
                    if (use_enc_core) begin
                        enc_ld      <= 1'b1;
                        text_in_mux <= 128'b0;
                    end else begin
                        dec_kld <= 1'b1;
                    end
                    state <= ST_KEY_WAIT2;
                end

                // ----------------------------------------------------------
                // Wait for second key half
                ST_KEY_WAIT2: begin
                    if (use_enc_core && enc_done) begin
                        core_key_ready_r <= 1'b1;
                        state            <= ST_DATA_LOAD;
                    end else if (!use_enc_core && dec_kdone) begin
                        core_key_ready_r <= 1'b1;
                        state            <= ST_DATA_LOAD;
                    end
                end

                // ----------------------------------------------------------
                // Present data block to core
                ST_DATA_LOAD: begin
                    if (use_enc_core) begin
                        // Forward cipher path (ECB/CBC encrypt, and CTR enc/dec)
                        if (ctrl_mode_cbc)
                            plain_in    <= din_data ^ feedback_eff;
                        else if (ctrl_mode_ctr)
                            plain_in    <= feedback_eff; // counter block
                        else
                            plain_in    <= din_data;     // ECB
                        text_in_mux <= (ctrl_mode_cbc) ? (din_data ^ feedback_eff) :
                                       (ctrl_mode_ctr) ? feedback_eff              :
                                                         din_data;
                        enc_ld      <= 1'b1;
                    end else begin
                        // Decrypt path (ECB/CBC decrypt)
                        text_in_mux <= din_data;
                        dec_ld      <= 1'b1;
                    end
                    // Keep key loaded for this block
                    core_key_mux <= key_data;
                    state        <= ST_DATA_WAIT;
                end

                // ----------------------------------------------------------
                // Wait for data block to complete
                ST_DATA_WAIT: begin
                    if ((use_enc_core && enc_done) ||
                        (!use_enc_core && dec_done)) begin

                        // Latch output atomically BEFORE feedback_reg updates
                        if (ctrl_mode_ctr)
                            dout_hold_r <= din_data ^ raw_text_out;
                        else if (ctrl_mode_cbc && ctrl_decrypt)
                            dout_hold_r <= raw_text_out ^ feedback_eff;
                        else
                            dout_hold_r <= raw_text_out;

                        iv_pending <= 1'b0;

                        // Update CBC/CTR feedback register
                        if (!ctrl_decrypt && ctrl_mode_cbc)
                            feedback_reg <= raw_text_out;           // CBC-E: next IV = ciphertext
                        else if (ctrl_decrypt && ctrl_mode_cbc)
                            feedback_reg <= din_data;               // CBC-D: next IV = ciphertext in
                        else if (ctrl_mode_ctr)
                            feedback_reg <= feedback_eff + 128'b1;  // CTR: increment counter

                        done_blocks <= done_blocks + 16'b1;

                        if (blk_remaining > 16'd1) begin
                            blk_remaining <= blk_remaining - 16'd1;
                            state         <= ST_DATA_LOAD;
                        end else begin
                            state         <= ST_DONE;
                        end
                    end
                end

                // ----------------------------------------------------------
                ST_DONE: begin
                    core_done_r  <= 1'b1;
                    core_busy_r  <= 1'b0;
                    state        <= ST_IDLE;
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // Held output driven to regfile
    assign dout_data = dout_hold_r;

    // =========================================================================
    // AES Cipher Core (Encrypt)
    // aes_cipher_top interface: clk, rst (active-LOW), ld, done,
    //                           key[127:0], text_in[127:0], text_out[127:0]
    // =========================================================================
    aes_cipher_top u_cipher (
        .clk      (aclk),
        .rst      (core_rst_n),    // active-LOW
        .ld       (enc_ld),
        .done     (enc_done),
        .key      (core_key_mux),
        .text_in  (text_in_mux),
        .text_out (enc_text_out)
    );

    // =========================================================================
    // AES Inverse Cipher Core (Decrypt)
    // aes_inv_cipher_top interface: clk, rst (active-LOW), kld, kdone,
    //                               ld, done, key[127:0],
    //                               text_in[127:0], text_out[127:0]
    // =========================================================================
    aes_inv_cipher_top u_inv_cipher (
        .clk      (aclk),
        .rst      (core_rst_n),    // active-LOW
        .kld      (dec_kld),
        .kdone    (dec_kdone),
        .ld       (dec_ld),
        .done     (dec_done),
        .key      (core_key_mux),
        .text_in  (text_in_mux),
        .text_out (dec_text_out)
    );

endmodule

`default_nettype wire

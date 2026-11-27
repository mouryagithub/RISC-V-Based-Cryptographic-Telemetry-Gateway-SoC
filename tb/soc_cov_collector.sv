// =============================================================================
// File        : tb/soc_cov_collector.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : SystemVerilog functional coverage collector aligned to all
//               38 verification testplan cases (Boot/SRAM/Crossbar, UART,
//               Timer, GPIO, SHA-256, AES-256, AXI DMA, and E2E Pipelines).
//               Imports package-scoped covergroup types from soc_cov_pkg so
//               Vivado xcrg merges bins across tb_soc_veer_cpu, tb_soc_c_test,
//               and tb_top into a single 17-covergroup unified report.
// =============================================================================

`timescale 1ns/1ps

module soc_cov_collector (
    input logic        clk,
    input logic        aresetn,

    // Boot / CPU Status
    input logic        is_cpu_mode,
    input logic        cpu_boot_ok,
    input logic        cpu_halted,

    // Interconnect Master s00 (CPU / DPI-C Host)
    input logic        s00_awvalid,
    input logic        s00_awready,
    input logic [31:0] s00_awaddr,
    input logic        s00_bvalid,
    input logic        s00_bready,
    input logic [1:0]  s00_bresp,
    input logic        s00_arvalid,
    input logic        s00_arready,
    input logic [31:0] s00_araddr,
    input logic        s00_rvalid,
    input logic        s00_rready,
    input logic [1:0]  s00_rresp,

    // Interconnect Master s01 (AXI DMA)
    input logic        s01_awvalid,
    input logic        s01_awready,
    input logic [31:0] s01_awaddr,
    input logic        s01_arvalid,
    input logic        s01_arready,
    input logic [31:0] s01_araddr,

    // Slave m05 (64 KB System SRAM)
    input logic        m05_awvalid,
    input logic        m05_awready,
    input logic [7:0]  m05_awlen,
    input logic        m05_wvalid,
    input logic        m05_wready,
    input logic [3:0]  m05_wstrb,
    input logic        m05_arvalid,
    input logic        m05_arready,
    input logic [7:0]  m05_arlen,

    // UART Status & Config
    input logic        uart_tx_pin,
    input logic [31:0] uart_lcr,
    input logic [15:0] uart_baud_div,
    input logic        uart_irq_en,
    input logic [31:0] uart_lsr,
    input logic        uart_rx_push,
    input logic        uart_wr_hpn,
    input logic        uart_rd_hpn,
    input logic        uart_irq,

    // System Timer Status & Config
    input logic        tmr_active,
    input logic [11:0] tmr_prescale,
    input logic [7:0]  tmr_step,
    input logic        tmr_intr_en,
    input logic        tmr_intr_state,
    input logic        tmr_irq,

    // GPIO Status & Config
    input logic        gpio_wr_hpn,
    input logic [11:0] gpio_awaddr,
    input logic [31:0] gpio_en_0,
    input logic [31:0] gpio_en_1,
    input logic [31:0] gpio_rise_en_0,
    input logic [31:0] gpio_rise_en_1,
    input logic [31:0] gpio_fall_en_0,
    input logic [31:0] gpio_fall_en_1,
    input logic [31:0] gpio_high_en_0,
    input logic [31:0] gpio_high_en_1,
    input logic [31:0] gpio_low_en_0,
    input logic [31:0] gpio_low_en_1,
    input logic [1:0]  gpio_intr,

    // SHA-256 Status & Config
    input logic        sha_wr_hpn,
    input logic [11:0] sha_awaddr,
    input logic [31:0] sha_wdata,
    input logic        sha_irq,

    // AES-256 Status & Config
    input logic [1:0]  aes_key_size,
    input logic        aes_decrypt,
    input logic        aes_mode_cbc,
    input logic        aes_mode_ctr,
    input logic [15:0] aes_total_blocks,
    input logic        aes_irq_en,
    input logic        aes_soft_rst,
    input logic        aes_done_pulse,
    input logic        aes_irq,

    // AXI DMA Config & Status
    input logic [1:0]  dma_desc_en,
    input logic [1:0]  dma_desc_rd_mod,
    input logic [1:0]  dma_desc_wr_mod,
    input logic        dma_go,
    input logic [7:0]  dma_max_burst,
    input logic        dma_done,
    input logic        dma_error,
    input logic        dma_err_valid,
    input logic        dma_err_src
);
    import soc_cov_pkg::*;

    // Address decoding helper -> 0=SRAM, 1=AES, 2=UART, 3=TIMER, 4=GPIO, 5=SHA, 6=UNMAPPED
    function automatic logic [2:0] decode_addr(input logic [31:0] addr);
        if (addr[31:16] == 16'h0000) begin
            return 3'd0;
        end else if (addr[31:16] == 16'h4000) begin
            case (addr[15:12])
                4'h0: return 3'd1; // AES
                4'h1: return 3'd2; // UART
                4'h2: return 3'd3; // TIMER
                4'h3: return 3'd4; // GPIO
                4'h4: return 3'd5; // SHA
                default: return 3'd6;
            endcase
        end else begin
            return 3'd6;
        end
    endfunction

    wire [2:0] s00_wr_tgt = decode_addr(s00_awaddr);
    wire [2:0] s00_rd_tgt = decode_addr(s00_araddr);
    wire [2:0] s01_wr_tgt = decode_addr(s01_awaddr);
    wire [2:0] s01_rd_tgt = decode_addr(s01_araddr);

    wire s00_aw_hpn = aresetn && s00_awvalid && s00_awready;
    wire s00_ar_hpn = aresetn && s00_arvalid && s00_arready;
    wire s00_b_hpn  = aresetn && s00_bvalid  && s00_bready;
    wire s00_r_hpn  = aresetn && s00_rvalid  && s00_rready;
    wire s01_aw_hpn = aresetn && s01_awvalid && s01_awready;
    wire s01_ar_hpn = aresetn && s01_arvalid && s01_arready;
    wire m05_aw_hpn = aresetn && m05_awvalid && m05_awready;
    wire m05_w_hpn  = aresetn && m05_wvalid  && m05_wready;
    wire m05_ar_hpn = aresetn && m05_arvalid && m05_arready;

    wire s00_s01_overlap = (s00_awvalid || s00_arvalid) &&
                           (s01_awvalid || s01_arvalid || dma_go);

    wire [1:0] uart_parity_cfg = {uart_lcr[4], uart_lcr[3]};
    wire [1:0] uart_tx_empty   = {uart_lsr[6], uart_lsr[5]};
    wire       gpio_rise_hit   = (|gpio_intr) && (|{gpio_rise_en_1, gpio_rise_en_0});
    wire       gpio_fall_hit   = (|gpio_intr) && (|{gpio_fall_en_1, gpio_fall_en_0});
    wire       gpio_high_hit   = (|gpio_intr) && (|{gpio_high_en_1, gpio_high_en_0});
    wire       gpio_low_hit    = (|gpio_intr) && (|{gpio_low_en_1,  gpio_low_en_0});
    wire [1:0] aes_mode_sel    = {aes_mode_ctr, aes_mode_cbc};

    // Instantiate shared package-scoped covergroups
`ifdef INCLUDE_SOC_INTERNAL_COV
    cg_boot_ctrl   u_cg_boot_ctrl   = new();
    cg_s00_wr      u_cg_s00_wr      = new();
    cg_s00_rd      u_cg_s00_rd      = new();
    cg_s00_resp    u_cg_s00_resp    = new();
    cg_sram        u_cg_sram        = new();
    cg_pipelines   u_cg_pipelines   = new();
`endif
    cg_uart        u_cg_uart        = new();
    cg_timer       u_cg_timer       = new();
    cg_gpio_wr     u_cg_gpio_wr     = new();
    cg_gpio_irq    u_cg_gpio_irq    = new();
    cg_sha_cmd     u_cg_sha_cmd     = new();
    cg_sha_irq     u_cg_sha_irq     = new();
    cg_aes_op      u_cg_aes_op      = new();
    cg_aes_events  u_cg_aes_events  = new();
    cg_dma_cfg     u_cg_dma_cfg     = new();
    cg_dma_bus     u_cg_dma_bus     = new();
    cg_dma_result  u_cg_dma_result  = new();

    // E2E pipeline state tracking
    reg pipe1_uart_to_sram_seen;
    reg pipe1_sram_to_sha_seen;
    reg pipe2_sram_to_aes_seen;
    reg pipe2_aes_cbc_done_seen;
    reg pipe2_aes_to_sram_seen;
    reg pipe_ingress_ok;
    reg pipe_egress_ok;

    // Edge-driven state trackers
    reg        prev_boot_ok, prev_cpu_halted;
    reg        prev_uart_irq, prev_uart_oe, prev_uart_pe, prev_uart_fe;
    reg        prev_tmr_active, prev_tmr_irq, prev_tmr_state;
    reg [1:0]  prev_gpio_intr;
    reg        prev_sha_irq;
    reg        prev_aes_irq, prev_aes_rst;
    reg        prev_dma_go, prev_dma_done, prev_dma_error;
    reg        prev_uart_tx;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            prev_boot_ok    <= 1'b0;
            prev_cpu_halted <= 1'b0;
            prev_uart_irq   <= 1'b0;
            prev_uart_oe    <= 1'b0;
            prev_uart_pe    <= 1'b0;
            prev_uart_fe    <= 1'b0;
            prev_tmr_active <= 1'b0;
            prev_tmr_irq    <= 1'b0;
            prev_tmr_state  <= 1'b0;
            prev_gpio_intr  <= 2'b00;
            prev_sha_irq    <= 1'b0;
            prev_aes_irq    <= 1'b0;
            prev_aes_rst    <= 1'b0;
            prev_dma_go     <= 1'b0;
            prev_dma_done   <= 1'b0;
            prev_dma_error  <= 1'b0;
            prev_uart_tx    <= 1'b1;

            pipe1_uart_to_sram_seen <= 1'b0;
            pipe1_sram_to_sha_seen  <= 1'b0;
            pipe2_sram_to_aes_seen  <= 1'b0;
            pipe2_aes_cbc_done_seen <= 1'b0;
            pipe2_aes_to_sram_seen  <= 1'b0;
            pipe_ingress_ok         <= 1'b0;
            pipe_egress_ok          <= 1'b0;
        end else begin
`ifdef INCLUDE_SOC_INTERNAL_COV
            // Boot / CPU state changes
            if ((cpu_boot_ok != prev_boot_ok) || (cpu_halted != prev_cpu_halted) || !prev_boot_ok) begin
                u_cg_boot_ctrl.sample(is_cpu_mode, cpu_boot_ok, cpu_halted);
            end
`endif
            prev_boot_ok    <= cpu_boot_ok;
            prev_cpu_halted <= cpu_halted;

`ifdef INCLUDE_SOC_INTERNAL_COV
            // Fabric / SRAM sampling on real handshakes
            if (s00_aw_hpn) u_cg_s00_wr.sample(s00_wr_tgt, s00_s01_overlap);
            if (s00_ar_hpn) u_cg_s00_rd.sample(s00_rd_tgt, s00_s01_overlap);
            if (s00_b_hpn || s00_r_hpn) u_cg_s00_resp.sample(s00_b_hpn, s00_bresp, s00_r_hpn, s00_rresp);
            if (m05_aw_hpn || m05_w_hpn || m05_ar_hpn) begin
                u_cg_sram.sample(m05_w_hpn, m05_wstrb, m05_aw_hpn, m05_awlen, m05_ar_hpn, m05_arlen);
            end
`endif

            // UART events
            if (uart_wr_hpn || uart_rd_hpn || uart_rx_push ||
                (uart_irq != prev_uart_irq) || (uart_lsr[1] != prev_uart_oe) ||
                (uart_lsr[2] != prev_uart_pe) || (uart_lsr[3] != prev_uart_fe)) begin
                u_cg_uart.sample(
                    uart_lcr[7], uart_baud_div, uart_parity_cfg, uart_lcr[2],
                    uart_lsr[3:0], uart_tx_empty, uart_irq_en, uart_irq
                );
            end
            prev_uart_irq <= uart_irq;
            prev_uart_oe  <= uart_lsr[1];
            prev_uart_pe  <= uart_lsr[2];
            prev_uart_fe  <= uart_lsr[3];

            // Timer events
            if ((tmr_active != prev_tmr_active) || (tmr_irq != prev_tmr_irq) || (tmr_intr_state != prev_tmr_state)) begin
                u_cg_timer.sample(tmr_active, tmr_step, tmr_prescale, tmr_intr_state, tmr_irq);
            end
            prev_tmr_active <= tmr_active;
            prev_tmr_irq    <= tmr_irq;
            prev_tmr_state  <= tmr_intr_state;

            // GPIO events
            if (gpio_wr_hpn) u_cg_gpio_wr.sample(gpio_awaddr, gpio_en_0, gpio_en_1);
            if (gpio_intr != prev_gpio_intr) begin
                u_cg_gpio_irq.sample(gpio_intr, gpio_rise_hit, gpio_fall_hit, gpio_high_hit, gpio_low_hit);
            end
            prev_gpio_intr <= gpio_intr;

            // SHA-256 events
            if (sha_wr_hpn && (sha_awaddr[7:0] == 8'h20)) u_cg_sha_cmd.sample(sha_awaddr[7:0], sha_wdata[1:0]);
            if (sha_irq != prev_sha_irq) u_cg_sha_irq.sample(sha_irq);
            prev_sha_irq <= sha_irq;

            // AES-256 events
            if (aes_done_pulse) begin
                u_cg_aes_op.sample(aes_key_size, aes_decrypt, aes_mode_sel, aes_total_blocks, aes_irq_en);
            end
            if ((aes_irq != prev_aes_irq) || (aes_soft_rst && !prev_aes_rst)) begin
                u_cg_aes_events.sample(aes_soft_rst, aes_irq);
            end
            prev_aes_irq <= aes_irq;
            prev_aes_rst <= aes_soft_rst;

            // DMA events
            if (dma_go && !prev_dma_go) begin
                u_cg_dma_cfg.sample(dma_desc_en, dma_desc_rd_mod[0], dma_desc_wr_mod[0], dma_max_burst);
            end
            if (s01_aw_hpn || s01_ar_hpn) begin
                u_cg_dma_bus.sample(s01_aw_hpn, s01_wr_tgt, s01_ar_hpn, s01_rd_tgt);
            end
            if ((dma_done && !prev_dma_done) || (dma_error && !prev_dma_error) ||
                (!dma_done && prev_dma_done) || (!dma_error && prev_dma_error)) begin
                u_cg_dma_result.sample(dma_done, dma_error, dma_err_valid, dma_err_src);
            end
            prev_dma_go    <= dma_go;
            prev_dma_done  <= dma_done;
            prev_dma_error <= dma_error;

            // E2E pipeline milestone tracking
            if (s01_ar_hpn && (s01_rd_tgt == 3'd2)) pipe1_uart_to_sram_seen <= 1'b1;
            if (pipe1_uart_to_sram_seen && s01_aw_hpn && (s01_wr_tgt == 3'd5)) pipe1_sram_to_sha_seen <= 1'b1;
            if (pipe1_sram_to_sha_seen && sha_irq && !prev_sha_irq) begin
                pipe_ingress_ok <= 1'b1;
            end

            if (s01_aw_hpn && (s01_wr_tgt == 3'd1) && (s01_awaddr[7:4] == 4'h4)) pipe2_sram_to_aes_seen <= 1'b1;
            if (pipe2_sram_to_aes_seen && aes_done_pulse && aes_mode_cbc) pipe2_aes_cbc_done_seen <= 1'b1;
            if (pipe2_aes_cbc_done_seen && s01_ar_hpn && (s01_rd_tgt == 3'd1) && (s01_araddr[7:4] == 4'h5)) pipe2_aes_to_sram_seen <= 1'b1;
            if (pipe2_aes_to_sram_seen && !uart_tx_pin && prev_uart_tx) begin
                pipe_egress_ok <= 1'b1;
            end
            prev_uart_tx <= uart_tx_pin;

`ifdef INCLUDE_SOC_INTERNAL_COV
            if (pipe_ingress_ok || pipe_egress_ok) begin
                u_cg_pipelines.sample(pipe_ingress_ok, pipe_egress_ok);
            end
`endif
        end
    end

endmodule

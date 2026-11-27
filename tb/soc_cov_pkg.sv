// =============================================================================
// File        : tb/soc_cov_pkg.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Package-scoped SystemVerilog functional covergroup definitions
//               aligned to all 38 verification testplan cases. Defining the
//               covergroup types in a shared package enables Vivado xcrg to
//               merge bins cleanly across tb_soc_veer_cpu, tb_soc_c_test, and
//               tb_top into a single unified 17-covergroup model.
// =============================================================================

package soc_cov_pkg;

`ifdef INCLUDE_SOC_INTERNAL_COV
    // -------------------------------------------------------------------------
    // Covergroup 1: Boot & CPU Execution (TC_BOOT_01..02)
    // -------------------------------------------------------------------------
    covergroup cg_boot_ctrl with function sample(
        logic is_cpu_mode,
        logic cpu_boot_ok,
        logic cpu_halted
    );
        type_option.merge_instances = 1;
        cp_cpu_mode : coverpoint is_cpu_mode {
            bins dpi_host = {1'b0};
            bins veer_cpu = {1'b1};
        }
        cp_boot_ok : coverpoint cpu_boot_ok {
            bins not_booted = {1'b0};
            bins booted     = {1'b1};
        }
        cp_cpu_halt : coverpoint cpu_halted {
            bins running    = {1'b0};
            bins wfi_halted = {1'b1};
        }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 2: AXI4 Interconnect Fabric (TC_BUS_01..02)
    // -------------------------------------------------------------------------
    covergroup cg_s00_wr with function sample(
        logic [2:0] wr_tgt,
        logic       overlap
    );
        type_option.merge_instances = 1;
        cp_wr_target : coverpoint wr_tgt {
            bins sram     = {3'd0};
            bins aes      = {3'd1};
            bins uart     = {3'd2};
            bins timer    = {3'd3};
            bins gpio     = {3'd4};
            bins sha      = {3'd5};
            bins unmapped = {3'd6};
        }
        cp_concurrent : coverpoint overlap {
            bins solo       = {1'b0};
            bins concurrent = {1'b1};
        }
    endgroup

    covergroup cg_s00_rd with function sample(
        logic [2:0] rd_tgt,
        logic       overlap
    );
        type_option.merge_instances = 1;
        cp_rd_target : coverpoint rd_tgt {
            bins sram     = {3'd0};
            bins aes      = {3'd1};
            bins uart     = {3'd2};
            bins timer    = {3'd3};
            bins gpio     = {3'd4};
            bins sha      = {3'd5};
            bins unmapped = {3'd6};
        }
        cp_concurrent : coverpoint overlap {
            bins solo       = {1'b0};
            bins concurrent = {1'b1};
        }
    endgroup

    covergroup cg_s00_resp with function sample(
        logic       b_hpn,
        logic [1:0] bresp,
        logic       r_hpn,
        logic [1:0] rresp
    );
        type_option.merge_instances = 1;
        cp_bresp : coverpoint bresp iff (b_hpn) {
            bins okay   = {2'b00};
            bins decerr = {2'b11};
        }
        cp_rresp : coverpoint rresp iff (r_hpn) {
            bins okay   = {2'b00};
            bins decerr = {2'b11};
        }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 3: 64 KB SRAM Memory Access & WSTRB (TC_BOOT_03)
    // -------------------------------------------------------------------------
    covergroup cg_sram with function sample(
        logic       w_hpn,
        logic [3:0] wstrb,
        logic       aw_hpn,
        logic [7:0] awlen,
        logic       ar_hpn,
        logic [7:0] arlen
    );
        type_option.merge_instances = 1;
        cp_wstrb : coverpoint wstrb iff (w_hpn) {
            bins byte0   = {4'b0001};
            bins byte1   = {4'b0010};
            bins byte2   = {4'b0100};
            bins byte3   = {4'b1000};
            bins half_lo = {4'b0011};
            bins half_hi = {4'b1100};
            bins word    = {4'b1111};
        }
        cp_wr_burst : coverpoint awlen iff (aw_hpn) {
            bins single = {8'd0};
            bins burst  = {[8'd1:8'd255]};
        }
        cp_rd_burst : coverpoint arlen iff (ar_hpn) {
            bins single = {8'd0};
            bins burst  = {[8'd1:8'd255]};
        }
    endgroup
`endif

    // -------------------------------------------------------------------------
    // Covergroup 4: UART Controller (TC_UART_01..06)
    // -------------------------------------------------------------------------
    covergroup cg_uart with function sample(
        logic        dlab,
        logic [15:0] baud_div,
        logic [1:0]  parity_cfg,
        logic        stop_2bit,
        logic [3:0]  lsr_flags,
        logic [1:0]  tx_empty,
        logic        irq_en,
        logic        irq
    );
        type_option.merge_instances = 1;
        cp_dlab : coverpoint dlab {
            bins op_mode  = {1'b0};
            bins div_mode = {1'b1};
        }
        cp_baud_div : coverpoint baud_div {
            bins default_434 = {16'd434};
            bins custom      = {[16'd1:16'd433], [16'd435:16'hFFFF]};
        }
        cp_parity : coverpoint parity_cfg {
            bins disabled = {2'b00, 2'b10};
            bins odd_par  = {2'b01};
            bins even_par = {2'b11};
        }
        cp_stop_bits : coverpoint stop_2bit {
            bins stop_1 = {1'b0};
            bins stop_2 = {1'b1};
        }
        cp_lsr_dr : coverpoint lsr_flags[0] {
            bins empty = {1'b0};
            bins ready = {1'b1};
        }
        cp_lsr_oe : coverpoint lsr_flags[1] {
            bins clear   = {1'b0};
            bins overrun = {1'b1};
        }
        cp_lsr_pe : coverpoint lsr_flags[2] {
            bins clear      = {1'b0};
            bins parity_err = {1'b1};
        }
        cp_lsr_fe : coverpoint lsr_flags[3] {
            bins clear       = {1'b0};
            bins framing_err = {1'b1};
        }
        cp_lsr_tx : coverpoint tx_empty {
            bins busy      = {2'b00};
            bins thre_only = {2'b01};
            bins all_empty = {2'b11};
        }
        cp_uart_irq_en : coverpoint irq_en {
            bins dis = {1'b0};
            bins en  = {1'b1};
        }
        cp_uart_irq : coverpoint irq {
            bins low  = {1'b0};
            bins high = {1'b1};
        }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 5: System Timer (TC_TMR_01..03)
    // -------------------------------------------------------------------------
    covergroup cg_timer with function sample(
        logic        active,
        logic [7:0]  step,
        logic [11:0] prescale,
        logic        intr_state,
        logic        irq
    );
        type_option.merge_instances = 1;
        cp_active : coverpoint active {
            bins off = {1'b0};
            bins on  = {1'b1};
        }
        cp_step : coverpoint step {
            bins step_1   = {8'd1};
            bins step_gt1 = {[8'd2:8'd255]};
        }
        cp_prescale : coverpoint prescale {
            bins zero    = {12'd0};
            bins div_gt0 = {[12'd1:12'hFFF]};
        }
        cp_intr_state : coverpoint intr_state {
            bins cleared = {1'b0};
            bins pending = {1'b1};
        }
        cp_timer_irq : coverpoint irq {
            bins low  = {1'b0};
            bins high = {1'b1};
        }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 6: GPIO 64-Pin Controller (TC_GPIO_01..05)
    // -------------------------------------------------------------------------
    covergroup cg_gpio_wr with function sample(
        logic [11:0] awaddr,
        logic [31:0] en_0,
        logic [31:0] en_1
    );
        type_option.merge_instances = 1;
        cp_reg : coverpoint awaddr {
            bins oe         = {12'h080, 12'h084};
            bins out        = {12'h180, 12'h184};
            bins atomic_set = {12'h200, 12'h204};
            bins atomic_clr = {12'h280, 12'h284};
            bins atomic_tgl = {12'h300, 12'h304};
            bins irq_en     = {12'h380, 12'h384, 12'h400, 12'h404,
                               12'h480, 12'h484, 12'h500, 12'h504};
            bins status_w1c = {12'h580, 12'h584};
        }
        cp_en0 : coverpoint en_0 {
            bins all_in  = {32'h0000_0000};
            bins all_out = {32'hFFFF_FFFF};
        }
        cp_en1 : coverpoint en_1 {
            bins all_in  = {32'h0000_0000};
            bins all_out = {32'hFFFF_FFFF};
        }
    endgroup

    covergroup cg_gpio_irq with function sample(
        logic [1:0] intr,
        logic       rise_hit,
        logic       fall_hit,
        logic       high_hit,
        logic       low_hit
    );
        type_option.merge_instances = 1;
        cp_b0        : coverpoint intr[0]  { bins low = {0}; bins high = {1}; }
        cp_b1        : coverpoint intr[1]  { bins low = {0}; bins high = {1}; }
        cp_rise_mode : coverpoint rise_hit { bins off = {0}; bins hit  = {1}; }
        cp_fall_mode : coverpoint fall_hit { bins off = {0}; bins hit  = {1}; }
        cp_high_mode : coverpoint high_hit { bins off = {0}; bins hit  = {1}; }
        cp_low_mode  : coverpoint low_hit  { bins off = {0}; bins hit  = {1}; }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 7: SHA-256 Accelerator (TC_SHA_01..05)
    // -------------------------------------------------------------------------
    covergroup cg_sha_cmd with function sample(
        logic [7:0] addr_lo,
        logic [1:0] wdata_lo
    );
        type_option.merge_instances = 1;
        cp_cmd : coverpoint wdata_lo iff (addr_lo == 8'h20) {
            bins init_256 = {2'b01};
            bins next_256 = {2'b10};
        }
    endgroup

    covergroup cg_sha_irq with function sample(logic irq);
        type_option.merge_instances = 1;
        cp_sha_irq : coverpoint irq {
            bins low  = {1'b0};
            bins high = {1'b1};
        }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 8: AES-256 Accelerator (TC_AES_01..06)
    // -------------------------------------------------------------------------
    covergroup cg_aes_op with function sample(
        logic [1:0]  key_size,
        logic        decrypt,
        logic [1:0]  mode_sel,
        logic [15:0] total_blocks,
        logic        irq_en
    );
        type_option.merge_instances = 1;
        cp_key_size : coverpoint key_size {
            bins aes128 = {2'b00};
            ignore_bins aes192 = {2'b01};
            bins aes256 = {2'b10};
        }
        cp_decrypt : coverpoint decrypt {
            bins encrypt = {1'b0};
            bins decrypt = {1'b1};
        }
        cp_mode : coverpoint mode_sel {
            bins ecb = {2'b00};
            bins cbc = {2'b01};
            bins ctr = {2'b10};
        }
        cp_blk_cnt : coverpoint total_blocks {
            bins single = {16'd1};
            bins multi  = {[16'd2:16'hFFFF]};
        }
        cp_irq_en : coverpoint irq_en {
            bins disabled = {1'b0};
            bins enabled  = {1'b1};
        }
        cx_cfg : cross cp_decrypt, cp_mode;
    endgroup

    covergroup cg_aes_events with function sample(
        logic soft_rst,
        logic irq
    );
        type_option.merge_instances = 1;
        cp_soft_rst : coverpoint soft_rst { bins idle = {0}; bins rst = {1}; }
        cp_aes_irq  : coverpoint irq      { bins low  = {0}; bins high = {1}; }
    endgroup

    // -------------------------------------------------------------------------
    // Covergroup 9: AXI DMA Controller (TC_DMA_01..05)
    // -------------------------------------------------------------------------
    covergroup cg_dma_cfg with function sample(
        logic [1:0] desc_en,
        logic       rd_mod,
        logic       wr_mod,
        logic [7:0] max_burst
    );
        type_option.merge_instances = 1;
        cp_desc_en : coverpoint desc_en {
            bins desc0_only = {2'b01};
            bins desc1_only = {2'b10};
            bins dual_desc  = {2'b11};
        }
        cp_rd_mode : coverpoint rd_mod {
            bins incr  = {1'b0};
            bins fixed = {1'b1};
        }
        cp_wr_mode : coverpoint wr_mod {
            bins incr  = {1'b0};
            bins fixed = {1'b1};
        }
        cp_max_burst : coverpoint max_burst {
            bins single_beat = {8'd0};
            bins multi_beat  = {[8'd1:8'd255]};
        }
    endgroup

    covergroup cg_dma_bus with function sample(
        logic       aw_hpn,
        logic [2:0] wr_tgt,
        logic       ar_hpn,
        logic [2:0] rd_tgt
    );
        type_option.merge_instances = 1;
        cp_s01_wr_tgt : coverpoint wr_tgt iff (aw_hpn) {
            bins sram     = {3'd0};
            bins aes      = {3'd1};
            bins uart     = {3'd2};
            bins timer    = {3'd3};
            bins gpio     = {3'd4};
            bins sha      = {3'd5};
            bins unmapped = {3'd6};
        }
        cp_s01_rd_tgt : coverpoint rd_tgt iff (ar_hpn) {
            bins sram     = {3'd0};
            bins aes      = {3'd1};
            bins uart     = {3'd2};
            bins timer    = {3'd3};
            bins gpio     = {3'd4};
            bins sha      = {3'd5};
            bins unmapped = {3'd6};
        }
    endgroup

    covergroup cg_dma_result with function sample(
        logic done,
        logic err,
        logic err_valid,
        logic err_src
    );
        type_option.merge_instances = 1;
        cp_done    : coverpoint done { bins low = {0}; bins high = {1}; }
        cp_err     : coverpoint err  { bins ok  = {0}; bins err  = {1}; }
        cp_err_src : coverpoint {err_valid, err_src} {
            bins no_err = {2'b00};
            bins rd_err = {2'b10};
            bins wr_err = {2'b11};
        }
    endgroup

`ifdef INCLUDE_SOC_INTERNAL_COV
    // -------------------------------------------------------------------------
    // Covergroup 10: Integrated E2E Pipelines (TC_PIPE_01..02)
    // -------------------------------------------------------------------------
    covergroup cg_pipelines with function sample(
        logic ingress_ok,
        logic egress_ok
    );
        type_option.merge_instances = 1;
        cp_ingress : coverpoint ingress_ok {
            bins verified = {1'b1};
        }
        cp_egress : coverpoint egress_ok {
            bins verified = {1'b1};
        }
    endgroup
`endif

endpackage : soc_cov_pkg

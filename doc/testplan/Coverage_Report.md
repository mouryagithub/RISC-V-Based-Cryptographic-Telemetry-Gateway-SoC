# Cryptographic Telemetry Gateway SoC — Peripheral Verification & Coverage Report

**Methodology:** UVM-1.2 Constrained-Random & Directed Peripheral VIPs + SystemVerilog Covergroups & RTL Code Coverage
**Verification Scope:** 6 Peripheral UVM-1.2 VIPs (`uart`, `timer`, `gpio`, `sha`, `aes`, `dma`) on [`tb_periph_top.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/tb_periph_top.sv) — **30 / 30** Peripheral Testplan Cases (`TC_BOOT`, `TC_BUS`, and `TC_PIPE` excluded per specification)

---

## 1. Executive Summary

| Metric | Result | Scope |
|---|---|---|
| **Peripheral Testplan Pass Rate** | **30 / 30 PASS** (`0` Failures, `0` Blocked) | All 6 `*_vip_test.sv` tests |
| **UVM Simulation Cleanliness** | **0** `UVM_WARNING` · **0** `UVM_ERROR` · **0** `UVM_FATAL` | All 6 UVM regression runs |
| **UVM Scoreboard Checks Passed** | **4,555 / 4,555** (`0` Mismatches) | Per-VIP Scoreboards |
| **Merged Functional Coverage** | **100.00%** (`29 / 29` Covergroups, `29 / 29` Instances, Insts Score `100`) | 18 VIP + 11 [`soc_cov_pkg.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/soc_cov_pkg.sv) CGs |
| **VIP Scoreboard Functional Coverage** | **100.00%** (All 6 VIPs · `234 / 234` Feature Paths) | Per-VIP Scoreboards |
| **Peripheral RTL Code Coverage (`34` files)** | **93.57%** Weighted Stmt · **82.04%** Avg Br (**100.00%** Timer/GPIO/SHA · **98.90%** AES · **97.76%** UART · **84.15%** DMA) | `rtl/{uart,timer,gpio,sha,aes,dma}/` |
| **Full Suite Code Coverage (`76` files)** | **94.67%** Stmt (`10,659 / 11,259`) · **48.96%** Br · **29.26%** Cond · **35.91%** Tgl (`tb/`: `95.46%` Stmt · `rtl/`: `93.29%` Stmt / `81.26%` AvgBr) | Combined UVM + SoC RTL elaboration |

---

## 2. Per-Peripheral UVM Architecture, Testplan & Scoreboard Summary

| Peripheral | UVM VIP Package | Testplan IDs (`30 / 30` PASS) | Scoreboard Checks | SB Func Cov | SB Feature Paths | RTL Stmt / Avg Br | Test Suite |
|---|---|---|---:|---:|---:|---:|---|
| **UART** | [`uart_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/uart_vip_uvm_tb) | `TC_UART_01` – `TC_UART_06` (`6/6`) | 1,201 | **100.00%** | **100.00%** (`22/22`) | 97.76% / 88.24% | [`uart_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/uart_vip_uvm_tb/uart_vip_test.sv) |
| **Timer** | [`timer_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/timer_vip_uvm_tb) | `TC_TMR_01` – `TC_TMR_03` (`3/3`) | 64 | **100.00%** | **100.00%** (`29/29`) | **100.00%** / 94.74% | [`timer_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/timer_vip_uvm_tb/timer_vip_test.sv) |
| **GPIO** | [`gpio_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/gpio_vip_uvm_tb) | `TC_GPIO_01` – `TC_GPIO_05` (`5/5`) | 137 | **100.00%** | **100.00%** (`45/45`) | **100.00%** / 92.73% | [`gpio_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/gpio_vip_uvm_tb/gpio_vip_test.sv) |
| **SHA-256** | [`sha_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/sha_vip_uvm_tb) | `TC_SHA_01` – `TC_SHA_05` (`5/5`) | 247 | **100.00%** | **100.00%** (`52/52`) | **100.00%** / 94.89% | [`sha_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/sha_vip_uvm_tb/sha_vip_test.sv) |
| **AES-256** | [`aes_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/aes_vip_uvm_tb) | `TC_AES_01` – `TC_AES_06` (`6/6`) | 301 | **100.00%** | **100.00%** (`61/61`) | 98.90% / 94.91% | [`aes_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/aes_vip_uvm_tb/aes_vip_test.sv) |
| **AXI DMA** | [`dma_vip_uvm_tb`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/dma_vip_uvm_tb) | `TC_DMA_01` – `TC_DMA_05` (`5/5`) | 2,605 | **100.00%** | **100.00%** (`25/25`) | 84.15% / 61.99% | [`dma_vip_test.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/dma_vip_uvm_tb/dma_vip_test.sv) |

### Testcase Coverage Matrix

| Peripheral | Testcase ID | Verified Behaviour | Status |
|---|---|---|---:|
| **UART** | `TC_UART_01` | Config reset, LCR/FCR/IER decode, split AW/W & DLAB divisor gating | **PASS** |
| **UART** | `TC_UART_02` | Serial TX 8N1, 8E2 (even parity + 2 stop), and odd parity | **PASS** |
| **UART** | `TC_UART_03` | Serial RX ingress frame capture (8N1 & 8O2) | **PASS** |
| **UART** | `TC_UART_04` | RX Data-Available interrupt assertion & FIFO drain clear | **PASS** |
| **UART** | `TC_UART_05` | Back-to-back burst TX, 16-byte FIFO stress & simultaneous push+pull (`NN`/`NP`/`PP`) | **PASS** |
| **UART** | `TC_UART_06` | LSR Framing (`FE`, incl. 8O2 stop1/stop2/break `WaitIdleState`), Parity (`PE`), and Overrun (`OE`) | **PASS** |
| **Timer** | `TC_TMR_01` | Free-running counter (`prescale=0, step=1` & `prescale=3, step=5` rollover) | **PASS** |
| **Timer** | `TC_TMR_02` | Compare match `INTR_STATE` & `timer_irq` assertion | **PASS** |
| **Timer** | `TC_TMR_03` | `RW1C` interrupt clear, `INTR_TEST0`, and full register decode | **PASS** |
| **GPIO** | `TC_GPIO_01` | `INFO=64` identification & register reset defaults | **PASS** |
| **GPIO** | `TC_GPIO_02` | Bank 0 & Bank 1 output enable (`OE`) and pin drive | **PASS** |
| **GPIO** | `TC_GPIO_03` | 2-stage synchronizer external pin input capture | **PASS** |
| **GPIO** | `TC_GPIO_04` | Atomic `SET` / `CLR` / `TGL` operations across both banks | **PASS** |
| **GPIO** | `TC_GPIO_05` | `RISE` / `FALL` / `HIGH` / `LOW` interrupts across both banks | **PASS** |
| **SHA-256** | `TC_SHA_01` | Core IDs (`NAME0/1`, `VERSION`), `CTRL` & `STATUS.READY` | **PASS** |
| **SHA-256** | `TC_SHA_02` | NIST FIPS 180-4 SHA-256 `'abc'` single-block digest | **PASS** |
| **SHA-256** | `TC_SHA_03` | Multi-block SHA-256 `INIT` + `NEXT` state chaining | **PASS** |
| **SHA-256** | `TC_SHA_04` | `BUSY` transition, IRQ latch/clear & SHA-224 digest verification | **PASS** |
| **SHA-256** | `TC_SHA_05` | 16-word `BLOCK0..15` addressing, full bit toggle & AXI ready wait states | **PASS** |
| **AES-256** | `TC_AES_01` | Write-only key/input protection, R/W registers, split AW/W & unmapped decode | **PASS** |
| **AES-256** | `TC_AES_02` | AES-128 & AES-256 key expansion | **PASS** |
| **AES-256** | `TC_AES_03` | AES-256 ECB encrypt & decrypt | **PASS** |
| **AES-256** | `TC_AES_04` | AES-256 CBC 2-block encryption | **PASS** |
| **AES-256** | `TC_AES_05` | AES-256 CBC decryption & CTR encrypt/decrypt | **PASS** |
| **AES-256** | `TC_AES_06` | `aes_irq` assertion & `W1C` clear | **PASS** |
| **AXI DMA** | `TC_DMA_01` | DMA CSR `0xCAFE` ID, partial `wstrb`, split AW/W, invalid R/W & descriptor config | **PASS** |
| **AXI DMA** | `TC_DMA_02` | 256-byte SRAM-to-SRAM AXI4 burst transfer, 4-beat bursts & concurrent R/W | **PASS** |
| **AXI DMA** | `TC_DMA_03` | Dual-descriptor & `DESC1`-only chaining | **PASS** |
| **AXI DMA** | `TC_DMA_04` | Fixed-address, all slave targets (`UART`/`TIMER`/`GPIO`/`SHA`/`AES`/`SRAM`), aligned tails (`1..7B`), zero-byte & abort | **PASS** |
| **AXI DMA** | `TC_DMA_05` | Bus fault trap (`RD`/`WR`, `0x5000_0000` & `0xFFFF_FFF0` wrap) & `dma_error_o` interrupt | **PASS** |

---

## 3. Functional Coverage (`100.00%` — `29 / 29` Covergroups)

All **29 / 29** merged covergroups (`18` VIP Scoreboard covergroups + `11` SoC peripheral covergroups in [`soc_cov_pkg.sv`](file:///home/mourya/projects/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/tb/soc_cov_pkg.sv)) achieved **100.00%** coverage with **0 uncovered bins** (`Total Insts Score = 100`).

| Subsystem | VIP Scoreboard Covergroups (`100.00%`) | SoC Monitor Covergroups (`100.00%`) |
|---|---|---|
| **UART** | `cg_uart_tx` (`cp_baud` 2/2, `cp_parity` 3/3, `cp_stop` 2/2)<br>`cg_uart_reg` (`cp_off` 5/5, `cp_dir` 2/2, `cp_dlab` 2/2)<br>`cg_uart_err_irq` (`cp_oe`, `cp_pe`, `cp_fe`, `cp_irq` 2/2 ea.) | `cg_uart` (`cp_dlab`, `cp_baud_div`, `cp_parity`, `cp_stop_bits`, `cp_lsr_{dr,oe,pe,fe,tx}`, `cp_uart_irq_en`, `cp_uart_irq` — all 100%) |
| **Timer** | `cg_tmr_wr` (`cp_wr_off` 10/10, `cp_active`, `cp_intr_en`, `cp_w1c`, `cp_intr_test`, `cp_prescale`, `cp_step` 2/2 ea.)<br>`cg_tmr_rd` (`cp_rd_off` 10/10)<br>`cg_tmr_irq` (`cp_irq` 2/2) | `cg_timer` (`cp_active`, `cp_step`, `cp_prescale`, `cp_intr_state`, `cp_timer_irq` 2/2 ea.) |
| **GPIO** | `cg_gpio_wr` (`cp_wr_off` 22/22)<br>`cg_gpio_rd` (`cp_rd_off` 19/19)<br>`cg_gpio_pins` (`cp_b0_intr` 2/2, `cp_b1_intr` 2/2) | `cg_gpio_wr` (`cp_reg` 7/7, `cp_en0` 2/2, `cp_en1` 2/2)<br>`cg_gpio_irq` (`cp_b0`, `cp_b1`, `cp_rise_mode`, `cp_fall_mode`, `cp_high_mode`, `cp_low_mode` 2/2 ea.) |
| **SHA-256** | `cg_sha_wr` (`cp_wr_area` 18/18, `cp_ctrl_cmd` 3/3)<br>`cg_sha_rd` (`cp_rd_area` 30/30)<br>`cg_sha_irq` (`cp_irq` 2/2) | `cg_sha_cmd` (`cp_cmd` 2/2)<br>`cg_sha_irq` (`cp_sha_irq` 2/2) |
| **AES-256** | `cg_aes_cmd` (`cp_key_size`, `cp_decrypt`, `cp_blk_cnt`, `cp_irq_en`, `cp_soft_rst`, `cp_mode`, `cx_256_modes` 6/6)<br>`cg_aes_reg` (`cp_off` 24/24, `cp_dir` 2/2, `cx_reg_dir` 48/48)<br>`cg_aes_irq` (`cp_irq` 2/2) | `cg_aes_op` (`cp_key_size`, `cp_decrypt`, `cp_mode`, `cp_blk_cnt`, `cp_irq_en`, `cx_cfg` 6/6)<br>`cg_aes_events` (`cp_soft_rst` 2/2, `cp_aes_irq` 2/2) |
| **AXI DMA** | `cg_dma_ctrl` (`cp_desc_en` 3/3, `cp_rd_mode`, `cp_wr_mode`, `cp_max_b`, `cp_abort` 2/2 ea.)<br>`cg_dma_bus` (`cp_wr_tgt` 7/7, `cp_rd_tgt` 7/7, `cp_axlen`, `cp_burst` 2/2 ea.)<br>`cg_dma_status` (`cp_done`, `cp_err` 2/2 ea.) | `cg_dma_cfg` (`cp_desc_en` 3/3, `cp_rd_mode`, `cp_wr_mode`, `cp_max_burst` 2/2 ea.)<br>`cg_dma_bus` (`cp_s01_wr_tgt` 7/7, `cp_s01_rd_tgt` 7/7)<br>`cg_dma_result` (`cp_done` 2/2, `cp_err` 2/2, `cp_err_src` 3/3) |

---

## 4. Peripheral RTL Code Coverage

| Peripheral | RTL File | Statement % | Branch % | Condition % | Toggle % |
|---|---|---:|---:|---:|---:|
| **Timer** | `axi_timer_top.v` | **100.00%** | 89.47% | 0.00% | 77.86% |
| **Timer** | `timer_core.sv` | **100.00%** | **100.00%** | 50.00% | 66.96% |
| **GPIO** | `axi_gpio_top.v` | **100.00%** | 92.73% | 0.00% | 40.03% |
| **SHA-256** | `axi_sha256_top.v` | **100.00%** | 78.95% | 66.67% | 66.11% |
| **SHA-256** | `sha256.v` | **100.00%** | **100.00%** | **100.00%** | 94.86% |
| **SHA-256** | `sha256_core.v` | **100.00%** | 97.06% | **100.00%** | 60.36% |
| **SHA-256** | `sha256_k_constants.v` | **100.00%** | 98.46% | 0.00% | **100.00%** |
| **SHA-256** | `sha256_w_mem.v` | **100.00%** | **100.00%** | **100.00%** | 94.70% |
| **AES-256** | `aes_regfile.v` | **100.00%** | 76.79% | 0.00% | 62.19% |
| **AES-256** | `aes_cipher_top.v` | **100.00%** | **100.00%** | 0.00% | 85.01% |
| **AES-256** | `aes_inv_cipher_top.v` | **100.00%** | **100.00%** | **100.00%** | 37.82% |
| **AES-256** | `aes_key_expand_256.v` | **100.00%** | **100.00%** | 0.00% | 95.59% |
| **AES-256** | `aes_rcon.v` | **100.00%** | **100.00%** | 0.00% | 41.46% |
| **AES-256** | `aes_sbox.v` | **100.00%** | 99.61% | 0.00% | **100.00%** |
| **AES-256** | `aes_inv_sbox.v` | **100.00%** | **100.00%** | 0.00% | **100.00%** |
| **AES-256** | `aes_core_top.v` | 86.67% | 82.86% | **100.00%** | 65.29% |
| **UART** | `uart_receiver.v` | **100.00%** | 92.31% | **100.00%** | 61.38% |
| **UART** | `uart_transmitter.v` | **100.00%** | 89.47% | 83.33% | 83.69% |
| **UART** | `uart_parity_bit_compute.v` | **100.00%** | **100.00%** | 0.00% | **100.00%** |
| **UART** | `axi_uart_top.v` | 99.24% | 90.16% | 66.67% | 39.00% |
| **UART** | `axi_internal_fifo.v` | 92.38% | 67.50% | **100.00%** | 83.62% |
| **UART** | `uart_controller.v` | 87.50% | 90.00% | 0.00% | 55.35% |
| **AXI DMA** | `dma_axi_top.sv` | **100.00%** | 0.00% | 0.00% | 54.44% |
| **AXI DMA** | `dma_fsm.sv` | **100.00%** | **100.00%** | 87.50% | 25.92% |
| **AXI DMA** | `dma_axi_if.sv` | **100.00%** | 94.23% | 40.00% | 68.39% |
| **AXI DMA** | `rggen_register_common.v` | **100.00%** | 62.50% | 75.00% | 28.97% |
| **AXI DMA** | `rggen_axi4lite_skid_buffer.v` | 97.30% | 88.89% | 0.00% | 44.95% |
| **AXI DMA** | `rggen_bit_field.v` | 86.49% | 38.10% | 12.00% | 29.55% |
| **AXI DMA** | `dma_fifo.sv` | 86.67% | 71.15% | 32.14% | 33.96% |
| **AXI DMA** | `rggen_axi4lite_adapter.v` | 86.21% | 82.61% | 85.71% | 45.14% |
| **AXI DMA** | `dma_axi_wrapper.sv` | 78.26% | 50.00% | 0.00% | 47.08% |
| **AXI DMA** | `rggen_address_decoder.v` | 75.00% | 40.00% | 25.00% | 62.50% |
| **AXI DMA** | `dma_streamer.sv` | 73.00% | 41.36% | 51.39% | 52.65% |
| **AXI DMA** | `rggen_adapter_common.v` | 66.67% | 75.00% | 50.00% | 47.88% |

*Coverage notes:* Remaining uncovered RTL items reflect structurally unreachable or parameterized logic rather than unverified peripheral features: `ST_KEY_LOAD2/WAIT2` (`unused for parallel 256-bit core`) in `aes_core_top.v`; defensive `PN` (`// MUST NEVER HAPPEN!`) in `axi_internal_fifo.v` and FSM `default:` arms in `uart_controller.v`; `DMA_DATA_WIDTH==64`, `SLOTS==1`, and unused `rggen_*` modes in DMA; synthetic `MISSING DEFAULT` rows (`aes_sbox.v`, `sha256_k_constants.v`) and `0.00%` cells where zero conditions/branches exist.

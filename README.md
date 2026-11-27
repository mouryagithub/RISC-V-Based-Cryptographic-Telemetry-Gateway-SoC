# RISC-V Based Cryptographic Telemetry Gateway SoC
### with AES-256 and SHA-256 Engines

> **Honours Project — RTL Design & UVM-1.2 Verification**  
> Languages: SystemVerilog (IEEE 1800 / UVM-1.2) / Verilog / DPI-C  
> Peripheral Verification: **30 / 30 PASS** · **100.00%** Merged Functional Coverage (`29 / 29` Covergroups) · **93.57%** Peripheral RTL Statement Coverage

---

## 1. Overview & Motivation

Telemetry gateways deployed in embedded, industrial, and edge environments require low-latency hardware acceleration for data confidentiality and integrity alongside deterministic control over serial, timer, DMA, and general-purpose I/O interfaces. Offloading symmetric block encryption (AES-256) and cryptographic hashing (SHA-256) to dedicated AXI-attached hardware blocks reduces CPU overhead and increases telemetry processing throughput.

This repository implements the integrated RTL, AMBA AXI4 / AXI4-Lite interconnect fabric, 64 KB on-chip SRAM, cryptographic and peripheral subsystems, DPI-C firmware test suite, and standalone **UVM-1.2 Verification IP (VIP)** suites for all six SoC peripherals (**UART, Timer, GPIO, SHA-256, AES-256, and AXI DMA**).

### Key Objectives

- Integrate an **AES-256** accelerator (`aes_core_top` with `aes_key_expand_256` supporting ECB, CBC, and CTR modes) and a **SHA-256 / SHA-224** accelerator (`axi_sha256_top` wrapping Secworks `sha256`) behind uniform 32-bit AXI4-Lite slave interfaces.
- Connect system masters (`veer_core_top` or external `ext_s00_axi_*`, plus `dma_axi_top` on `s01`) to five AXI4-Lite peripheral slaves (`m00`–`m04`) and a 64 KB AXI4 on-chip SRAM (`m05`, `rtl/mem/axi_sram.v`) via an **AXI4 2-master × 6-slave crossbar** (`axi_interconnect_wrap_2x6`).
- Route peripheral and DMA interrupts (`uart_irq`, `timer_irq`, `aes_irq`, `sha_irq`, `dma_done`, `dma_error`, `gpio_intr[1:0]`) to the VeeR EL2 PIC gateway (`pic_ext_irqs[8:1]`).
- Verify all six SoC peripherals (`TC_UART_01–06`, `TC_TMR_01–03`, `TC_GPIO_01–05`, `TC_SHA_01–05`, `TC_AES_01–06`, `TC_DMA_01–05`) using dedicated **UVM-1.2 VIPs**, scoreboards, and SystemVerilog covergroups compiled on [`tb/tb_periph_top.sv`](tb/tb_periph_top.sv) via [`run/run_periph_vip.f`](run/run_periph_vip.f).

---

## 2. System Architecture

### 2.1 SoC Block Diagram & Integrated RTL

```text
+-----------------------------------------------------------------------------+
|                Integrated Telemetry Gateway SoC Architecture                |
+-----------------------------------------------------------------------------+
|                                                                             |
|   +-----------------------+                  +--------------------------+   |
|   |  VeeR EL2 RISC-V Core | (s00 / ext)      |   AXI4 DMA Controller    |   |
|   |  (rtl/veer_core_top)  |---+          +---|   (rtl/dma/dma_axi_top)  |   |
|   +-----------------------+   |          |   +--------------------------+   |
|                               v          v (s01)                            |
|                    +--------------------------------+                       |
|                    |   AXI4 2x6 Crossbar Fabric     |                       |
|                    |   (axi_interconnect_wrap_2x6)  |                       |
|                    +--------------------------------+                       |
|                       |    |    |    |    |        |                        |
|      +----------------+    |    |    |    |        +--------------+         |
|      v                     v    v    v    v                       v         |
|  [AXI4-to-AXI4-Lite Bridges (m00..m04)]                   [m05 AXI4 Slave]  |
|   |      |       |      |       |                         * 64 KB System    |
|   v      v       v      v       v                           SRAM (axi_sram) |
|  AES   UART   Timer   GPIO   SHA-256                        0x0000_0000     |
+-----------------------------------------------------------------------------+
```

In [`rtl/soc_top.v`](rtl/soc_top.v), `soc_top #(USE_INTERNAL_CPU=1, AXI_DATA_WIDTH=32, AXI_ADDR_WIDTH=32, AXI_ID_WIDTH=8)` integrates:

- **Master `s00` (CPU / Testbench Master):** Multiplexed by `USE_INTERNAL_CPU`:
  - `1`: `veer_core_top` ([`rtl/veer_core_top.sv`](rtl/veer_core_top.sv)) wrapping `rtl/Cores-VeeR-EL2/` with inline 64-to-32-bit LSU width steering.
  - `0`: External AXI4 master interface `ext_s00_axi_*` (driven by [`tb/tb_periph_top.sv`](tb/tb_periph_top.sv), [`tb/tb_top.sv`](tb/tb_top.sv), and [`tb/tb_soc_c_test.sv`](tb/tb_soc_c_test.sv)).
- **Master `s01` (DMA Master):** `dma_axi_top` ([`rtl/dma/dma_axi_top.sv`](rtl/dma/dma_axi_top.sv)) configured with `DMA_NUM_DESC=2`, `AXI_DATA_WIDTH=32`, and `AXI_TXN_ID_WIDTH=8`. Its AXI4-Lite CSR configuration slave (`dma_csr_*`) is exported on `soc_top` and driven by [`tb/soc_axi_if.sv`](tb/soc_axi_if.sv) / `tb_soc_c_test.sv`.
- **Slaves `m00`–`m04`:** Five 4 KB (`12`-bit) peripheral windows bridged via `axi_to_axilite_bridge` to `aes_core_top`, `axi_uart_top`, `axi_timer_top`, `axi_gpio_top`, and `axi_sha256_top`.
- **Slave `m05`:** On-chip **64 KB AXI4 SRAM** (`rtl/mem/axi_sram.v`) mapped at `0x0000_0000–0x0000_FFFF`, supporting full AXI4 bursts (`FIXED`/`INCR`/`WRAP`) and byte strobes (`WSTRB`) for DMA and master transfers.

### 2.2 Architectural Alignment Note

> Earlier documentation referenced an APB control plane. The SoC standardizes **AXI4-Lite** as the unified control interface for the AES accelerator and all sibling peripherals.

---

## 3. Implementation & Verification Status

| Feature / Subsystem | Status | Implementation & Verification Notes |
|---|---|---|
| Top-level integration (`rtl/soc_top.v`) | Implemented & Verified | 2×6 crossbar, `USE_INTERNAL_CPU` mux, 5 AXI4-Lite bridges, 64 KB SRAM (`m05`), DMA master `s01`, `pic_ext_irqs[8:1]` |
| AXI4 2×6 crossbar (`axi_interconnect_wrap_2x6.v`) | Implemented & Verified | Parameterized 2-master × 6-slave Forencich AXI4 crossbar (`m00`–`m04` 4 KB, `m05` 64 KB) |
| On-chip SRAM (`rtl/mem/axi_sram.v`) | Implemented & Verified | Full AXI4 64 KB SRAM (`0x0000_0000–0x0000_FFFF`) supporting byte strobes and bursts |
| Peripheral UVM Top (`tb/tb_periph_top.sv` + `run/run_periph_vip.f`) | Implemented & Verified | Isolated UVM-1.2 top running all 6 peripheral VIP tests (`30 / 30 PASS`, `4,555 / 4,555` checks, `0` warnings/errors/fatals) |
| 6 Peripheral UVM-1.2 VIPs (`tb/*_vip_uvm_tb/`) | Implemented & Verified | Complete `item`/`seqr`/`drv`/`mon`/`agent`/`sb`/`env`/`test` architectures for UART, Timer, GPIO, SHA-256, AES-256, and AXI DMA |
| Functional Coverage (`tb/soc_cov_pkg.sv`, `soc_cov_collector.sv`) | **100.00% (`29 / 29` CGs)** | `18` VIP scoreboard covergroups + `11` SoC monitor covergroups merged to `100.00%` |
| UART (`rtl/uart/`) | Verified (`6/6`) | AXI4-Lite 16-entry FIFOs (`FIFO_THRESHOLD=1`), LSR sticky `OE`/`PE`/`FE` error bits, `97.76%` RTL Stmt cov |
| System Timer (`rtl/timer/`) | Verified (`3/3`) | OpenTitan-style `rv_timer` (`N=1`), prescale/step rollover, `INTR_TEST`/`RW1C`, `100.00%` RTL Stmt cov |
| 64-pin GPIO (`rtl/gpio/`) | Verified (`5/5`) | 64 pins, atomic `SET`/`CLR`/`TGL`, 2-stage input sync, `RISE`/`FALL`/`HIGH`/`LOW` IRQs, `100.00%` RTL Stmt cov |
| SHA-256 (`rtl/sha/`) | Verified (`5/5`) | Secworks SHA-256 & SHA-224 (`INIT`/`NEXT` chaining, `BLOCK0..15`, IRQ), `100.00%` RTL Stmt cov |
| AES-256 (`rtl/aes/`) | Verified (`6/6`) | Fixed multi-block (`total_blocks`), parallel 256-bit key load, IV latch (`iv_written`), CBC-decrypt `dout_hold_r`, CTR (`use_enc_core`), `98.90%` RTL Stmt cov |
| AXI DMA (`rtl/dma/`) | Verified (`5/5`) | Dual descriptors, SRAM/peripheral targets, tails, abort & bus-fault IRQs (`arvalid` FIFO guard & SV enum fixes), `84.15%` RTL Stmt cov |
| VeeR EL2 CPU (`rtl/Cores-VeeR-EL2/`, `rtl/veer_core_top.sv`) | Integrated | Bundled in `rtl/Cores-VeeR-EL2/` for `USE_INTERNAL_CPU=1` (`tb/tb_soc_veer_cpu.sv`); peripheral VIPs run with `USE_INTERNAL_CPU=0` |

---

## 4. SoC Address Map & Interrupts

Verified from [`rtl/soc_top.v`](rtl/soc_top.v) and [`c_test/soc_regs.h`](c_test/soc_regs.h):

### 4.1 Crossbar Slave Windows (`axi_interconnect_wrap_2x6`)

| Port | Target | Module | Base Address | End Address | Interface / Window |
|---|---|---|---|---|---|
| `m00` | AES-256 Engine | `aes_core_top` | `0x4000_0000` | `0x4000_0FFF` | AXI4-Lite (`S_ADDR_WIDTH=8`), 4 KB |
| `m01` | UART | `axi_uart_top` | `0x4000_1000` | `0x4000_1FFF` | AXI4-Lite (`S_ADDR_WIDTH=8`), 4 KB |
| `m02` | System Timer | `axi_timer_top` | `0x4000_2000` | `0x4000_2FFF` | AXI4-Lite (`S_ADDR_WIDTH=12`), 4 KB |
| `m03` | 64-Pin GPIO | `axi_gpio_top` | `0x4000_3000` | `0x4000_3FFF` | AXI4-Lite (`S_ADDR_WIDTH=12`), 4 KB |
| `m04` | SHA-256 Engine | `axi_sha256_top` | `0x4000_4000` | `0x4000_4FFF` | AXI4-Lite (`S_ADDR_WIDTH=12`), 4 KB |
| `m05` | System SRAM (64 KB) | `axi_sram` | `0x0000_0000` | `0x0000_FFFF` | Native AXI4 (`ADDR_WIDTH=16`), 64 KB |

> **DMA CSR Port:** `dma_axi_top` connects as AXI4 master `s01` on `axi_interconnect_wrap_2x6`; its AXI4-Lite CSR configuration slave (`dma_csr_*`) is exported on `soc_top` and mapped in testbench BFM space (`bus_vif` / `tb_soc_c_test.sv`) at base `0x4000_5000`.

### 4.2 Interrupt Mapping (`pic_ext_irqs[8:1]`)

| VeeR PIC Line | SoC Source Signal | Description |
|---|---|---|
| `pic_ext_irqs[1]` | `uart_irq` | UART RX/TX/Line Error interrupt from `axi_uart_top` |
| `pic_ext_irqs[2]` | `timer_irq` | System Timer expiration interrupt from `axi_timer_top` |
| `pic_ext_irqs[3]` | `aes_irq` | AES interrupt (`ctrl_irq_en & (status_done \| status_err)`) |
| `pic_ext_irqs[4]` | `sha_irq` | SHA-256 interrupt from `axi_sha256_top` |
| `pic_ext_irqs[5]` | `dma_done` | DMA transfer completion interrupt from `dma_axi_top` |
| `pic_ext_irqs[6]` | `dma_error` | DMA AXI bus error interrupt from `dma_axi_top` |
| `pic_ext_irqs[7]` | `gpio_intr[0]` | Lower 32-pin GPIO bank interrupt (`\|reg_status_0`) |
| `pic_ext_irqs[8]` | `gpio_intr[1]` | Upper 32-pin GPIO bank interrupt (`\|reg_status_1`) |

---

## 5. Subsystems & Verification IPs

### 5.1 Peripheral UVM-1.2 VIPs & Coverage Environment

[`tb/tb_periph_top.sv`](tb/tb_periph_top.sv) instantiates `soc_top #(.USE_INTERNAL_CPU(0))`, the shared AXI4 + DMA CSR BFM [`tb/soc_axi_if.sv`](tb/soc_axi_if.sv), the SoC coverage collector ([`tb/soc_cov_collector.sv`](tb/soc_cov_collector.sv), [`tb/soc_cov_pkg.sv`](tb/soc_cov_pkg.sv)), and all six modular UVM-1.2 VIPs:

- **UART UVM VIP ([`tb/uart_vip_uvm_tb/`](tb/uart_vip_uvm_tb/)):** Covers `TC_UART_01`–`TC_UART_06` (reset/DLAB gating, 8N1/8E2/8O2 TX & RX, RX data-available IRQ, 16-byte FIFO burst stress & simultaneous push+pull, and `FE`/`PE`/`OE` LSR error injection).
- **Timer UVM VIP ([`tb/timer_vip_uvm_tb/`](tb/timer_vip_uvm_tb/)):** Covers `TC_TMR_01`–`TC_TMR_03` (prescale/step rollover, compare-match IRQ, `RW1C` & `INTR_TEST0` decode).
- **GPIO UVM VIP ([`tb/gpio_vip_uvm_tb/`](tb/gpio_vip_uvm_tb/)):** Covers `TC_GPIO_01`–`TC_GPIO_05` (`GPIO_INFO=64`, Bank 0/1 OE & output drive, 2-stage synchronizer capture, atomic `SET`/`CLR`/`TGL`, and `RISE`/`FALL`/`HIGH`/`LOW` IRQs).
- **SHA-256 UVM VIP ([`tb/sha_vip_uvm_tb/`](tb/sha_vip_uvm_tb/)):** Covers `TC_SHA_01`–`TC_SHA_05` (ID registers, NIST `'abc'` single-block digest, `INIT`+`NEXT` multi-block chaining, `BUSY`/IRQ + SHA-224, `BLOCK0..15` walk/toggle & backpressure).
- **AES-256 UVM VIP ([`tb/aes_vip_uvm_tb/`](tb/aes_vip_uvm_tb/)):** Covers `TC_AES_01`–`TC_AES_06` (WO security & decode, AES-128/256 key expansion, ECB encrypt/decrypt, CBC 2-block encrypt/decrypt, CTR encrypt/decrypt, IRQ `W1C`).
- **AXI DMA UVM VIP ([`tb/dma_vip_uvm_tb/`](tb/dma_vip_uvm_tb/)):** Covers `TC_DMA_01`–`TC_DMA_05` (`0xCAFE` CSR ID & strobes, 256 B SRAM-to-SRAM AXI4 bursts & concurrent R/W, dual/DESC1 chaining, fixed-address & all-slave routing, unaligned tails/abort, bus-fault trap & `dma_error_o`).

> Full unified DPI-C + boundary VIP SoC testbenches remain available in [`tb/tb_top.sv`](tb/tb_top.sv), [`tb/tb_soc_c_test.sv`](tb/tb_soc_c_test.sv), and [`tb/tb_soc_veer_cpu.sv`](tb/tb_soc_veer_cpu.sv).

### 5.2 Cryptographic & Peripheral RTL Subsystems

- **AES-256 (`rtl/aes/`):** `aes_core_top.v`, `aes_regfile.v`, `aes_cipher_top.v`, `aes_inv_cipher_top.v`, `aes_key_expand_256.v`, `aes_key_expand_128.v`, `aes_sbox.v`, `aes_inv_sbox.v`, `aes_rcon.v`.
- **SHA-256 (`rtl/sha/`):** `axi_sha256_top.v` wrapping `sha256.v`, `sha256_core.v`, `sha256_w_mem.v`, `sha256_k_constants.v`.
- **UART (`rtl/uart/`):** `axi_uart_top.v`, `uart_controller.v`, `uart_transmitter.v`, `uart_receiver.v`, `uart_parity_bit_compute.v`, `axi_internal_fifo.v`.
- **System Timer (`rtl/timer/`):** `axi_timer_top.v`, `timer_core.sv` (`rv_timer`, `N=1`).
- **64-Pin GPIO (`rtl/gpio/`):** `axi_gpio_top.v`.
- **DMA (`rtl/dma/`):** `dma_axi_top.sv`, `dma_axi_wrapper.sv`, `dma_func_wrapper.sv`, `dma_fsm.sv`, `dma_streamer.sv`, `dma_fifo.sv`, `dma_axi_if.sv`, `csr_dma.v`, `rggen_*.v`, and `rtl/dma/inc/{amba_axi_pkg.sv, dma_pkg.svh, dma_utils_pkg.sv}`.
- **Memory & Interconnect (`rtl/mem/`, `rtl/interconnect/`):** `axi_sram.v`, `axi_interconnect_wrap_2x6.v`, `axi_interconnect.v`, `axi_to_axilite_bridge.v`, `arbiter.v`, `priority_encoder.v`.

---

## 6. Repository Structure

```text
RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/
├── c_test/
│   ├── soc_regs.h                         # Unified peripheral & DMA CSR register definitions
│   ├── soc_test.c / soc_test.h            # DPI-C system firmware test suite (soc_c_main)
├── doc/
│   ├── Project_spec.odt / description.md / aes.pdf
│   ├── csv files/{aes,dma,gpio,sha,timer,uart}/  # Per-IP signal spreadsheets
│   └── testplan/
│       ├── Cryptographic_Telemetry_Gateway_SoC_Testplan.{md,xlsx}
│       ├── Coverage_Report.md             # Verified peripheral UVM & RTL coverage report
│       └── Coverage_Report.pdf            # 4-page PDF verification & coverage report
├── rtl/
│   ├── soc_top.v                          # Top-level SoC wrapper (2x6 crossbar + SRAM + CPU/DMA)
│   ├── veer_core_top.sv                   # VeeR EL2 CPU & memory wrapper
│   ├── Cores-VeeR-EL2/                    # Integrated CHIPS Alliance VeeR EL2 RTL core
│   ├── interconnect/                      # axi_interconnect_wrap_2x6, axi_interconnect, axi_to_axilite_bridge
│   ├── mem/axi_sram.v                     # 64 KB full AXI4 on-chip SRAM
│   ├── aes/                               # AES-256 core & AXI4-Lite regfile
│   ├── sha/                               # SHA-256 / SHA-224 core & AXI4-Lite wrapper
│   ├── uart/                              # 16550-style AXI4-Lite UART + 16B TX/RX FIFOs
│   ├── timer/                             # OpenTitan-style rv_timer + AXI4-Lite wrapper
│   ├── gpio/                              # 64-pin GPIO controller with bank IRQs
│   └── dma/                               # Dual-descriptor AXI4 DMA + rggen CSR + inc/ packages
├── run/
│   ├── run_periph_vip.f                   # Clean 6-peripheral UVM-1.2 filelist (tb_periph_top.sv)
│   ├── run_vip.f                          # Unified SoC + DPI-C + VIP filelist (tb_top.sv)
│   ├── run_c_test.f / run.f / tb_top.f    # Standalone DPI-C & VCS SoC filelists
├── scripts/
│   ├── compile_and_run_vivado.sh          # Vivado UVM-1.2, CPU, C-test & coverage runner
│   ├── compile_and_run_{vips,c_test,soc,soc_cpu,hex_sim}.sh
│   ├── uvm_testbench_generator_v2.py      # UVM skeleton generator from signal CSVs
│   └── axi_interconnect_wrap.py / generate_soc_testplan.py / generate_soc_hex.py
└── tb/
    ├── tb_periph_top.sv                   # Clean 6-peripheral UVM-1.2 verification top
    ├── soc_axi_if.sv                      # Shared AXI4 master + DMA CSR BFM interface
    ├── soc_cov_pkg.sv / soc_cov_collector.sv / soc_cov_inst.svh  # 11 SoC covergroups
    ├── {uart,timer,gpio,sha,aes,dma}_vip_uvm_tb/  # Complete UVM-1.2 VIPs (10 files each)
    ├── tb_top.sv                          # Legacy unified SoC UVM + DPI-C testbench
    ├── tb_soc_c_test.sv                   # Standalone DPI-C SoC testbench
    └── tb_soc_veer_cpu.sv                 # VeeR EL2 hardware boot & execution testbench
```

---

## 7. Verification Results & Simulation Instructions

### 7.1 Peripheral UVM-1.2 Verification & Coverage Summary

Verified across all 6 peripheral VIPs on [`tb/tb_periph_top.sv`](tb/tb_periph_top.sv) (`TC_BOOT`, `TC_BUS`, and `TC_PIPE` excluded as CPU/SoC-internal scope; full details in [`doc/testplan/Coverage_Report.md`](doc/testplan/Coverage_Report.md) and [`doc/testplan/Coverage_Report.pdf`](doc/testplan/Coverage_Report.pdf)):

- **Testplan Pass Rate:** **`30 / 30 PASS`** (`0` Failures, **`0`** `UVM_WARNING` / `UVM_ERROR` / `UVM_FATAL`)
- **Scoreboard Checks Passed:** **`4,555 / 4,555`** (`0` Mismatches)
- **Merged Functional Coverage:** **`100.00%`** (`29 / 29` covergroups — `18` VIP scoreboard CGs + `11` SoC monitor CGs; `234 / 234` scoreboard feature paths)
- **Peripheral RTL Code Coverage (`34` files):** **`93.57%`** weighted Statement Coverage · **`82.04%`** average Branch Coverage (`94.67%` Statement across all `76` simulation files)

| Peripheral | Testplan Cases | Scoreboard Checks | Functional Coverage | RTL Statement Coverage | RTL Avg Branch Coverage |
|---|---|---:|---:|---:|---:|
| **UART** | `TC_UART_01`–`06` (`6/6 PASS`) | 1,201 | **100.00%** | 97.76% | 88.24% |
| **Timer** | `TC_TMR_01`–`03` (`3/3 PASS`) | 64 | **100.00%** | **100.00%** | 94.74% |
| **GPIO** | `TC_GPIO_01`–`05` (`5/5 PASS`) | 137 | **100.00%** | **100.00%** | 92.73% |
| **SHA-256** | `TC_SHA_01`–`05` (`5/5 PASS`) | 247 | **100.00%** | **100.00%** | 94.89% |
| **AES-256** | `TC_AES_01`–`06` (`6/6 PASS`) | 301 | **100.00%** | 98.90% | 94.91% |
| **AXI DMA** | `TC_DMA_01`–`05` (`5/5 PASS`) | 2,605 | **100.00%** | 84.15% | 61.99% |

### 7.2 Running Peripheral UVM-1.2 Suites & Coverage (`compile_and_run_vivado.sh`)

Run from the **repository root**:

```bash
export PATH="/home/mourya/Vivado/Vivado/2023.2/bin:$PATH"

# Run all 6 peripheral VIPs + collect merged functional & code coverage summaries
bash scripts/compile_and_run_vivado.sh coverage

# Or run all 6 peripheral VIPs without coverage overhead
bash scripts/compile_and_run_vivado.sh vip

# Or run a single peripheral VIP test
bash scripts/compile_and_run_vivado.sh vip uart_vip_test
bash scripts/compile_and_run_vivado.sh vip aes_vip_test
```

Coverage text reports and scoreboard logs are generated under `run/coverage/` (`xcrg_func_cov_report.txt`, `xcrg_periph_cc.txt`, `xcrg_code_cov_summary.txt`) and `run/vivado_vip_test/xsim_*_vip_test.log` (both directories are gitignored).

### 7.3 Legacy Synopsys VCS / Verdi Flows

```bash
cd run

# Unified SoC + DPI-C + VIP build
vcs -full64 -ntb_opts uvm -debug_access+all -kdb -f run_vip.f -o simv_soc_vips
./simv_soc_vips +UVM_TESTNAME=soc_vip_test +UVM_NO_RELNOTES

# Standalone DPI-C SoC C suite
vcs -full64 -kdb +define+FSDB -f run_c_test.f -o simv_soc_c_test
./simv_soc_c_test +VCD_FILE=soc_c_test.vcd
```

---

## 8. Notes on Design & Coverage Scope

1. **Resolved Peripheral Fixes:** Multi-block AES (`total_blocks`), parallel 256-bit key load, IV latching (`iv_written`), CBC-decrypt `dout_hold_r` capture, CTR forward-cipher path (`use_enc_core`), UART `FIFO_THRESHOLD=1`, UART sticky `LSR` error flags, and DMA `arvalid` FIFO/outstanding-read gating have all been implemented and verified.
2. **SHA-256 IRQ Behavior (`rtl/sha/axi_sha256_top.v`):** `digest_valid_reg` (`sha_irq`) updates on `STATUS` (`0x24`) reads and clears on `INIT` (`0x20`).
3. **Unreachable RTL Coverage Margin:** The remaining uncovered code-coverage lines (`6.43%` across peripheral RTL) correspond to structurally unreachable or parameterized paths (`ST_KEY_LOAD2/WAIT2` unused by the parallel 256-bit AES core, defensive FIFO/FSM `default:` arms in UART, parameterized `DMA_DATA_WIDTH==64`/`SLOTS==1`/unused `rggen_*` modes in DMA).

---

## 9. Documentation & References

- Testplan & Verification Reports: [`doc/testplan/Cryptographic_Telemetry_Gateway_SoC_Testplan.md`](doc/testplan/Cryptographic_Telemetry_Gateway_SoC_Testplan.md), [`doc/testplan/Coverage_Report.md`](doc/testplan/Coverage_Report.md), and [`doc/testplan/Coverage_Report.pdf`](doc/testplan/Coverage_Report.pdf).
- Specifications & Signal CSVs: [`doc/Project_spec.odt`](doc/Project_spec.odt), [`doc/description.md`](doc/description.md), [`doc/aes.pdf`](doc/aes.pdf), and [`doc/csv files/`](doc/csv%20files/).
- Underlying IP baselines: Alex Forencich `verilog-axi`, Secworks `sha256`, OpenTitan `rv_timer`, Anderson Ignacio `rggen`/AXI4 DMA, Rudolf Usselmann AES/Rijndael IP Core, CHIPS Alliance VeeR EL2.

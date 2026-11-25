# RISC-V Based Cryptographic Telemetry Gateway SoC
### with AES-256 and SHA-256 Engines

> **Honours Project — RTL Design & Verification**  
> Simulation environment: Synopsys VCS `U-2023.03` / Verdi · Languages: SystemVerilog / Verilog / DPI-C

---

## 1. Overview & Motivation

Telemetry gateways deployed in embedded, industrial, and edge environments require low-latency hardware acceleration for data confidentiality and integrity alongside deterministic control over serial, timer, and general-purpose I/O interfaces. Relying on software alone for symmetric block encryption (AES-256) and cryptographic hashing (SHA-256) consumes significant CPU cycles and limits sustainable telemetry throughput.

This repository implements the RTL integration, memory-mapped AXI4 / AXI4-Lite fabric, cryptographic and peripheral subsystems, SystemVerilog testbenches, and DPI-C verification tests for a **RISC-V Based Cryptographic Telemetry Gateway SoC**.

### Key Objectives

- Integrate an **AES-256** engine (`aes_core_top` with `aes_key_expand_256`) and a **SHA-256** engine (`axi_sha256_top`) behind uniform 32-bit AXI4-Lite register interfaces.
- Provide a unified **AXI4 2-master × 5-slave crossbar** (`axi_interconnect_wrap_2x5`) with combinational `axi_to_axilite_bridge` instances for all peripherals.
- Support dual control-master integration on `soc_top`: either the **VeeR EL2** CPU wrapper (`veer_core_top`, `USE_INTERNAL_CPU=1`) or an external verification master (`ext_s00_axi_*`, `USE_INTERNAL_CPU=0`), alongside an **AXI4 DMA controller** (`dma_axi_top`) on master port `s01`.
- Verify subsystem and top-level integration using both native SystemVerilog (`tb/tb_soc_top.sv`) and DPI-C (`tb/tb_soc_c_test.sv` + `c_test/soc_test.c`) test suites under Synopsys VCS.

---

## 2. System Architecture

### 2.1 SoC Block Diagram (Intended vs. Integrated Top)

The control path defines how the VeeR EL2 core orchestrates system operations across the unified AXI4/AXI4-Lite interconnect architecture:

```text
+-------------------------------------------------------------------------+
|                    Intended SoC Architecture (Spec)                     |
+-------------------------------------------------------------------------+
|                                                                         |
|   +-----------------------+              +--------------------------+   |
|   |  VeeR EL2 RISC-V Core | (M0)         |   AXI4 DMA Controller    |   |
|   |  (rtl/veer_core_top)  |---+      +---|   (rtl/dma/dma_axi_top)  |   |
|   +-----------------------+   |      |   +--------------------------+   |
|                               v      v (M1)                             |
|                    +----------------------------+                       |
|                    |   AXI4 Crossbar Fabric     |                       |
|                    +----------------------------+                       |
|                       |    |    |    |    |    |                        |
|      +----------------+    |    |    |    |    +--------------+         |
|      v                     v    v    v    v                   v         |
|  [AXI-Lite Bridges]      [AXI4 Memory / Subsystem Targets]              |
|   |   |   |   |   |        * System SRAM / Boot IMEM (planned)          |
|   v   v   v   v   v                                                     |
|  AES UART TMR GPIO SHA-256                                              |
+-------------------------------------------------------------------------+
```

In the **current integrated RTL** ([`rtl/soc_top.v`](rtl/soc_top.v)), `soc_top` parameterizes `#(USE_INTERNAL_CPU=1, AXI_DATA_WIDTH=32, AXI_ADDR_WIDTH=32, AXI_ID_WIDTH=8)` over an `axi_interconnect_wrap_2x5` fabric:

- **Master `s00`**: Multiplexed by `USE_INTERNAL_CPU`:
  - `1`: `veer_core_top` (`rtl/veer_core_top.sv`) with inline 64-to-32-bit LSU width steering.
  - `0`: External AXI4 master port `ext_s00_axi_*` (used by `tb_soc_top.sv` and `tb_soc_c_test.sv`).
- **Master `s01`**: `dma_axi_top` (`rtl/dma/dma_axi_top.sv`) AXI4 master interface (`DMA_NUM_DESC=2`, `AXI_DATA_WIDTH=32`, `AXI_TXN_ID_WIDTH=8`). Its AXI4-Lite CSR slave (`dma_csr_*`) is exposed directly on `soc_top` top-level pins (tied off to `0` in current SoC testbenches).
- **Slaves `m00`–`m04`**: Five 4 KB (`12`-bit) windows bridged via `axi_to_axilite_bridge` to `aes_core_top`, `axi_uart_top`, `axi_timer_top`, `axi_gpio_top`, and `axi_sha256_top`.

### 2.2 Architectural Alignment Note

> Earlier documentation and legacy baseline assumptions referenced an APB control plane. The updated architecture establishes **AXI4-Lite** as the unified control interface for the AES core and all peripherals, aligning directly with the AXI4-Lite register file already implemented in [`rtl/aes/aes_regfile.v`](rtl/aes/aes_regfile.v) and all four sibling peripheral wrappers.

---

## 3. Current Implementation Status

| Feature / Subsystem | Status | Implementation & Verification Notes |
|---|---|---|
| Top-level integration (`rtl/soc_top.v`) | Implemented | Integrates 2×5 crossbar, `USE_INTERNAL_CPU` mux, 5 AXI4-Lite bridges, DMA master `s01`, and `pic_ext_irqs[8:1]` |
| AXI4 2×5 crossbar (`axi_interconnect_wrap_2x5.v`) | Implemented | Parameterized 2-master × 5-slave Forencich AXI4 wrapper (`m00`–`m04`, 4 KB each) |
| AXI4-to-AXI4-Lite bridge (`axi_to_axilite_bridge.v`) | Implemented | Combinational burst-stripping bridge instantiated per slave (`S_ADDR_WIDTH=8` or `12`) |
| UART (`rtl/uart/axi_uart_top.v`, `axi_internal_fifo.v`) | Implemented | AXI4-Lite 16-entry TX/RX FIFO UART; tested in `tb_axi_uart_top.sv`, `tb_soc_top.sv`, and `c_test/soc_test.c` (note FIFO threshold truncation bug in Section 8) |
| System Timer (`rtl/timer/axi_timer_top.v`, `timer_core.sv`) | Implemented | OpenTitan-style `rv_timer` (`N=1`) with 64-bit `mtime`/`mtimecmp` and `timer_irq` |
| 64-pin GPIO (`rtl/gpio/axi_gpio_top.v`) | Implemented | 64 pins, atomic SET/CLEAR/TOGGLE writes, edge/level IRQs (`gpio_intr_o[1:0]`) |
| SHA-256 accelerator (`rtl/sha/axi_sha256_top.v`, `sha256.v`, `sha256_core.v`) | Implemented | Secworks SHA-256 wrapped on AXI4-Lite (`0x4000_4000`); see `STATUS`-read IRQ caveat in Section 8 |
| AES-256 accelerator (`rtl/aes/`) | Partial / Bugs Open | Cipher cores instantiate `aes_key_expand_256` (256-bit key), but `aes_core_top.v` retains multi-block, key-load, IV, and CBC-decrypt bugs (Section 8) |
| DMA controller (`rtl/dma/dma_axi_top.sv`) | Integrated (Untested at SoC) | Master wired to `s01` (`DMA_NUM_DESC=2`); `dma_csr_*` brought to `soc_top` pins and tied to `0` in current SoC testbenches |
| VeeR EL2 wrapper (`rtl/veer_core_top.sv`) | Wrapper Only | Wrapper exists in repo (`USE_INTERNAL_CPU=1`), but upstream CHIPS Alliance EL2 core RTL/packages/headers/RAMs are not bundled; SoC sims run with `USE_INTERNAL_CPU=0` |
| AXI System SRAM / DMA target memory | Not Implemented | No RAM slave is attached to `axi_interconnect_wrap_2x5` (`soc_top` currently has only the 5 peripheral slaves `m00`–`m04`) |
| Directed & DPI-C SoC verification | Implemented | `tb/tb_soc_top.sv` (15 directed tests) + `tb/tb_soc_c_test.sv` & `c_test/soc_test.c` (`soc_c_main`) |
| UVM environment & VIPs | Not in Repository | No UVM package, agents, scoreboards, or VIP CSV/interface files are currently present in this repo |

---

## 4. SoC Address Map & Interrupts

Verified directly from [`rtl/soc_top.v`](rtl/soc_top.v):

### 4.1 Crossbar Slave Windows (`axi_interconnect_wrap_2x5`)

| Port | Peripheral | Module | Base Address | End Address | Bridge `S_ADDR_WIDTH` |
|---|---|---|---|---|---|
| `m00` | AES-256 Engine | `aes_core_top` | `0x4000_0000` | `0x4000_0FFF` | `8` |
| `m01` | UART | `axi_uart_top` | `0x4000_1000` | `0x4000_1FFF` | `8` |
| `m02` | System Timer | `axi_timer_top` | `0x4000_2000` | `0x4000_2FFF` | `12` |
| `m03` | 64-Pin GPIO | `axi_gpio_top` | `0x4000_3000` | `0x4000_3FFF` | `12` |
| `m04` | SHA-256 Engine | `axi_sha256_top` | `0x4000_4000` | `0x4000_4FFF` | `12` |

> **DMA CSR Port Note:** `dma_axi_top` is master `s01` on the crossbar, while its AXI4-Lite configuration slave (`dma_csr_*`) is exported as external top-level ports on `soc_top` rather than mapped into `m00`–`m04`.

### 4.2 Interrupt Mapping (`pic_ext_irqs[8:1]`)

| VeeR PIC Line | SoC Source Signal | Notes |
|---|---|---|
| `pic_ext_irqs[1]` | `uart_irq` | UART interrupt from `axi_uart_top` |
| `pic_ext_irqs[2]` | `timer_irq` | Timer interrupt from `axi_timer_top` (also wired to `u_cpu.timer_int`) |
| `pic_ext_irqs[3]` | `aes_irq` | AES interrupt (`ctrl_irq_en & (status_done \| status_err)`) |
| `pic_ext_irqs[4]` | `sha_irq` | SHA-256 interrupt from `axi_sha256_top` |
| `pic_ext_irqs[5]` | `dma_done` | DMA completion interrupt from `dma_axi_top` |
| `pic_ext_irqs[6]` | `dma_error` | DMA error interrupt from `dma_axi_top` |
| `pic_ext_irqs[7]` | `gpio_intr[0]` | Lower 32-pin GPIO bank interrupt (`\|reg_status_0`) |
| `pic_ext_irqs[8]` | `gpio_intr[1]` | Upper 32-pin GPIO bank interrupt (`\|reg_status_1`) |

---

## 5. Subsystem Overview

### 5.1 AES-256 Accelerator (`rtl/aes/`)

- **Cipher & Key Expansion:** `aes_cipher_top.v` and `aes_inv_cipher_top.v` instantiate `aes_key_expand_256` (`rtl/aes/aes_key_expand_256.v`) taking a 256-bit `key[255:0]` input. (`aes_key_expand_128.v` and the original Rev. 1.1 `doc/aes.pdf` baseline datasheet remain in the repository for reference.)
- **AXI4-Lite Register Map (`rtl/aes/aes_regfile.v`, byte offsets `0x00`–`0x5C`):**
  - `0x00` `AES_CTRL` (RW): `[0]` `START` (self-clearing, reads `0`), `[1]` `IRQ_EN`, `[2]` `DECRYPT`, `[4:3]` `KEY_SIZE`, `[5]` `MODE_CBC`, `[6]` `MODE_CTR`, `[7]` `SOFT_RST` (self-clearing)
  - `0x04` `AES_STATUS` (RO/W1C): `[0]` `BUSY` (RO), `[1]` `DONE` (W1C), `[2]` `KEY_READY` (W1C), `[3]` `ERR` (W1C)
  - `0x08` `AES_BLK_CNT`: `[15:0]` `TOTAL_BLOCKS` (RW), `[31:16]` `DONE_BLOCKS` (RO)
  - `0x0C` `AES_IRQ_CLR` (WO/W1C, reads `0`): `[0]` clears `status_done`, `[1]` clears `status_err`
  - `0x10–0x2C` `KEY[0..7]` (`key_data[255:0]`, WO — reads return `0`)
  - `0x30–0x3C` `IV[0..3]` (`iv_data[127:0]`, RW)
  - `0x40–0x4C` `DIN[0..3]` (`din_data[127:0]`, WO — reads return `0`)
  - `0x50–0x5C` `DOUT[0..3]` (`dout_data[127:0]`, RO)

### 5.2 SHA-256 Accelerator (`rtl/sha/`)

- `axi_sha256_top.v` wraps Secworks `sha256.v` / `sha256_core.v` on AXI4-Lite (`m04` at `0x4000_4000`).
- Includes identification registers (`NAME0="sha2"`, `NAME1="-256"`, `VERSION="1.80"`), `CTRL` (`0x20`), `STATUS` (`0x24`), 512-bit input block registers `BLOCK0–15` (`0x40–0x7C`), and 256-bit digest output registers `DIGEST0–7` (`0x80–0x9C`).

### 5.3 UART, System Timer, GPIO & DMA

- **UART (`rtl/uart/`):** `axi_uart_top.v` + `axi_internal_fifo.v` provide 16-entry TX/RX FIFOs and configurable baud divisor over AXI4-Lite (`m01` at `0x4000_1000`).
- **System Timer (`rtl/timer/`):** `axi_timer_top.v` wraps `timer_core.sv` (`rv_timer`, `N=1`) across `0x000–0x11C` (including `mtime` at `0x110`/`0x114` and `mtimecmp` at `0x118`/`0x11C`), generating `timer_irq = reg_intr_en & reg_intr_state` (`m02` at `0x4000_2000`).
- **GPIO (`rtl/gpio/`):** `axi_gpio_top.v` implements 64 configurable I/O pins (`0x000` `GPIO_INFO=64`, `0x004` `cfg`, `0x008` `mode`, `0x080–0x084` direction/enable, `0x100–0x104` inputs, `0x180–0x184` outputs + atomic SET/CLEAR/TOGGLE writes, `0x380–0x504` rise/fall/high/low interrupt enables, `0x580–0x584` status) (`m03` at `0x4000_3000`).
- **DMA (`rtl/dma/`):** `dma_axi_top.sv` (`dma_axi_wrapper.sv`, `dma_func_wrapper.sv`, `dma_fsm.sv`, `csr_dma.v`, and `rtl/dma/inc/{dma_utils_pkg.sv, dma_pkg.svh, amba_axi_pkg.sv}`) provides a 2-descriptor (`DMA_NUM_DESC=2`) AXI4 master on `s01` with external `dma_csr_*` AXI4-Lite slave pins and `dma_done`/`dma_error` IRQs.

### 5.4 VeeR EL2 Wrapper (`rtl/veer_core_top.sv`)

- Instantiates `el2_veer_wrapper`, `el2_mem_if`, `ram_4096x39` (DCCM/ICCM), `ram_be_512x142`, `ram_be_128x52`, and optional `axi_slv` (`BOOT_IMEM_ENABLE=1`), requiring `common_defines.vh`, `el2_param.vh`, and `el2_pkg`.
- Because those external CHIPS Alliance VeeR EL2 RTL/package/header/RAM sources are not included in this repository, simulation targets currently set `USE_INTERNAL_CPU(0)` and drive `ext_s00_axi_*`.

---

## 6. Repository Structure

```text
RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/
├── c_test/
│   ├── soc_regs.h                     # C register definitions for 0x4000_0000–0x4000_4FFF
│   ├── soc_test.c                     # DPI-C system test sequence (soc_c_main: UART, GPIO, Timer, SHA-256, AES-256)
│   └── soc_test.h                     # DPI-C import/export declarations
├── doc/
│   ├── Project_spec.odt               # Project architecture specification document
│   ├── aes.pdf                        # Original Rudolf Usselmann AES IP Core Rev 1.1 datasheet
│   └── description.md                 # Design notes
├── rtl/
│   ├── soc_top.v                      # Top-level SoC wrapper (2x5 crossbar + CPU/DMA + 5 slaves)
│   ├── veer_core_top.sv               # VeeR EL2 CPU & memory wrapper (requires external EL2 core files)
│   ├── interconnect/
│   │   ├── axi_interconnect_wrap_2x5.v
│   │   └── axi_to_axilite_bridge.v
│   ├── aes/
│   │   ├── aes_core_top.v
│   │   ├── aes_regfile.v
│   │   ├── aes_axi_slave.v
│   │   ├── aes_cipher_top.v
│   │   ├── aes_inv_cipher_top.v
│   │   ├── aes_key_expand_256.v
│   │   └── aes_key_expand_128.v       # Legacy 128-bit key expansion module
│   ├── sha/
│   │   ├── axi_sha256_top.v
│   │   ├── sha256.v
│   │   └── sha256_core.v
│   ├── uart/
│   │   ├── axi_uart_top.v
│   │   └── axi_internal_fifo.v
│   ├── timer/
│   │   ├── axi_timer_top.v
│   │   └── timer_core.sv
│   ├── gpio/
│   │   └── axi_gpio_top.v
│   └── dma/
│       ├── dma_axi_top.sv
│       ├── dma_axi_wrapper.sv
│       ├── dma_func_wrapper.sv
│       ├── dma_fsm.sv
│       ├── csr_dma.v
│       └── inc/
│           ├── amba_axi_pkg.sv
│           ├── dma_pkg.svh
│           └── dma_utils_pkg.sv
├── run/
│   ├── run_c_test.f                   # Primary VCS filelist for DPI-C SoC verification (tb_soc_c_test.sv + soc_test.c)
│   ├── run.f                          # Stale SoC filelist (points to missing ../rtl/interconnect/soc_top.v)
│   ├── run_integrated_soc.f           # Legacy partial filelist (references axi_interconnect_wrap_2x10)
│   ├── run1.f
│   └── run2.f
├── scripts/
│   └── axi_interconnect_wrap.py       # Crossbar wrapper helper script
└── tb/
    ├── tb_soc_c_test.sv               # SoC DPI-C testbench (USE_INTERNAL_CPU=0, calls soc_c_main)
    ├── tb_soc_top.sv                  # Standalone 15-test SV SoC testbench (USE_INTERNAL_CPU=0, 50 MHz, BAUD_DIV=434)
    ├── tb_axi_uart_top.sv             # Block-level UART testbench (12 tests, FSDB dump)
    ├── tb_aes_axi_slave.sv            # SystemVerilog AES AXI4-Lite slave testbench
    ├── tb_aes_axi_slave.v             # Verilog AES AXI4-Lite slave testbench
    ├── tb_axi_interconnect.sv         # AXI4 interconnect testbench
    └── test_bench_top.v               # Block-level testbench
```

---

## 7. Verification & Simulation Instructions

### 7.1 Available Testbenches

- **DPI-C SoC Test Suite (`tb/tb_soc_c_test.sv` + `c_test/soc_test.c`):** Instantiates `soc_top #(.USE_INTERNAL_CPU(0))` with `dma_csr_*` tied to `0`, and invokes `soc_c_main` over SystemVerilog DPI-C to exercise UART, GPIO, Timer, SHA-256, and AES-256. Supports runtime VCD capture via `+VCD_FILE=<path>` and compile-time `+define+FSDB` / `+define+VPD` waveform dumping.
- **Standalone SystemVerilog SoC Testbench (`tb/tb_soc_top.sv`):** Instantiates `soc_top #(.USE_INTERNAL_CPU(0))` (`CLK_PERIOD=20` for 50 MHz, `BAUD_DIV=434`, `dma_csr_*` tied to `0`) and executes 15 directed tests (9 UART, 3 GPIO, 1 Timer, 1 SHA-256, 1 AES-256).
- **Block-Level Testbenches:** `tb/tb_axi_uart_top.sv` (12 UART tests with `$fsdbDumpfile("dump.fsdb")`), `tb/tb_aes_axi_slave.sv` / `tb/tb_aes_axi_slave.v`, `tb/tb_axi_interconnect.sv`, and `tb/test_bench_top.v`.

### 7.2 Running with Synopsys VCS

Run from the `run/` directory using the maintained DPI-C filelist [`run/run_c_test.f`](run/run_c_test.f) (example invocation — simulation logs were not generated or checked into this repository):

```bash
cd run

# Example compile command for SoC RTL + DPI-C C test suite (optional: +define+FSDB or +define+VPD)
vcs -sverilog -full64 -debug_access+all -f run_c_test.f -o simv_c_test

# Run simulation (optional: +VCD_FILE=soc_c_test.vcd)
./simv_c_test +VCD_FILE=soc_c_test.vcd
```

> **Filelist Caveats:**
> - [`run/run.f`](run/run.f) currently references `../rtl/interconnect/soc_top.v` (nonexistent; the actual module path is `../rtl/soc_top.v`, which is corrected in `run/run_c_test.f`).
> - [`run/run_integrated_soc.f`](run/run_integrated_soc.f) is a legacy partial filelist referencing `axi_interconnect_wrap_2x10` alongside `rtl/soc_top.v` and is out of sync with the current `axi_interconnect_wrap_2x5` integration.
> - No pre-run VCS simulation logs (`sim.log`, `simv.log`) are checked into the repository.

---

## 8. Known Issues & Next Steps

1. **AES Wrapper Defects (`rtl/aes/aes_core_top.v`):**
   - `blk_remaining` is hardwired to `1` (preventing true multi-block streaming).
   - `ST_KEY_LOAD1` skips `ST_KEY_LOAD2` / `ST_KEY_WAIT2`.
   - `iv_data` is never loaded into `feedback_reg`.
   - `ST_DATA_WAIT` updates `feedback_reg <= din_data` before the combinational CBC-decrypt XOR (`dout_internal`).
2. **SHA-256 Interrupt Latch (`rtl/sha/axi_sha256_top.v`):**
   - `digest_valid_reg` (`sha_irq`) only updates when software reads `STATUS` (`0x24`), instead of latching `core_digest_valid` when digest computation completes.
3. **UART FIFO Threshold Width (`rtl/uart/axi_uart_top.v`):**
   - `FIFO_THRESHOLD=90` exceeds the 16-entry FIFO depth and is truncated in 5-bit width to `26`.
4. **DMA Accessibility & Memory Targets (`rtl/soc_top.v`):**
   - `dma_csr_*` is exposed only at top-level pins (unmapped from `axi_interconnect_wrap_2x5` and tied to `0` in `tb_soc_top.sv` / `tb_soc_c_test.sv`), and no AXI System SRAM target slave exists on the crossbar for memory-to-peripheral or memory-to-memory transfers.
5. **VeeR EL2 Execution & UVM Verification:**
   - Add or link the external CHIPS Alliance VeeR EL2 RTL/packages/memory models to enable `USE_INTERNAL_CPU=1` firmware execution.
   - Add a dedicated DMA verification sequence and UVM agents/scoreboards if full coverage-driven verification is required.

---

## 9. Documentation & References

- Local specifications & references in [`doc/`](doc/):
  - [`doc/Project_spec.odt`](doc/Project_spec.odt)
  - [`doc/description.md`](doc/description.md)
  - [`doc/aes.pdf`](doc/aes.pdf) (Rudolf Usselmann AES/Rijndael IP Core Rev. 1.1 baseline)
- Underlying IP baselines: Alex Forencich `verilog-axi`, Secworks `sha256`, OpenTitan `rv_timer` / Anderson Ignacio AXI4 DMA, CHIPS Alliance VeeR EL2.

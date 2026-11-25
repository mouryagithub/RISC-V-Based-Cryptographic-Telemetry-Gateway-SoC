# RISC-V Based Cryptographic Telemetry Gateway SoC
### with AES-256 and SHA-256 Engines

> **Honours Project — RTL Design & Verification**  
> Simulation environment: Synopsys VCS `U-2023.03` / Verdi · Languages: SystemVerilog (IEEE 1800 / UVM) / Verilog / DPI-C

---

## 1. Overview & Motivation

Telemetry gateways deployed in embedded, industrial, and edge environments require low-latency hardware acceleration for data confidentiality and integrity alongside deterministic control over serial, timer, and general-purpose I/O interfaces. Offloading symmetric block encryption (AES-256) and cryptographic hashing (SHA-256) to dedicated AXI-attached hardware blocks reduces CPU overhead and increases telemetry processing throughput.

This repository implements the integrated RTL, AMBA AXI4 / AXI4-Lite interconnect fabric, cryptographic and peripheral subsystems, DPI-C firmware test suite, directed SystemVerilog testbenches, and UVM Verification IP (VIP) environment for a **RISC-V Based Cryptographic Telemetry Gateway SoC**.

### Key Objectives

- Integrate an **AES-256** accelerator (`aes_core_top` with `aes_key_expand_256`) and a **SHA-256** accelerator (`axi_sha256_top` wrapping Secworks `sha256`) behind uniform 32-bit AXI4-Lite register interfaces.
- Connect system masters (`veer_core_top` or external `ext_s00_axi_*`, plus `dma_axi_top` on `s01`) to five memory-mapped peripheral slaves (`m00`–`m04`) via a parameterized **AXI4 2-master × 5-slave crossbar** (`axi_interconnect_wrap_2x5`) and combinational `axi_to_axilite_bridge` modules.
- Route peripheral and DMA interrupts (`uart_irq`, `timer_irq`, `aes_irq`, `sha_irq`, `dma_done`, `dma_error`, `gpio_intr[1:0]`) to the VeeR EL2 PIC gateway (`pic_ext_irqs[8:1]`).
- Verify SoC integration using directed SystemVerilog tests (`tb/tb_soc_top.sv`), a C firmware DPI-C test suite (`c_test/soc_test.c`), and a unified **UVM testbench** (`tb/tb_top.sv`) with external boundary VIPs (`tb/gpio_vip_uvm_tb/`, `tb/uart_vip_uvm_tb/`) compiled through [`run/run_vip.f`](run/run_vip.f).

---

## 2. System Architecture

### 2.1 SoC Block Diagram (Intended Spec vs. Integrated RTL)

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

In the **current integrated RTL** ([`rtl/soc_top.v`](rtl/soc_top.v)), `soc_top #(USE_INTERNAL_CPU=1, AXI_DATA_WIDTH=32, AXI_ADDR_WIDTH=32, AXI_ID_WIDTH=8)` integrates:

- **Master `s00` (CPU / Testbench Master):** Multiplexed by `USE_INTERNAL_CPU`:
  - `1`: `veer_core_top` ([`rtl/veer_core_top.sv`](rtl/veer_core_top.sv)) with inline 64-to-32-bit LSU width steering.
  - `0`: External AXI4 master interface `ext_s00_axi_*` (used by `tb_top.sv`, `tb_soc_c_test.sv`, and `tb_soc_top.sv`).
- **Master `s01` (DMA Master):** `dma_axi_top` ([`rtl/dma/dma_axi_top.sv`](rtl/dma/dma_axi_top.sv)) configured with `DMA_NUM_DESC=2`, `AXI_DATA_WIDTH=32`, and `AXI_TXN_ID_WIDTH=8`. Its AXI4-Lite CSR configuration slave (`dma_csr_*`) is exported on `soc_top` top-level pins (tied off to `0` in current SoC testbenches).
- **Slaves `m00`–`m04` (`axi_interconnect_wrap_2x5`):** Five 4 KB (`12`-bit) address windows bridged via `axi_to_axilite_bridge` to `aes_core_top`, `axi_uart_top`, `axi_timer_top`, `axi_gpio_top`, and `axi_sha256_top`.

### 2.2 Architectural Alignment Note

> Earlier documentation and legacy baseline assumptions referenced an APB control plane. The updated specification establishes **AXI4-Lite** as the unified control interface for the AES core and all peripherals, aligning directly with the AXI4-Lite slave interface in [`rtl/aes/aes_regfile.v`](rtl/aes/aes_regfile.v) and all four sibling peripheral wrappers.

---

## 3. Current Implementation Status

| Feature / Subsystem | Status | Implementation & Verification Notes |
|---|---|---|
| Top-level integration (`rtl/soc_top.v`) | Implemented | 2×5 crossbar, `USE_INTERNAL_CPU` mux, 5 AXI4-Lite bridges, DMA master `s01`, and `pic_ext_irqs[8:1]` |
| AXI4 2×5 crossbar (`axi_interconnect_wrap_2x5.v`) | Implemented | Parameterized 2-master × 5-slave Forencich AXI4 wrapper (`m00`–`m04`, 4 KB each) |
| AXI4-to-AXI4-Lite bridge (`axi_to_axilite_bridge.v`) | Implemented | Combinational single-beat bridge instantiated per slave (`S_ADDR_WIDTH=8` or `12`) |
| UVM Testbench Top (`tb/tb_top.sv` + `run/run_vip.f`) | Implemented | Unified UVM + DPI-C testbench (`soc_vip_test`, `soc_c_test`, `gpio_vip_test`, `uart_vip_test`) with FSDB/VCD capture |
| UVM External Boundary VIPs (`tb/gpio_vip_uvm_tb/`, `tb/uart_vip_uvm_tb/`) | Implemented | Complete UVM packages (`item`, `sequencer`, `driver`, `monitor`, `agent`, `scoreboard`, `env`, `test`) and SV interfaces (`gpio_vip_if.sv`, `uart_vip_if.sv`) driving/sampling SoC boundary pins |
| DPI-C Firmware Suite (`c_test/soc_test.c`, `tb/tb_soc_c_test.sv`) | Implemented | Exercises UART, GPIO, Timer, SHA-256, and AES-256 (`soc_c_main`, runnable standalone via `run_c_test.f` or under `soc_c_test` in `tb_top.sv`) |
| Standalone SV Testbenches (`tb/tb_soc_top.sv`, unit TBs) | Implemented | 15 directed SoC tests in `tb_soc_top.sv`, plus block TBs for UART (`tb_axi_uart_top.sv`), AES (`tb_aes_axi_slave.*`), and interconnect (`tb_axi_interconnect.sv`) |
| UART (`rtl/uart/axi_uart_top.v`, `axi_internal_fifo.v`) | Implemented | AXI4-Lite 16-entry TX/RX FIFO UART (see FIFO threshold truncation defect in Section 8) |
| System Timer (`rtl/timer/axi_timer_top.v`, `timer_core.sv`) | Implemented | OpenTitan-style `rv_timer` (`N=1`) with 64-bit `mtime`/`mtimecmp` and `timer_irq` |
| 64-pin GPIO (`rtl/gpio/axi_gpio_top.v`) | Implemented | 64 pins, atomic SET/CLEAR/TOGGLE registers, edge/level interrupts (`gpio_intr_o[1:0]`) |
| SHA-256 accelerator (`rtl/sha/axi_sha256_top.v`, `sha256.v`) | Implemented | Secworks SHA-256 on AXI4-Lite (`0x4000_4000`); see `STATUS`-read IRQ latch behavior in Section 8 |
| AES-256 accelerator (`rtl/aes/`) | Partial / Bugs Open | `aes_cipher_top`/`aes_inv_cipher_top` instantiate `aes_key_expand_256` (256-bit key), but `aes_core_top.v` retains multi-block, key-load, IV, and CBC-decrypt bugs (Section 8) |
| DMA controller (`rtl/dma/dma_axi_top.sv`) | Integrated (Untested at SoC) | Wired to `s01`; `dma_csr_*` exported on `soc_top` pins and tied to `0` in `tb_top.sv`, `tb_soc_c_test.sv`, and `tb_soc_top.sv` |
| VeeR EL2 wrapper (`rtl/veer_core_top.sv`) | Wrapper Only | Wrapper exists in repo (`USE_INTERNAL_CPU=1`), while upstream CHIPS Alliance EL2 core RTL/packages/headers/SRAMs are external and not bundled; TBs run with `USE_INTERNAL_CPU=0` |

---

## 4. SoC Address Map & Interrupts

Verified from [`rtl/soc_top.v`](rtl/soc_top.v) and [`c_test/soc_regs.h`](c_test/soc_regs.h):

### 4.1 Crossbar Slave Windows (`axi_interconnect_wrap_2x5`)

| Port | Peripheral | Module | Base Address | End Address | Bridge `S_ADDR_WIDTH` |
|---|---|---|---|---|---|
| `m00` | AES-256 Engine | `aes_core_top` | `0x4000_0000` | `0x4000_0FFF` | `8` |
| `m01` | UART | `axi_uart_top` | `0x4000_1000` | `0x4000_1FFF` | `8` |
| `m02` | System Timer | `axi_timer_top` | `0x4000_2000` | `0x4000_2FFF` | `12` |
| `m03` | 64-Pin GPIO | `axi_gpio_top` | `0x4000_3000` | `0x4000_3FFF` | `12` |
| `m04` | SHA-256 Engine | `axi_sha256_top` | `0x4000_4000` | `0x4000_4FFF` | `12` |

> **DMA CSR Port:** `dma_axi_top` connects as AXI4 master `s01` on `axi_interconnect_wrap_2x5`; its AXI4-Lite configuration slave (`dma_csr_*`) is exposed directly at `soc_top` ports rather than decoded under `m00`–`m04`.

### 4.2 Interrupt Mapping (`pic_ext_irqs[8:1]`)

| VeeR PIC Line | SoC Source Signal | Description |
|---|---|---|
| `pic_ext_irqs[1]` | `uart_irq` | UART interrupt from `axi_uart_top` |
| `pic_ext_irqs[2]` | `timer_irq` | Timer interrupt from `axi_timer_top` (also routed to `u_cpu.timer_int`) |
| `pic_ext_irqs[3]` | `aes_irq` | AES interrupt (`ctrl_irq_en & (status_done \| status_err)`) |
| `pic_ext_irqs[4]` | `sha_irq` | SHA-256 interrupt from `axi_sha256_top` |
| `pic_ext_irqs[5]` | `dma_done` | DMA transfer completion interrupt from `dma_axi_top` |
| `pic_ext_irqs[6]` | `dma_error` | DMA bus error interrupt from `dma_axi_top` |
| `pic_ext_irqs[7]` | `gpio_intr[0]` | Lower 32-pin GPIO bank interrupt (`\|reg_status_0`) |
| `pic_ext_irqs[8]` | `gpio_intr[1]` | Upper 32-pin GPIO bank interrupt (`\|reg_status_1`) |

---

## 5. Subsystems & Verification IPs

### 5.1 UVM Verification Environment & Boundary VIPs

[`tb/tb_top.sv`](tb/tb_top.sv) implements a unified UVM testbench targeting `soc_top #(.USE_INTERNAL_CPU(0))` with pure boundary pin-level VIPs (no internal AXI signals inside the VIPs):

- **GPIO UVM VIP ([`tb/gpio_vip_uvm_tb/gpio_vip_pkg.sv`](tb/gpio_vip_uvm_tb/gpio_vip_pkg.sv)):**
  - Interface [`gpio_vip_if.sv`](tb/gpio_vip_uvm_tb/gpio_vip_if.sv): binds `gpio_i[63:0]`, `gpio_o[63:0]`, `gpio_dir_o[63:0]`, and `gpio_intr_o[1:0]` with `drv_cb`/`mon_cb` clocking blocks and `drv_mp`/`mon_mp` modports.
  - Package components: `gpio_vip_item`, `gpio_vip_sequencer`, `gpio_vip_driver` (drives `gpio_i` with configurable hold cycles), `gpio_vip_monitor` (samples changes across all external GPIO pins and broadcasts on analysis port `ap`), `gpio_vip_agent`, `gpio_vip_scoreboard`, `gpio_vip_env`, `gpio_base_seq`, `gpio_stimulus_seq`, and `gpio_vip_test`.
- **UART UVM VIP ([`tb/uart_vip_uvm_tb/uart_vip_pkg.sv`](tb/uart_vip_uvm_tb/uart_vip_pkg.sv)):**
  - Interface [`uart_vip_if.sv`](tb/uart_vip_uvm_tb/uart_vip_if.sv): binds `uart_rx`, `uart_tx`, and `uart_irq` with `drv_cb`/`mon_cb` clocking blocks and `drv_mp`/`mon_mp` modports.
  - Package components: `uart_vip_item` (payload, `clks_per_bit`, parity/stop-bit controls, and error injection flags `corrupt_stop`/`corrupt_parity`), `uart_vip_sequencer`, `uart_vip_driver` (bit-bangs serial frames onto `uart_rx`), `uart_vip_monitor` (reconstructs bytes from `uart_tx` and watches `uart_irq`), `uart_vip_agent`, `uart_vip_scoreboard`, `uart_vip_env`, `uart_base_seq`, `uart_inject_seq`, and `uart_vip_test`.
- **Top-Level UVM Tests in `tb/tb_top.sv`:**
  - `soc_vip_test` (default): runs `gpio_stimulus_seq`, configures UART via AXI4 (`DLAB=1`, `BAUD=434`, `8N1`, RX IRQ enabled), and runs `uart_inject_seq`.
  - `soc_c_test`: executes `soc_c_main` over DPI-C while both `gpio_vip_env` and `uart_vip_env` monitor/interact with the external SoC pins.

### 5.2 Cryptographic & Peripheral RTL Subsystems

- **AES-256 (`rtl/aes/`):** `aes_cipher_top.v` and `aes_inv_cipher_top.v` instantiate `aes_key_expand_256` (`key[255:0]`). [`aes_regfile.v`](rtl/aes/aes_regfile.v) exposes `AES_CTRL` (`0x00`), `AES_STATUS` (`0x04`), `AES_BLK_CNT` (`0x08`), `AES_IRQ_CLR` (`0x0C`), `AES_KEY0–7` (`0x10–0x2C`, WO), `AES_IV0–3` (`0x30–0x3C`, RW), `AES_DIN0–3` (`0x40–0x4C`, WO), and `AES_DOUT0–3` (`0x50–0x5C`, RO).
- **SHA-256 (`rtl/sha/`):** `axi_sha256_top.v` wraps Secworks `sha256.v` / `sha256_core.v` with `NAME0="sha2"` (`0x00`), `NAME1="-256"` (`0x04`), `VERSION="1.80"` (`0x08`), `CTRL` (`0x20`), `STATUS` (`0x24`), `BLOCK0–15` (`0x40–0x7C`), and `DIGEST0–7` (`0x80–0x9C`).
- **UART (`rtl/uart/`):** `axi_uart_top.v` (`uart_controller`, `uart_transmitter`, `uart_receiver`, `uart_parity_bit_compute`) and two 16-entry `axi_internal_fifo` instances (`0x00` `THR`/`RBR`, `0x04` `IER`, `0x08` `BAUD_DIV`, `0x0C` `LCR`, `0x14` `LSR`).
- **System Timer (`rtl/timer/`):** `axi_timer_top.v` + `timer_core.sv` (`rv_timer`, `N=1`) across `0x000–0x11C` (`CTRL 0x004`, `INTR_ENABLE0 0x100`, `INTR_STATE0 0x104`, `CFG0 0x10C`, `mtime 0x110/0x114`, `mtimecmp 0x118/0x11C`).
- **64-Pin GPIO (`rtl/gpio/`):** `axi_gpio_top.v` across `0x000–0x584` (`GPIO_INFO=64` at `0x000`, `GPIO_EN_0/1` `0x080/0x084`, `GPIO_IN_0/1` `0x100/0x104`, `GPIO_OUT_0/1` `0x180/0x184`, atomic `SET` `0x200/0x204`, `CLEAR` `0x280/0x284`, `TOGGLE` `0x300/0x304`, rise/fall/high/low IRQ enables `0x380–0x504`, `status` `0x580/0x584`).
- **DMA (`rtl/dma/`):** `dma_axi_top.sv` (`dma_axi_wrapper`, `dma_func_wrapper`, `dma_fsm`, `dma_streamer`, `dma_fifo`, `dma_axi_if`, `csr_dma` + `rggen_*` infrastructure, `rtl/dma/inc/{amba_axi_pkg.sv, dma_pkg.svh, dma_utils_pkg.sv}`).
- **VeeR EL2 Wrapper (`rtl/veer_core_top.sv`):** Instantiates `el2_veer_wrapper`, `el2_mem_if`, `ram_4096x39`, `ram_be_512x142`, `ram_be_128x52`, and optional `axi_slv` (`BOOT_IMEM_ENABLE=1`), requiring external `common_defines.vh`, `el2_param.vh`, and `el2_pkg`.

---

## 6. Repository Structure

Verified repository layout (note: `doc/` also retains the original specification and IP PDF; external VeeR EL2 core sources are not included):

```text
RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/
├── c_test/
│   ├── soc_regs.h                         # Peripheral register definitions (0x4000_0000–0x4000_4FFF)
│   ├── soc_test.c                         # DPI-C system firmware test suite (soc_c_main)
│   └── soc_test.h                         # DPI-C import/export prototypes & MMIO helpers
├── doc/
│   ├── Project_spec.odt                   # Project architecture specification document
│   ├── aes.pdf                            # Original Rudolf Usselmann AES IP Core Rev 1.1 datasheet
│   └── description.md                     # Early SoC integration notes
├── rtl/
│   ├── soc_top.v                          # Top-level SoC wrapper (2x5 crossbar + CPU/DMA + 5 slaves)
│   ├── veer_core_top.sv                   # VeeR EL2 CPU & memory wrapper (requires external EL2 core files)
│   ├── interconnect/
│   │   ├── arbiter.v
│   │   ├── priority_encoder.v
│   │   ├── axi_interconnect.v
│   │   ├── axi_interconnect_wrap_2x5.v
│   │   └── axi_to_axilite_bridge.v
│   ├── aes/
│   │   ├── timescale.v
│   │   ├── aes_sbox.v / aes_inv_sbox.v / aes_rcon.v
│   │   ├── aes_key_expand_128.v / aes_key_expand_256.v
│   │   ├── aes_cipher_top.v / aes_inv_cipher_top.v
│   │   ├── aes_regfile.v / aes_core_top.v / aes_axi_slave.v
│   ├── sha/
│   │   ├── sha256_k_constants.v / sha256_w_mem.v
│   │   ├── sha256_core.v / sha256.v / axi_sha256_top.v
│   ├── uart/
│   │   ├── timescale.v / axi_uart_defines.vh / axi_uart.vh
│   │   ├── uart_parity_bit_compute.v / axi_internal_fifo.v
│   │   ├── uart_receiver.v / uart_transmitter.v / uart_controller.v
│   │   └── axi_uart_top.v
│   ├── timer/
│   │   ├── timer_core.sv
│   │   └── axi_timer_top.v
│   ├── gpio/
│   │   └── axi_gpio_top.v
│   └── dma/
│       ├── dma_axi_top.sv / dma_axi_wrapper.sv / dma_func_wrapper.sv
│       ├── dma_fsm.sv / dma_streamer.sv / dma_fifo.sv / dma_axi_if.sv
│       ├── csr_dma.v / rggen_*.v
│       └── inc/ { amba_axi_pkg.sv, dma_pkg.svh, dma_utils_pkg.sv }
├── run/
│   ├── run_vip.f                          # VCS filelist: full SoC + DPI-C + GPIO & UART UVM VIPs (tb_top.sv)
│   ├── run_c_test.f                       # VCS filelist: full SoC + DPI-C C test suite (tb_soc_c_test.sv)
│   ├── run.f                              # Stale SoC filelist (references missing ../rtl/interconnect/soc_top.v)
│   ├── run_integrated_soc.f               # Legacy partial filelist (references axi_interconnect_wrap_2x10)
│   ├── run1.f / run2.f                    # Legacy block-level interconnect / AES filelists
├── scripts/
│   └── axi_interconnect_wrap.py           # Crossbar wrapper Jinja2 generator script
└── tb/
    ├── tb_top.sv                          # Unified UVM + DPI-C SoC testbench (4 UVM test targets)
    ├── tb_soc_c_test.sv                   # Standalone DPI-C SoC testbench (+VCD_FILE, +define+FSDB/+VPD)
    ├── tb_soc_top.sv                      # Standalone 15-test SV SoC testbench (50 MHz, BAUD_DIV=434)
    ├── gpio_vip_uvm_tb/                   # External 64-pin GPIO UVM VIP (if, pkg, item, seqr, drv, mon, agent, sb, env, test)
    ├── uart_vip_uvm_tb/                   # External UART UVM VIP (if, pkg, item, seqr, drv, mon, agent, sb, env, test)
    ├── tb_axi_uart_top.sv                 # Block-level UART testbench (12 tests)
    ├── tb_aes_axi_slave.sv / .v           # AES AXI4-Lite slave testbenches
    ├── tb_axi_interconnect.sv             # AXI4 interconnect testbench
    └── test_bench_top.v                   # Standalone AES cipher/inv_cipher testbench
```

---

## 7. Verification & Simulation Instructions

### 7.1 UVM + External VIPs + DPI-C Simulation ([`run/run_vip.f`](run/run_vip.f))

Documented directly in [`run/run_vip.f`](run/run_vip.f), execute from the `run/` directory:

```bash
cd run

# Compile full SoC RTL + DPI-C C tests + GPIO & UART UVM VIPs
vcs -full64 -ntb_opts uvm -debug_access+all -kdb -f run_vip.f -o simv_soc_vips

# Run integrated UVM VIP test (default: soc_vip_test)
./simv_soc_vips +UVM_NO_RELNOTES
# or explicitly:
./simv_soc_vips +UVM_TESTNAME=soc_vip_test +UVM_NO_RELNOTES

# Run standalone external GPIO VIP test
./simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES

# Run standalone external UART VIP test
./simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES

# Run SoC DPI-C C regression suite (31 checks) inside UVM top
./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES

# View Verdi FSDB waveform
verdi -ssf soc_vips_tb.fsdb &
```

### 7.2 Standalone DPI-C SoC Simulation ([`run/run_c_test.f`](run/run_c_test.f))

```bash
cd run

# Compile with Verdi FSDB support (+define+FSDB already enabled in run_c_test.f)
vcs -full64 -kdb +define+FSDB -f run_c_test.f -o simv_soc_c_test
./simv_soc_c_test +VCD_FILE=soc_c_test.vcd
```

> **Filelist Notes:**
> - [`run/run.f`](run/run.f) references `../rtl/interconnect/soc_top.v` instead of `../rtl/soc_top.v` (fixed in `run/run_c_test.f` and `run/run_vip.f`).
> - [`run/run_integrated_soc.f`](run/run_integrated_soc.f) and [`run/run1.f`](run/run1.f) reference a legacy `axi_interconnect_wrap_2x10.v` wrapper not present alongside `axi_interconnect_wrap_2x5.v` in `rtl/interconnect/`.
> - Pre-generated VCS simulation logs (`sim.log`, `simv.log`) are not checked into the repository.

---

## 8. Known Issues & Next Steps

1. **AES Wrapper Defects (`rtl/aes/aes_core_top.v`):**
   - `blk_remaining` is hardwired to `1` (blocking multi-block streaming).
   - `ST_KEY_LOAD1` transitions directly to `ST_DATA_LOAD`, skipping `ST_KEY_LOAD2` / `ST_KEY_WAIT2`.
   - `iv_data` is never loaded into `feedback_reg`.
   - `ST_DATA_WAIT` updates `feedback_reg <= din_data` before the combinational CBC-decrypt XOR (`dout_internal`).
2. **SHA-256 Interrupt Latch (`rtl/sha/axi_sha256_top.v`):**
   - `digest_valid_reg` (`sha_irq`) only updates on `STATUS` (`0x24`) register reads rather than latching `core_digest_valid` automatically upon digest completion.
3. **UART FIFO Threshold Width (`rtl/uart/axi_uart_top.v`):**
   - `FIFO_THRESHOLD=90` exceeds the 16-entry FIFO depth and truncates in 5 bits to `26`.
4. **DMA CSR Connectivity (`rtl/soc_top.v`):**
   - `dma_csr_*` is brought out to `soc_top` pins (unmapped from `axi_interconnect_wrap_2x5` and tied to `0` in current SoC testbenches).
5. **VeeR EL2 Execution (`USE_INTERNAL_CPU=1`):**
   - Link the external CHIPS Alliance VeeR EL2 RTL/packages/headers/RAM models when enabling internal CPU simulation.

---

## 9. Documentation & References

- Repository documents in [`doc/`](doc/): [`doc/Project_spec.odt`](doc/Project_spec.odt), [`doc/description.md`](doc/description.md), and [`doc/aes.pdf`](doc/aes.pdf).
- Underlying IP baselines: Alex Forencich `verilog-axi`, Secworks `sha256`, OpenTitan `rv_timer`, Anderson Ignacio `rggen`/AXI4 DMA, Rudolf Usselmann AES/Rijndael IP Core, CHIPS Alliance VeeR EL2.

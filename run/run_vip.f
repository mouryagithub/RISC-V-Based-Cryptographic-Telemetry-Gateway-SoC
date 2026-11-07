// =============================================================================
// File        : run_vip.f
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : VCS compilation and simulation file-list for the integrated
//               SoC testbench (tb/tb_top.sv) with UVM VIPs (GPIO & UART)
//               and DPI-C C firmware regression test suite.
//
// Target DUT  : soc_top (rtl/interconnect/soc_top.v)
// Testbench   : tb_top (tb/tb_top.sv)
// VIPs        : GPIO VIP (tb/gpio_vip_uvm_tb), UART VIP (tb/uart_vip_uvm_tb)
// C Firmware  : c_test/soc_test.c (DPI-C test suite)
//
// USAGE EXAMPLES (executed from the project 'run/' directory):
// -----------------------------------------------------------------------------
// 1. Compilation:
//      vcs -full64 -ntb_opts uvm -debug_access+all -kdb -f run_vip.f -o simv_soc_vips
//
// 2. Run Integrated VIP Test (Default - GPIO VIP + UART VIP):
//      ./simv_soc_vips +UVM_NO_RELNOTES
//      (or explicitly: ./simv_soc_vips +UVM_TESTNAME=soc_vip_test +UVM_NO_RELNOTES)
//
// 3. Run Standalone GPIO VIP UVM Test:
//      ./simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES
//
// 4. Run Standalone UART VIP UVM Test:
//      ./simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES
//
// 5. Run SoC DPI-C Firmware Regression Suite (31 tests):
//      ./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES
//
// 6. Verdi FSDB Waveform Viewing:
//      verdi -ssf soc_vips_tb.fsdb &
// =============================================================================

// -----------------------------------------------------------------------------
// Language & Simulation Compiler Flags
// -----------------------------------------------------------------------------
-sverilog
+v2k
-timescale=1ns/1ps
+define+FSDB

// -----------------------------------------------------------------------------
// Include Directories
// -----------------------------------------------------------------------------
+incdir+../rtl/dma/inc
+incdir+../rtl/dma
+incdir+../rtl/uart
+incdir+../rtl/aes
+incdir+../tb/gpio_vip_uvm_tb
+incdir+../tb/uart_vip_uvm_tb
+incdir+../c_test
+incdir+../tb

// -----------------------------------------------------------------------------
// C Firmware Test Suite (DPI-C Implementation)
// -----------------------------------------------------------------------------
../c_test/soc_test.c

// -----------------------------------------------------------------------------
// AXI Interconnect & Infrastructure RTL
// -----------------------------------------------------------------------------
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x5.v
../rtl/interconnect/axi_to_axilite_bridge.v

// -----------------------------------------------------------------------------
// AXI DMA Subsystem RTL
// -----------------------------------------------------------------------------
../rtl/dma/inc/amba_axi_pkg.sv
../rtl/dma/inc/dma_utils_pkg.sv
../rtl/dma/rggen_mux.v
../rtl/dma/rggen_adapter_common.v
../rtl/dma/rggen_address_decoder.v
../rtl/dma/rggen_axi4lite_adapter.v
../rtl/dma/rggen_axi4lite_skid_buffer.v
../rtl/dma/rggen_bit_field.v
../rtl/dma/rggen_default_register.v
../rtl/dma/rggen_or_reducer.v
../rtl/dma/rggen_register_common.v
../rtl/dma/csr_dma.v
../rtl/dma/dma_fifo.sv
../rtl/dma/dma_fsm.sv
../rtl/dma/dma_streamer.sv
../rtl/dma/dma_axi_if.sv
../rtl/dma/dma_func_wrapper.sv
../rtl/dma/dma_axi_wrapper.sv
../rtl/dma/dma_axi_top.sv

// -----------------------------------------------------------------------------
// Cryptographic Hardware: AES-256 Accelerator RTL
// -----------------------------------------------------------------------------
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_rcon.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_key_expand_256.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v
../rtl/aes/aes_regfile.v
../rtl/aes/aes_core_top.v

// -----------------------------------------------------------------------------
// Communication: AXI-UART Controller RTL
// -----------------------------------------------------------------------------
../rtl/uart/timescale.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// -----------------------------------------------------------------------------
// Timers: AXI RV-Timer Subsystem RTL
// -----------------------------------------------------------------------------
../rtl/timer/timer_core.sv
../rtl/timer/axi_timer_top.v

// -----------------------------------------------------------------------------
// I/O: 64-Pin AXI GPIO Controller RTL
// -----------------------------------------------------------------------------
../rtl/gpio/axi_gpio_top.v

// -----------------------------------------------------------------------------
// Cryptographic Hardware: SHA-256 Accelerator RTL
// -----------------------------------------------------------------------------
../rtl/sha/sha256_k_constants.v
../rtl/sha/sha256_w_mem.v
../rtl/sha/sha256_core.v
../rtl/sha/sha256.v
../rtl/sha/axi_sha256_top.v

// -----------------------------------------------------------------------------
// Integrated SoC Top-Level RTL
// -----------------------------------------------------------------------------
../rtl/soc_top.v

// -----------------------------------------------------------------------------
// UVM VIP Interfaces & Packages
// -----------------------------------------------------------------------------
../tb/gpio_vip_uvm_tb/gpio_vip_if.sv
../tb/gpio_vip_uvm_tb/gpio_vip_pkg.sv
../tb/uart_vip_uvm_tb/uart_vip_if.sv
../tb/uart_vip_uvm_tb/uart_vip_pkg.sv

// -----------------------------------------------------------------------------
// Top-Level Testbench
// -----------------------------------------------------------------------------
../tb/tb_top.sv

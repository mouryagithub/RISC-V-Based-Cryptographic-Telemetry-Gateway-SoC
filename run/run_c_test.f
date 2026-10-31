// =============================================================================
// File        : run.f (or run_c_test.f)
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : VCS compilation, DPI-C elaboration, and simulation file-list
//               to execute the C firmware test suite on soc_top and generate
//               waveforms (VCD, Verdi FSDB, or Synopsys VPD).
//
// Target DUT  : soc_top (rtl/interconnect/soc_top.v)
// Testbench   : tb_soc_c_test (tb/tb_soc_c_test.sv)
// C Firmware  : c_test/soc_test.c (DPI-C test suite)
//
// USAGE EXAMPLES (from project run/ directory):
// -----------------------------------------------------------------------------
// 1. Compile and Run with VCD Waveform Generation:
//      vcs -full64 -f run.f -o simv_soc_c_test
//      ./simv_soc_c_test
//      # Waveform output: soc_c_test.vcd
//      # View waveform: gtkwave soc_c_test.vcd &
//
// 2. Compile and Run with Synopsys Verdi FSDB Waveforms:
//      vcs -full64 -kdb +define+FSDB -f run.f -o simv_soc_c_test
//      ./simv_soc_c_test
//      # View waveform: verdi -ssf soc_c_test.fsdb &
//
// 3. Compile and Run with Synopsys DVE VPD Waveforms:
//      vcs -full64 +define+VPD -f run.f -o simv_soc_c_test
//      ./simv_soc_c_test
//      # View waveform: dve -vpd soc_c_test.vpd &
// =============================================================================

// -----------------------------------------------------------------------------
// Compiler Options
// -----------------------------------------------------------------------------
-sverilog
+v2k
-debug_access+all
+define+FSDB

// -----------------------------------------------------------------------------
// Include Directories
// -----------------------------------------------------------------------------
+incdir+../rtl/dma/inc
+incdir+../rtl/dma
+incdir+../rtl/uart
+incdir+../rtl/aes
+incdir+../c_test
+incdir+../tb

// -----------------------------------------------------------------------------
// C Compiler Flags (for DPI-C test suite headers)
// -----------------------------------------------------------------------------
-CFLAGS -I../c_test

// -----------------------------------------------------------------------------
// C Firmware Test Suite (DPI-C Implementation)
// -----------------------------------------------------------------------------
../c_test/soc_test.c

// -----------------------------------------------------------------------------
// AXI Interconnect & Infrastructure
// -----------------------------------------------------------------------------
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x5.v
../rtl/interconnect/axi_to_axilite_bridge.v

// -----------------------------------------------------------------------------
// AXI DMA Subsystem
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
// Cryptographic Hardware: AES-256 Accelerator
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
// Communication: AXI-UART Controller
// -----------------------------------------------------------------------------
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// -----------------------------------------------------------------------------
// Timers: AXI RV-Timer Subsystem
// -----------------------------------------------------------------------------
../rtl/timer/timer_core.sv
../rtl/timer/axi_timer_top.v

// -----------------------------------------------------------------------------
// I/O: 64-Pin AXI GPIO Controller
// -----------------------------------------------------------------------------
../rtl/gpio/axi_gpio_top.v

// -----------------------------------------------------------------------------
// Cryptographic Hardware: SHA-256 Accelerator
// -----------------------------------------------------------------------------
../rtl/sha/sha256_k_constants.v
../rtl/sha/sha256_w_mem.v
../rtl/sha/sha256_core.v
../rtl/sha/sha256.v
../rtl/sha/axi_sha256_top.v

// -----------------------------------------------------------------------------
// Integrated SoC Top-Level
// -----------------------------------------------------------------------------
../rtl/interconnect/soc_top.v

// -----------------------------------------------------------------------------
// Testbench: SystemVerilog DPI-C C Testbench
// -----------------------------------------------------------------------------
../tb/tb_soc_c_test.sv

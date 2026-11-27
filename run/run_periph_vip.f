// =============================================================================
// File        : run/run_periph_vip.f
// Description : Filelist for clean 6-Peripheral UVM-1.2 VIP Verification
//               (UART, Timer, GPIO, SHA-256, AES-256, AXI DMA) on soc_top.
// =============================================================================

-sverilog
+v2k
-timescale=1ns/1ps

+incdir+../rtl/dma/inc
+incdir+../rtl/dma
+incdir+../rtl/uart
+incdir+../rtl/aes
+incdir+../tb/gpio_vip_uvm_tb
+incdir+../tb/uart_vip_uvm_tb
+incdir+../tb/timer_vip_uvm_tb
+incdir+../tb/sha_vip_uvm_tb
+incdir+../tb/aes_vip_uvm_tb
+incdir+../tb/dma_vip_uvm_tb
+incdir+../tb

// AXI Interconnect & Memory Infrastructure RTL
../rtl/interconnect/priority_encoder.v
../rtl/interconnect/arbiter.v
../rtl/interconnect/axi_interconnect.v
../rtl/interconnect/axi_interconnect_wrap_2x6.v
../rtl/interconnect/axi_to_axilite_bridge.v
../rtl/mem/axi_sram.v

// AXI DMA Subsystem RTL
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

// AES-256 Accelerator RTL
../rtl/aes/aes_sbox.v
../rtl/aes/aes_inv_sbox.v
../rtl/aes/aes_rcon.v
../rtl/aes/aes_key_expand_128.v
../rtl/aes/aes_key_expand_256.v
../rtl/aes/aes_cipher_top.v
../rtl/aes/aes_inv_cipher_top.v
../rtl/aes/aes_regfile.v
../rtl/aes/aes_core_top.v

// AXI-UART Controller RTL
../rtl/uart/timescale.v
../rtl/uart/uart_parity_bit_compute.v
../rtl/uart/axi_internal_fifo.v
../rtl/uart/uart_receiver.v
../rtl/uart/uart_transmitter.v
../rtl/uart/uart_controller.v
../rtl/uart/axi_uart_top.v

// AXI RV-Timer RTL
../rtl/timer/timer_core.sv
../rtl/timer/axi_timer_top.v

// AXI 64-Pin GPIO RTL
../rtl/gpio/axi_gpio_top.v

// AXI SHA-256 Accelerator RTL
../rtl/sha/sha256_k_constants.v
../rtl/sha/sha256_w_mem.v
../rtl/sha/sha256_core.v
../rtl/sha/sha256.v
../rtl/sha/axi_sha256_top.v

// SoC Top-Level RTL
../rtl/soc_top.v

// Peripheral UVM Interfaces & Packages
../tb/soc_axi_if.sv
../tb/gpio_vip_uvm_tb/gpio_vip_if.sv
../tb/gpio_vip_uvm_tb/gpio_vip_pkg.sv
../tb/uart_vip_uvm_tb/uart_vip_if.sv
../tb/uart_vip_uvm_tb/uart_vip_pkg.sv
../tb/timer_vip_uvm_tb/timer_vip_if.sv
../tb/timer_vip_uvm_tb/timer_vip_pkg.sv
../tb/sha_vip_uvm_tb/sha_vip_if.sv
../tb/sha_vip_uvm_tb/sha_vip_pkg.sv
../tb/aes_vip_uvm_tb/aes_vip_if.sv
../tb/aes_vip_uvm_tb/aes_vip_pkg.sv
../tb/dma_vip_uvm_tb/dma_vip_if.sv
../tb/dma_vip_uvm_tb/dma_vip_pkg.sv

// Peripheral Coverage Collector & Clean UVM Top
../tb/soc_cov_pkg.sv
../tb/soc_cov_collector.sv
../tb/tb_periph_top.sv

#!/usr/bin/env bash
# ==============================================================================
# Script: compile_and_run_soc.sh
# Description: VCS compilation and simulation script for the integrated SoC top
#              with 2 Masters (VeeR2 CPU & AXI DMA) and 5 Slaves (UART, GPIO,
#              Timer, AES-256, SHA-256) through the 2x5 AXI Crossbar.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export PATH="$VCS_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"

cd "${SOC_ROOT}"

echo "================================================================="
echo " Compiling SoC with Synopsys VCS (U-2023.03_Full64)..."
echo "================================================================="

vcs -full64 -sverilog +v2k \
    +incdir+rtl/dma/inc \
    +incdir+rtl/dma \
    +incdir+rtl/uart \
    +incdir+rtl/aes \
    rtl/interconnect/priority_encoder.v \
    rtl/interconnect/arbiter.v \
    rtl/interconnect/axi_interconnect.v \
    rtl/interconnect/axi_interconnect_wrap_2x5.v \
    rtl/interconnect/axi_to_axilite_bridge.v \
    rtl/dma/inc/amba_axi_pkg.sv \
    rtl/dma/inc/dma_utils_pkg.sv \
    rtl/dma/rggen_mux.v \
    rtl/dma/rggen_adapter_common.v \
    rtl/dma/rggen_address_decoder.v \
    rtl/dma/rggen_axi4lite_adapter.v \
    rtl/dma/rggen_axi4lite_skid_buffer.v \
    rtl/dma/rggen_bit_field.v \
    rtl/dma/rggen_default_register.v \
    rtl/dma/rggen_or_reducer.v \
    rtl/dma/rggen_register_common.v \
    rtl/dma/csr_dma.v \
    rtl/dma/dma_fifo.sv \
    rtl/dma/dma_fsm.sv \
    rtl/dma/dma_streamer.sv \
    rtl/dma/dma_axi_if.sv \
    rtl/dma/dma_func_wrapper.sv \
    rtl/dma/dma_axi_wrapper.sv \
    rtl/dma/dma_axi_top.sv \
    rtl/aes/aes_sbox.v \
    rtl/aes/aes_inv_sbox.v \
    rtl/aes/aes_rcon.v \
    rtl/aes/aes_key_expand_128.v \
    rtl/aes/aes_key_expand_256.v \
    rtl/aes/aes_cipher_top.v \
    rtl/aes/aes_inv_cipher_top.v \
    rtl/aes/aes_regfile.v \
    rtl/aes/aes_core_top.v \
    rtl/uart/uart_parity_bit_compute.v \
    rtl/uart/axi_internal_fifo.v \
    rtl/uart/uart_receiver.v \
    rtl/uart/uart_transmitter.v \
    rtl/uart/uart_controller.v \
    rtl/uart/axi_uart_top.v \
    rtl/timer/timer_core.sv \
    rtl/timer/axi_timer_top.v \
    rtl/gpio/axi_gpio_top.v \
    rtl/sha/sha256_k_constants.v \
    rtl/sha/sha256_w_mem.v \
    rtl/sha/sha256_core.v \
    rtl/sha/sha256.v \
    rtl/sha/axi_sha256_top.v \
    rtl/soc_top.v \
    tb/tb_soc_top.sv \
    -o run/simv_soc

echo "================================================================="
echo " Running SoC Simulation..."
echo "================================================================="
./run/simv_soc

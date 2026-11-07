#!/usr/bin/env bash
# ==============================================================================
# Script: compile_and_run_soc_cpu.sh
# Description: VCS compilation and simulation script for the integrated SoC top
#              with the internal Western Digital VeeR EL2 RISC-V core instantiated
#              (USE_INTERNAL_CPU = 1), connected to:
#                - 2x5 AXI4 Crossbar Interconnect
#                - 64-bit AXI DMA Controller
#                - AES-256 Accelerator
#                - UART 16550 Serial Controller
#                - 64-bit System Timer (rv_timer)
#                - 64-pin GPIO Controller
#                - SHA-256 Hash Accelerator
#                - VeeR PIC Interrupt Gateway (31 interrupt vector lines)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export PATH="$VCS_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"
export RV_ROOT="${SOC_ROOT}/rtl/Cores-VeeR-EL2"

cd "${SOC_ROOT}"
mkdir -p run

# Ensure VeeR EL2 configuration snapshot exists
if [ ! -f "${RV_ROOT}/snapshots/default/common_defines.vh" ]; then
    echo "Generating VeeR-EL2 configuration snapshot..."
    (cd "${RV_ROOT}" && export RV_ROOT && perl configs/veer.config -target=default)
fi

echo "================================================================="
echo " Compiling Integrated SoC with VeeR-EL2 CPU via Synopsys VCS..."
echo " Target : soc_top (USE_INTERNAL_CPU = 1)"
echo " Testbench : tb/tb_soc_veer_cpu.sv"
echo "================================================================="

vcs -full64 -sverilog +v2k -timescale=1ns/1ps \
    +incdir+rtl/dma/inc \
    +incdir+rtl/dma \
    +incdir+rtl/uart \
    +incdir+rtl/aes \
    +incdir+$RV_ROOT/snapshots/default \
    +incdir+$RV_ROOT/design/include \
    +incdir+$RV_ROOT/design/lib \
    +incdir+tb \
    +define+RV_OPENSOURCE \
    $RV_ROOT/design/lib/el2_assert.sv \
    $RV_ROOT/design/include/el2_def.sv \
    $RV_ROOT/design/el2_mubi_pkg.sv \
    $RV_ROOT/design/lib/el2_mem_if.sv \
    $RV_ROOT/design/lib/el2_prim_generic_buf.sv \
    $RV_ROOT/design/lib/el2_prim_buf.sv \
    $RV_ROOT/design/lib/el2_lib.sv \
    $RV_ROOT/design/ifu/el2_ifu_aln_ctl.sv \
    $RV_ROOT/design/ifu/el2_ifu_compress_ctl.sv \
    $RV_ROOT/design/ifu/el2_ifu_ifc_ctl.sv \
    $RV_ROOT/design/ifu/el2_ifu_bp_ctl.sv \
    $RV_ROOT/design/ifu/el2_ifu_ic_mem.sv \
    $RV_ROOT/design/ifu/el2_ifu_mem_ctl.sv \
    $RV_ROOT/design/ifu/el2_ifu_iccm_mem.sv \
    $RV_ROOT/design/ifu/el2_ifu.sv \
    $RV_ROOT/design/dec/el2_dec_decode_ctl.sv \
    $RV_ROOT/design/dec/el2_dec_gpr_ctl.sv \
    $RV_ROOT/design/dec/el2_dec_ib_ctl.sv \
    $RV_ROOT/design/dec/el2_dec_pmp_ctl.sv \
    $RV_ROOT/design/dec/el2_dec_tlu_ctl.sv \
    $RV_ROOT/design/dec/el2_dec_trigger.sv \
    $RV_ROOT/design/dec/el2_dec.sv \
    $RV_ROOT/design/exu/el2_exu_alu_ctl.sv \
    $RV_ROOT/design/exu/el2_exu_mul_ctl.sv \
    $RV_ROOT/design/exu/el2_exu_div_ctl.sv \
    $RV_ROOT/design/exu/el2_exu.sv \
    $RV_ROOT/design/lsu/el2_lsu.sv \
    $RV_ROOT/design/lsu/el2_lsu_clkdomain.sv \
    $RV_ROOT/design/lsu/el2_lsu_addrcheck.sv \
    $RV_ROOT/design/lsu/el2_lsu_lsc_ctl.sv \
    $RV_ROOT/design/lsu/el2_lsu_stbuf.sv \
    $RV_ROOT/design/lsu/el2_lsu_bus_buffer.sv \
    $RV_ROOT/design/lsu/el2_lsu_bus_intf.sv \
    $RV_ROOT/design/lsu/el2_lsu_ecc.sv \
    $RV_ROOT/design/lsu/el2_lsu_dccm_mem.sv \
    $RV_ROOT/design/lsu/el2_lsu_dccm_ctl.sv \
    $RV_ROOT/design/lsu/el2_lsu_trigger.sv \
    $RV_ROOT/design/dbg/el2_dbg.sv \
    $RV_ROOT/design/dmi/dmi_mux.v \
    $RV_ROOT/design/dmi/dmi_wrapper.v \
    $RV_ROOT/design/dmi/dmi_jtag_to_core_sync.v \
    $RV_ROOT/design/dmi/rvjtag_tap.v \
    $RV_ROOT/design/el2_pic_ctrl.sv \
    $RV_ROOT/design/el2_dma_ctrl.sv \
    $RV_ROOT/design/el2_pmp.sv \
    $RV_ROOT/design/el2_veer.sv \
    $RV_ROOT/design/el2_mem.sv \
    $RV_ROOT/design/el2_veer_wrapper.sv \
    $RV_ROOT/testbench/ahb_sif.sv \
    -v $RV_ROOT/design/lib/beh_lib.sv \
    -v $RV_ROOT/design/lib/mem_lib.sv \
    rtl/veer_core_top.sv \
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
    tb/tb_soc_veer_cpu.sv \
    -o run/simv_soc_cpu

echo "================================================================="
echo " Running Integrated SoC with VeeR CPU in Synopsys VCS..."
echo "================================================================="
./run/simv_soc_cpu

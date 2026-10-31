#!/usr/bin/env bash
# ==============================================================================
# Script: compile_and_run_vips.sh
# Description: VCS compilation and simulation script for the UVM VIP testbenches:
#              1. GPIO VIP testbench (tb/gpio_vip_uvm_tb/tb_top.sv)
#              2. UART VIP testbench (tb/uart_vip_uvm_tb/tb_top.sv)
#              3. Integrated SoC VIP testbench (tb/tb_top.sv)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"

cd "${SOC_ROOT}"
mkdir -p run

TARGET="${1:-all}"

if [ "$TARGET" = "gpio" ] || [ "$TARGET" = "all" ]; then
    echo "================================================================="
    echo " Compiling & Running Standalone GPIO VIP Testbench..."
    echo " Top: tb/gpio_vip_uvm_tb/tb_top.sv | DUT: axi_gpio_top"
    echo "================================================================="
    cd "${SOC_ROOT}/tb/gpio_vip_uvm_tb"
    vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb \
        ../../rtl/gpio/axi_gpio_top.v \
        gpio_vip_if.sv gpio_vip_pkg.sv tb_top.sv \
        -o "${SOC_ROOT}/run/simv_gpio_vip"
    "${SOC_ROOT}/run/simv_gpio_vip" +UVM_NO_RELNOTES
fi

if [ "$TARGET" = "uart" ] || [ "$TARGET" = "all" ]; then
    echo "================================================================="
    echo " Compiling & Running Standalone UART VIP Testbench..."
    echo " Top: tb/uart_vip_uvm_tb/tb_top.sv | DUT: axi_uart_top"
    echo "================================================================="
    cd "${SOC_ROOT}/tb/uart_vip_uvm_tb"
    vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb \
        +incdir+../../rtl/uart \
        ../../rtl/uart/timescale.v \
        ../../rtl/uart/uart_parity_bit_compute.v \
        ../../rtl/uart/axi_internal_fifo.v \
        ../../rtl/uart/uart_receiver.v \
        ../../rtl/uart/uart_transmitter.v \
        ../../rtl/uart/uart_controller.v \
        ../../rtl/uart/axi_uart_top.v \
        uart_vip_if.sv uart_vip_pkg.sv tb_top.sv \
        -o "${SOC_ROOT}/run/simv_uart_vip"
    "${SOC_ROOT}/run/simv_uart_vip" +UVM_NO_RELNOTES
fi

if [ "$TARGET" = "soc" ] || [ "$TARGET" = "all" ]; then
    echo "================================================================="
    echo " Compiling & Running Integrated SoC VIP Testbench..."
    echo " Top: tb/tb_top.sv | DUT: soc_top | VIPs: UART + GPIO"
    echo "================================================================="
    cd "${SOC_ROOT}"
    vcs -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb \
        +incdir+rtl/dma/inc \
        +incdir+rtl/dma \
        +incdir+rtl/uart \
        +incdir+rtl/aes \
        +incdir+tb/gpio_vip_uvm_tb \
        +incdir+tb/uart_vip_uvm_tb \
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
        rtl/uart/timescale.v \
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
        rtl/interconnect/soc_top.v \
        tb/gpio_vip_uvm_tb/gpio_vip_if.sv \
        tb/gpio_vip_uvm_tb/gpio_vip_pkg.sv \
        tb/uart_vip_uvm_tb/uart_vip_if.sv \
        tb/uart_vip_uvm_tb/uart_vip_pkg.sv \
        tb/tb_top.sv \
        -o run/simv_soc_vips
    ./run/simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES
    ./run/simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES
fi

echo "================================================================="
echo " All UVM VIP simulations completed successfully!"
echo "================================================================="

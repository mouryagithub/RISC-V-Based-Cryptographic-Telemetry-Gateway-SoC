#!/usr/bin/env bash
# ==============================================================================
# Script: compile_and_run_vips.sh
# Description: VCS compilation and simulation script for the External UVM VIPs:
#              - GPIO VIP (tb/gpio_vip_uvm_tb)
#              - UART VIP (tb/uart_vip_uvm_tb)
#              - Integrated SoC Top Testbench (tb/tb_top.sv)
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"

cd "${SOC_ROOT}/run"

TARGET="${1:-all}"

echo "================================================================="
echo " Compiling SoC with External Pin VIPs (run_vip.f)..."
echo "================================================================="
vcs -full64 -ntb_opts uvm -debug_access+all -kdb -f run_vip.f -o simv_soc_vips

if [ "$TARGET" = "gpio" ]; then
    echo "================================================================="
    echo " Running External GPIO VIP UVM Test (gpio_vip_test)..."
    echo "================================================================="
    ./simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES
elif [ "$TARGET" = "uart" ]; then
    echo "================================================================="
    echo " Running External UART VIP UVM Test (uart_vip_test)..."
    echo "================================================================="
    ./simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES
elif [ "$TARGET" = "soc_vip" ]; then
    echo "================================================================="
    echo " Running Integrated External VIPs Test (soc_vip_test)..."
    echo "================================================================="
    ./simv_soc_vips +UVM_TESTNAME=soc_vip_test +UVM_NO_RELNOTES
elif [ "$TARGET" = "c_test" ]; then
    echo "================================================================="
    echo " Running SoC DPI-C Regression Suite (soc_c_test)..."
    echo "================================================================="
    ./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES
elif [ "$TARGET" = "all" ]; then
    echo "================================================================="
    echo " Running Full Suite of External VIP Tests..."
    echo "================================================================="
    ./simv_soc_vips +UVM_TESTNAME=soc_vip_test +UVM_NO_RELNOTES
    ./simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES
    ./simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES
    ./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES
fi

echo "================================================================="
echo " All UVM VIP simulations completed successfully!"
echo "================================================================="

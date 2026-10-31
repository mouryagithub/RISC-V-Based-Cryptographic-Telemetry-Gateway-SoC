#!/usr/bin/env bash
# ==============================================================================
# Script: tb/run.sh
# Description: Quick runner for UVM VIP testbenches from within tb/
# Usage:
#   ./run.sh soc    (runs integrated SoC VIP tb_top.sv)
#   ./run.sh gpio   (runs standalone GPIO VIP tb_top.sv)
#   ./run.sh uart   (runs standalone UART VIP tb_top.sv)
#   ./run.sh c_test (runs SoC C firmware test suite)
#   ./run.sh all    (runs all testbenches)
# ==============================================================================
set -e

TB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${TB_DIR}"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"

TARGET="${1:-soc}"

make "${TARGET}"

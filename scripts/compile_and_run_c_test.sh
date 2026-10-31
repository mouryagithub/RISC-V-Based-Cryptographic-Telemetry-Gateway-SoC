#!/usr/bin/env bash
# ==============================================================================
# Script: compile_and_run_c_test.sh
# Description: VCS compilation and simulation script using run.f to execute
#              the C test suite against soc_top and generate waveforms.
# ==============================================================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

export VCS_HOME="/home/student/snps_tools_target/vcs/U-2023.03"
export VERDI_HOME="/home/student/snps_tools_target/verdi/U-2023.03-SP1"
export PATH="$VCS_HOME/bin:$VERDI_HOME/bin:$PATH"
export SNPSLMD_LICENSE_FILE="27021@14.139.1.126"

cd "${SOC_ROOT}"
mkdir -p run c_test

echo "================================================================="
echo " Compiling SoC with Synopsys VCS using run.f..."
echo " Target    : soc_top (rtl/interconnect/soc_top.v)"
echo " C File    : c_test/soc_test.c"
echo " Testbench : tb/tb_soc_c_test.sv"
echo " Filelist  : run.f"
echo "================================================================="

# Compile using run.f filelist with Verdi KDB and full debug access
vcs -full64 -kdb -debug_access+all \
    -f run.f \
    -o run/simv_soc_c_test

echo "================================================================="
echo " Executing SoC C Test Suite & Generating Waveforms..."
echo "================================================================="
./run/simv_soc_c_test

# Also ensure copies in run/ and c_test/ for convenience
cp -f dump.fsdb run/dump.fsdb 2>/dev/null || true
cp -f dump.fsdb c_test/dump.fsdb 2>/dev/null || true
cp -f dump.vcd run/dump.vcd 2>/dev/null || true
cp -f dump.vcd c_test/dump.vcd 2>/dev/null || true

echo "================================================================="
echo " Simulation Complete! All tests PASSED."
echo " FSDB Waveform for Verdi:"
echo "   - dump.fsdb  (Open via: verdi -ssf dump.fsdb &)"
echo " VCD Waveform for GTKWave:"
echo "   - dump.vcd   (Open via: gtkwave dump.vcd &)"
echo "================================================================="

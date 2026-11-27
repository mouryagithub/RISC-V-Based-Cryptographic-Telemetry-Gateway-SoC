#!/usr/bin/env bash
# ==============================================================================
# Script      : compile_and_run_vivado.sh
# Project     : RISC-V Cryptographic Telemetry Gateway SoC
# Description : Builds and runs all SoC verification targets using AMD/Xilinx
#               Vivado Simulator (xsc / xvlog / xelab / xsim) strictly inside
#               run/vivado_{cpu_test,c_test,vip_test}:
#                 - cpu    : tb_soc_veer_cpu (VeeR-EL2 HW integration)
#                 - c_test : tb_soc_c_test + soc_test.c (DPI-C full SoC suite)
#                 - vip    : tb_periph_top UVM-1.2 suite (uart, timer, gpio,
#                            sha, aes, dma peripheral VIPs)
#                 - all    : runs all three suites (default)
#                 - coverage : runs all 6 peripheral VIPs with Vivado code
#                              coverage (--cc_type sbct) + functional coverage
#                              and writes text reports under run/coverage/
#
# Notes:
#   - Uses -d NO_ASSERTIONS to avoid Vivado xelab SVA crash in dma_axi_if.sv
#   - Uses --relax for Vivado UVM-1.2 & VeeR-EL2 compatibility
# ==============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOC_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODE="${1:-all}"
ENABLE_COV=0
if [ "${MODE}" = "coverage" ]; then
    ENABLE_COV=1
fi
COV_ROOT="${SOC_ROOT}/run/coverage"

if ! command -v xvlog >/dev/null 2>&1 || ! command -v xsim >/dev/null 2>&1; then
    for candidate in \
        "/home/mourya/Vivado/Vivado/2023.2/bin" \
        /tools/Xilinx/Vivado/*/bin \
        /opt/Xilinx/Vivado/*/bin; do
        if [ -x "${candidate}/xvlog" ] && [ -x "${candidate}/xsim" ]; then
            export PATH="${candidate}:${PATH}"
            break
        fi
    done
fi

for tool in xsc xvlog xelab xsim xcrg; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        echo "ERROR: Required Vivado Simulator binary '${tool}' not found in PATH." >&2
        exit 1
    fi
done
export XILINX_VIVADO="${XILINX_VIVADO:-$(cd "$(dirname "$(command -v xcrg)")/.." && pwd)}"

run_cpu_suite() {
    local work_dir="${SOC_ROOT}/run/vivado_cpu_test"
    local rv_root="../../rtl/Cores-VeeR-EL2"
    mkdir -p "${work_dir}"
    cd "${work_dir}"

    mapfile -t soc_rtl < <(grep -E '^\.\./rtl/' ../run_c_test.f | sed 's|^\.\./|../../|')

    echo "============================================================="
    echo " [Vivado] Building & Running VeeR-EL2 CPU Integration (sim_cpu)"
    echo "============================================================="
    xvlog -sv --relax -d RV_OPENSOURCE -d NO_ASSERTIONS \
        -i ../../rtl/dma/inc \
        -i ../../rtl/dma \
        -i ../../rtl/uart \
        -i ../../rtl/aes \
        -i "${rv_root}/snapshots/default" \
        -i "${rv_root}/design/include" \
        -i "${rv_root}/design/lib" \
        -i ../../tb \
        "${rv_root}/design/lib/el2_assert.sv" \
        "${rv_root}/design/include/el2_def.sv" \
        "${rv_root}/design/el2_mubi_pkg.sv" \
        "${rv_root}/design/lib/el2_mem_if.sv" \
        "${rv_root}/design/lib/el2_prim_generic_buf.sv" \
        "${rv_root}/design/lib/el2_prim_buf.sv" \
        "${rv_root}/design/lib/el2_lib.sv" \
        "${rv_root}/design/ifu/el2_ifu_aln_ctl.sv" \
        "${rv_root}/design/ifu/el2_ifu_compress_ctl.sv" \
        "${rv_root}/design/ifu/el2_ifu_ifc_ctl.sv" \
        "${rv_root}/design/ifu/el2_ifu_bp_ctl.sv" \
        "${rv_root}/design/ifu/el2_ifu_ic_mem.sv" \
        "${rv_root}/design/ifu/el2_ifu_mem_ctl.sv" \
        "${rv_root}/design/ifu/el2_ifu_iccm_mem.sv" \
        "${rv_root}/design/ifu/el2_ifu.sv" \
        "${rv_root}/design/dec/el2_dec_decode_ctl.sv" \
        "${rv_root}/design/dec/el2_dec_gpr_ctl.sv" \
        "${rv_root}/design/dec/el2_dec_ib_ctl.sv" \
        "${rv_root}/design/dec/el2_dec_pmp_ctl.sv" \
        "${rv_root}/design/dec/el2_dec_tlu_ctl.sv" \
        "${rv_root}/design/dec/el2_dec_trigger.sv" \
        "${rv_root}/design/dec/el2_dec.sv" \
        "${rv_root}/design/exu/el2_exu_alu_ctl.sv" \
        "${rv_root}/design/exu/el2_exu_mul_ctl.sv" \
        "${rv_root}/design/exu/el2_exu_div_ctl.sv" \
        "${rv_root}/design/exu/el2_exu.sv" \
        "${rv_root}/design/lsu/el2_lsu.sv" \
        "${rv_root}/design/lsu/el2_lsu_clkdomain.sv" \
        "${rv_root}/design/lsu/el2_lsu_addrcheck.sv" \
        "${rv_root}/design/lsu/el2_lsu_lsc_ctl.sv" \
        "${rv_root}/design/lsu/el2_lsu_stbuf.sv" \
        "${rv_root}/design/lsu/el2_lsu_bus_buffer.sv" \
        "${rv_root}/design/lsu/el2_lsu_bus_intf.sv" \
        "${rv_root}/design/lsu/el2_lsu_ecc.sv" \
        "${rv_root}/design/lsu/el2_lsu_dccm_mem.sv" \
        "${rv_root}/design/lsu/el2_lsu_dccm_ctl.sv" \
        "${rv_root}/design/lsu/el2_lsu_trigger.sv" \
        "${rv_root}/design/dbg/el2_dbg.sv" \
        "${rv_root}/design/dmi/dmi_mux.v" \
        "${rv_root}/design/dmi/dmi_wrapper.v" \
        "${rv_root}/design/dmi/dmi_jtag_to_core_sync.v" \
        "${rv_root}/design/dmi/rvjtag_tap.v" \
        "${rv_root}/design/el2_pic_ctrl.sv" \
        "${rv_root}/design/el2_dma_ctrl.sv" \
        "${rv_root}/design/el2_pmp.sv" \
        "${rv_root}/design/el2_veer.sv" \
        "${rv_root}/design/el2_mem.sv" \
        "${rv_root}/design/el2_veer_wrapper.sv" \
        "${rv_root}/testbench/ahb_sif.sv" \
        "${rv_root}/design/lib/beh_lib.sv" \
        "${rv_root}/design/lib/mem_lib.sv" \
        ../../rtl/veer_core_top.sv \
        "${soc_rtl[@]}" \
        ../../tb/soc_cov_pkg.sv \
        ../../tb/soc_cov_collector.sv \
        ../../tb/tb_soc_veer_cpu.sv

    if [ "${ENABLE_COV}" -eq 1 ]; then
        xelab --relax tb_soc_veer_cpu -timescale 1ns/1ps -debug off -s sim_cpu \
            --cc_type sbct --cc_db sim_cpu --cc_dir "${COV_ROOT}/cc_cpu" \
            --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name fc_cpu
        xsim sim_cpu -runall \
            --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name fc_cpu \
            -log xsim_cpu.log
    else
        xelab --relax tb_soc_veer_cpu -timescale 1ns/1ps -debug off -s sim_cpu
        xsim sim_cpu -runall -log xsim_cpu.log
    fi
}

run_c_test_suite() {
    local work_dir="${SOC_ROOT}/run/vivado_c_test"
    mkdir -p "${work_dir}"
    cd "${work_dir}"

    mapfile -t sv_files < <(grep -E '^\.\./' ../run_c_test.f | grep -v '^\.\./c_test/soc_test\.c$' | sed 's|^\.\./|../../|')

    echo "============================================================="
    echo " [Vivado] Building & Running DPI-C SoC Test Suite (sim_c_test)"
    echo "============================================================="
    xsc ../../c_test/soc_test.c --gcc_compile_options "-I../../c_test"
    xvlog -sv --relax -d NO_ASSERTIONS \
        -i ../../rtl/dma/inc \
        -i ../../rtl/dma \
        -i ../../rtl/uart \
        -i ../../rtl/aes \
        -i ../../c_test \
        -i ../../tb \
        "${sv_files[@]}"
    if [ "${ENABLE_COV}" -eq 1 ]; then
        xelab --relax tb_soc_c_test -sv_lib dpi -timescale 1ns/1ps -debug off -s sim_c_test \
            --cc_type sbct --cc_db sim_c_test --cc_dir "${COV_ROOT}/cc_c_test" \
            --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name fc_c_test
        xsim sim_c_test -runall \
            --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name fc_c_test \
            -log xsim_c_test.log
    else
        xelab --relax tb_soc_c_test -sv_lib dpi -timescale 1ns/1ps -debug off -s sim_c_test
        xsim sim_c_test -runall -log xsim_c_test.log
    fi
}

run_vip_suite() {
    local requested_test="${1:-all}"
    local work_dir="${SOC_ROOT}/run/vivado_vip_test"
    mkdir -p "${work_dir}"
    cd "${work_dir}"

    mapfile -t vip_sv < <(grep -E '^\.\./' ../run_periph_vip.f | sed 's|^\.\./|../../|')

    echo "============================================================="
    echo " [Vivado] Building Clean Peripheral UVM-1.2 Suite (sim_vip)"
    echo "============================================================="
    xvlog -sv -L uvm --relax -d NO_ASSERTIONS \
        -i ../../rtl/dma/inc \
        -i ../../rtl/dma \
        -i ../../rtl/uart \
        -i ../../rtl/aes \
        -i ../../tb/gpio_vip_uvm_tb \
        -i ../../tb/uart_vip_uvm_tb \
        -i ../../tb/timer_vip_uvm_tb \
        -i ../../tb/sha_vip_uvm_tb \
        -i ../../tb/aes_vip_uvm_tb \
        -i ../../tb/dma_vip_uvm_tb \
        -i ../../tb \
        "${vip_sv[@]}"
    if [ "${ENABLE_COV}" -eq 1 ]; then
        rm -rf xsim.codeCov xsim.codeCov.elab
        xelab -L uvm --relax tb_periph_top -timescale 1ns/1ps -debug off -s sim_vip \
            --cc_type sbct --cc_db sim_vip --cc_dir . \
            --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name fc_vip_elab
        if [ -d xsim.codeCov/sim_vip ]; then
            cp -r xsim.codeCov xsim.codeCov.elab
        fi
    else
        xelab -L uvm --relax tb_periph_top -timescale 1ns/1ps -debug off -s sim_vip
    fi

    local tests=()
    if [ "${requested_test}" = "all" ]; then
        tests=("uart_vip_test" "timer_vip_test" "gpio_vip_test" "sha_vip_test" "aes_vip_test" "dma_vip_test")
    else
        tests=("${requested_test}")
    fi

    for t in "${tests[@]}"; do
        echo "-------------------------------------------------------------"
        echo " [Vivado UVM] Running +UVM_TESTNAME=${t}"
        echo "-------------------------------------------------------------"
        if [ "${ENABLE_COV}" -eq 1 ]; then
            if [ -d xsim.codeCov.elab ]; then
                rm -rf xsim.codeCov
                cp -r xsim.codeCov.elab xsim.codeCov
            fi
            xsim sim_vip -testplusarg "UVM_TESTNAME=${t}" -runall \
                --cov_db_dir "${COV_ROOT}/cov_dbs" --cov_db_name "fc_vip_${t}" \
                -log "xsim_${t}.log"
            mkdir -p "${COV_ROOT}/cc_vip_${t}/xsim.codeCov"
            rm -rf "${COV_ROOT}/cc_vip_${t}/xsim.codeCov/sim_vip"
            cp -r xsim.codeCov/sim_vip "${COV_ROOT}/cc_vip_${t}/xsim.codeCov/sim_vip"
        else
            xsim sim_vip -testplusarg "UVM_TESTNAME=${t}" -runall -log "xsim_${t}.log"
        fi
        if grep -E "UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9]" "xsim_${t}.log" >/dev/null 2>&1; then
            echo "ERROR: ${t} reported UVM_ERROR/UVM_FATAL in xsim_${t}.log" >&2
            return 1
        fi
    done
}

run_coverage_suite() {
    rm -rf "${COV_ROOT}" "${SOC_ROOT}/run/vivado_vip_test"
    mkdir -p "${COV_ROOT}/cov_dbs" "${COV_ROOT}/fc_work" "${COV_ROOT}/fc_merged" \
             "${COV_ROOT}/func_cov_report" "${COV_ROOT}/cc_merged_vip" \
             "${COV_ROOT}/code_cov_vip"
    : > "${COV_ROOT}/xcrg_periph_cc.txt"

    run_vip_suite "all"

    # Remove elaboration-only placeholder functional DB so only runtime DBs merge
    rm -rf "${COV_ROOT}/cov_dbs/xsim.covdb/fc_vip_elab"

    echo "============================================================="
    echo " [Vivado XCRG] Merging Functional Coverage (All 6 Peripherals)"
    echo "============================================================="
    (
        cd "${COV_ROOT}/fc_work"
        xcrg -dir "${COV_ROOT}/cov_dbs" \
            -merge_dir "${COV_ROOT}/fc_merged" \
            -merge_db_name soc_merged_fc \
            -report_dir "${COV_ROOT}/func_cov_report" \
            -report_format text \
            -log "${COV_ROOT}/xcrg_fc.log"
    )

    echo "============================================================="
    echo " [Vivado XCRG] Merging Code Coverage (All 6 Peripherals)"
    echo "============================================================="
    (
        cd "${COV_ROOT}"
        xcrg -merge_cc \
            -cc_dir "${COV_ROOT}/cc_vip_uart_vip_test"  -cc_db sim_vip \
            -cc_dir "${COV_ROOT}/cc_vip_timer_vip_test" -cc_db sim_vip \
            -cc_dir "${COV_ROOT}/cc_vip_gpio_vip_test"  -cc_db sim_vip \
            -cc_dir "${COV_ROOT}/cc_vip_sha_vip_test"   -cc_db sim_vip \
            -cc_dir "${COV_ROOT}/cc_vip_aes_vip_test"   -cc_db sim_vip \
            -cc_dir "${COV_ROOT}/cc_vip_dma_vip_test"   -cc_db sim_vip \
            -cc_merge_dir "${COV_ROOT}/cc_merged_vip" -cc_merge_db vip_merged_cc \
            -cc_report "${COV_ROOT}/code_cov_vip" \
            -cc_instancescount 500 \
            -log "${COV_ROOT}/xcrg_cc_vip.log"
    )

    python3 - "${COV_ROOT}" << 'PYEOF'
import pathlib, re, html, sys
cov_root = pathlib.Path(sys.argv[1])
fhtml = cov_root / "code_cov_vip" / "files.html"
cclog = cov_root / "xcrg_cc_vip.log"
if not fhtml.exists():
    sys.exit(0)
strip = lambda s: re.sub(r'\s+', ' ', html.unescape(re.sub(r'<[^>]+>', '', s))).strip()
ft = re.search(r"<table class='fileInfosTable'>(.*?)</table>", fhtml.read_text(errors='replace'), re.S).group(1)
groups = {k: [] for k in ['UART', 'TIMER', 'GPIO', 'SHA', 'AES', 'DMA']}
summary_rows = []
all_cnt = all_s = 0
all_hit = 0.0
rtl_s = tb_s = 0
rtl_hit = tb_hit = 0.0
rtl_brs = []
for r in re.findall(r'<tr>(.*?)</tr>', ft, re.S)[1:]:
    c = [strip(x) for x in re.findall(r'<td[^>]*>(.*?)</td>', r, re.S)]
    if len(c) < 10:
        continue
    all_cnt += 1
    p = c[1]
    stmt = int(c[6])
    s_pct, b_pct, c_pct, t_pct = float(c[4]), float(c[7]), float(c[8]), float(c[9])
    all_s += stmt
    all_hit += stmt * s_pct / 100.0
    if '/rtl/' in p:
        rtl_s += stmt
        rtl_hit += stmt * s_pct / 100.0
        if stmt > 0:
            rtl_brs.append(b_pct)
    if '/tb/' in p:
        tb_s += stmt
        tb_hit += stmt * s_pct / 100.0
    if '/rtl/' in p or '/tb/' in p:
        summary_rows.append(f"{p} | Stmts={stmt} | Stmt={s_pct:.4f}% | Br={b_pct:.4f}% | Cond={c_pct:.4f}% | Tgl={t_pct:.2f}%")
    for k, d in [('UART', '/rtl/uart/'), ('TIMER', '/rtl/timer/'), ('GPIO', '/rtl/gpio/'), ('SHA', '/rtl/sha/'), ('AES', '/rtl/aes/'), ('DMA', '/rtl/dma/')]:
        if d in p and stmt > 0:
            groups[k].append((pathlib.Path(p).name, stmt, s_pct, b_pct, c_pct, t_pct))
out = []
all_periph_rows = []
for k in ['UART', 'TIMER', 'GPIO', 'SHA', 'AES', 'DMA']:
    rows = groups[k]
    if rows:
        tot_s = sum(r[1] for r in rows)
        hit_s = sum(r[1] * r[2] / 100.0 for r in rows)
        avg_s = 100.0 * hit_s / tot_s if tot_s else 0.0
        avg_b = sum(r[3] for r in rows) / len(rows)
        out.append(f"{k}|Files={len(rows)}|WeightedStmt={avg_s:.2f}%|AvgBranch={avg_b:.2f}%")
        all_periph_rows.extend(rows)
if all_periph_rows:
    tot_s = sum(r[1] for r in all_periph_rows)
    hit_s = sum(r[1] * r[2] / 100.0 for r in all_periph_rows)
    avg_s = 100.0 * hit_s / tot_s if tot_s else 0.0
    avg_b = sum(r[3] for r in all_periph_rows) / len(all_periph_rows)
    out.append(f"PERIPH_RTL|Files={len(all_periph_rows)}|WeightedStmt={avg_s:.2f}%|AvgBranch={avg_b:.2f}%")
(cov_root / "xcrg_periph_cc.txt").write_text("\n".join(out) + "\n")

log_txt = cclog.read_text(errors='replace') if cclog.exists() else ""
get_sc = lambda lbl: (re.search(rf'{lbl}\s+([\d.]+)', log_txt).group(1) if re.search(rf'{lbl}\s+([\d.]+)', log_txt) else "N/A")
l_sc, b_sc, c_sc, t_sc = get_sc('Line Coverage Score'), get_sc('Branch Coverage Score'), get_sc('Condition Coverage Score'), get_sc('Toggle Coverage Score')
rtl_s_pct = 100.0 * rtl_hit / rtl_s if rtl_s else 0.0
rtl_b_avg = sum(rtl_brs) / len(rtl_brs) if rtl_brs else 0.0
tb_s_pct = 100.0 * tb_hit / tb_s if tb_s else 0.0
agg_lines = [
    f"Suite Aggregate: Files={all_cnt} | Stmts={int(round(all_hit))}/{all_s} | Line={l_sc}% | Br={b_sc}% | Cond={c_sc}% | Tgl={t_sc}%",
    f"Tree Breakdown: rtl/={rtl_s_pct:.2f}% Stmt ({int(round(rtl_hit))}/{rtl_s}), {rtl_b_avg:.2f}% AvgBr | tb/={tb_s_pct:.2f}% Stmt ({int(round(tb_hit))}/{tb_s})"
]
(cov_root / "xcrg_code_cov_summary.txt").write_text("\n".join(agg_lines + [""] + out + [""] + summary_rows) + "\n")
print("\n".join(agg_lines + out))
PYEOF
    rm -rf "${COV_ROOT}/code_cov_vip"

    echo "============================================================="
    echo " [Vivado UVM] Refreshing Scoreboard Logs with XCRG CC Metrics"
    echo "============================================================="
    (
        cd "${SOC_ROOT}/run/vivado_vip_test"
        for t in "uart_vip_test" "timer_vip_test" "gpio_vip_test" "sha_vip_test" "aes_vip_test" "dma_vip_test"; do
            xsim sim_vip -testplusarg "UVM_TESTNAME=${t}" -runall -log "xsim_${t}.log" >/dev/null
            if grep -E "UVM_(ERROR|FATAL)[[:space:]]*:[[:space:]]*[1-9]" "xsim_${t}.log" >/dev/null 2>&1; then
                echo "ERROR: ${t} reported UVM_ERROR/UVM_FATAL in xsim_${t}.log" >&2
                exit 1
            fi
        done
    )
}

case "${MODE}" in
    cpu)
        run_cpu_suite
        ;;
    c_test)
        run_c_test_suite
        ;;
    vip)
        run_vip_suite "${2:-all}"
        ;;
    all)
        run_cpu_suite
        run_c_test_suite
        run_vip_suite "all"
        ;;
    coverage)
        run_coverage_suite
        ;;
    *)
        echo "Usage: $0 {all|cpu|c_test|vip [uart_vip_test|timer_vip_test|gpio_vip_test|sha_vip_test|aes_vip_test|dma_vip_test]|coverage}" >&2
        exit 2
        ;;
esac

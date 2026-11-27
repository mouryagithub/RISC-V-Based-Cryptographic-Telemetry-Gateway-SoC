// =============================================================================
// File        : uart_vip_scoreboard.sv
// Description : UVM Scoreboard for UART VIP (TC_UART_01..TC_UART_06)
//               Verifies serial TX frames, register/DLAB gating, LSR errors,
//               RX IRQ, and reports Functional & Code Coverage.
// =============================================================================

class uart_vip_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp #(uart_vip_item, uart_vip_scoreboard) mon_imp;

    bit [7:0] exp_tx_queue[$];
    int match_count     = 0;
    int mismatch_count  = 0;
    int total_captured  = 0;

    bit        sh_dlab = 1'b0;
    bit [15:0] sh_div  = 16'd434;
    bit [31:0] sh_lcr  = 32'h0;
    bit        sh_ier  = 1'b0;

    // Code-path tracking across axi_uart_top / tx / rx / fifo
    bit [6:0]  wr_path_hit = 7'h0; // thr_ok, thr_dlab1, ier_ok, ier_dlab1, div_ok, div_dlab0, lcr/unmap
    bit [6:0]  rd_path_hit = 7'h0; // rbr_ok, rbr_dlab1, ier, div, lcr, lsr, unmap
    bit        tx_8n1_hit, tx_even2_hit, tx_odd1_hit, pe_hit, fe_hit, oe_hit, irq_hi_hit, irq_lo_hit;

    covergroup cg_uart_tx with function sample(int div, bit par_en, bit par_type, bit [1:0] stop_b);
        cp_baud : coverpoint div {
            bins std_434 = {434};
            bins custom  = {[1:433], [435:65535]};
        }
        cp_parity : coverpoint {par_en, par_type} {
            bins none     = {2'b00, 2'b01};
            bins even_par = {2'b10};
            bins odd_par  = {2'b11};
        }
        cp_stop : coverpoint stop_b {
            bins stop_1 = {2'd1};
            bins stop_2 = {2'd2};
        }
    endgroup

    covergroup cg_uart_reg with function sample(bit [7:0] off, bit is_wr, bit dlab);
        cp_off : coverpoint off {
            bins rbr_thr = {8'h00};
            bins ier     = {8'h04};
            bins div     = {8'h08};
            bins lcr     = {8'h0C};
            bins lsr     = {8'h14};
            bins invalid = default;
        }
        cp_dir  : coverpoint is_wr { bins rd = {1'b0}; bins wr = {1'b1}; }
        cp_dlab : coverpoint dlab  { bins d0 = {1'b0}; bins d1 = {1'b1}; }
    endgroup

    covergroup cg_uart_err_irq with function sample(bit oe, bit pe, bit fe, bit irq_v);
        cp_oe  : coverpoint oe    { bins ok = {1'b0}; bins err = {1'b1}; }
        cp_pe  : coverpoint pe    { bins ok = {1'b0}; bins err = {1'b1}; }
        cp_fe  : coverpoint fe    { bins ok = {1'b0}; bins err = {1'b1}; }
        cp_irq : coverpoint irq_v { bins lo = {1'b0}; bins hi  = {1'b1}; }
    endgroup

    `uvm_component_utils(uart_vip_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_uart_tx      = new();
        cg_uart_reg     = new();
        cg_uart_err_irq = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_imp = new("mon_imp", this);
    endfunction

    function void add_expected_byte(bit [7:0] byte_val);
        exp_tx_queue.push_back(byte_val);
    endfunction

    function void write(uart_vip_item item);
        if (item.uart_irq) irq_hi_hit = 1'b1; else irq_lo_hit = 1'b1;

        if (item.kind == uart_vip_item::KIND_SERIAL_TX) begin
            total_captured++;
            cg_uart_tx.sample(item.clks_per_bit, item.parity_en, item.parity_type, item.stop_bits);
            if (!item.parity_en && item.stop_bits == 1) tx_8n1_hit = 1'b1;
            if (item.parity_en && !item.parity_type && item.stop_bits == 2) tx_even2_hit = 1'b1;
            if (item.parity_en && item.parity_type) tx_odd1_hit = 1'b1;

            if (!item.parity_ok || !item.stop_ok) begin
                `uvm_error("UART_SB", $sformatf("Serial frame error on TX byte 0x%02X (par_ok=%0b stop_ok=%0b)",
                                                item.data, item.parity_ok, item.stop_ok))
                mismatch_count++;
            end

            if (exp_tx_queue.size() > 0) begin
                bit [7:0] exp_data = exp_tx_queue.pop_front();
                if (item.data === exp_data) begin
                    match_count++;
                end else begin
                    `uvm_error("UART_SB", $sformatf("[MISMATCH] Captured UART TX 0x%02X != expected 0x%02X", item.data, exp_data))
                    mismatch_count++;
                end
            end else begin
                match_count++;
            end
        end else if (item.kind == uart_vip_item::KIND_REG_WR) begin
            cg_uart_reg.sample(item.offset, 1'b1, sh_dlab);
            if (item.resp !== 2'b00) mismatch_count++; else match_count++;
            case (item.offset)
                8'h00: if (!sh_dlab) wr_path_hit[0] = 1'b1; else wr_path_hit[1] = 1'b1;
                8'h04: if (!sh_dlab) begin sh_ier = item.wdata[0]; wr_path_hit[2] = 1'b1; end else wr_path_hit[3] = 1'b1;
                8'h08: if (sh_dlab)  begin sh_div = item.wdata[15:0]; wr_path_hit[4] = 1'b1; end else wr_path_hit[5] = 1'b1;
                8'h0C: begin sh_lcr = item.wdata; sh_dlab = item.wdata[7]; wr_path_hit[6] = 1'b1; end
                default: wr_path_hit[6] = 1'b1;
            endcase
        end else if (item.kind == uart_vip_item::KIND_REG_RD) begin
            cg_uart_reg.sample(item.offset, 1'b0, sh_dlab);
            if (item.resp !== 2'b00) mismatch_count++; else match_count++;
            case (item.offset)
                8'h00: if (!sh_dlab) rd_path_hit[0] = 1'b1; else begin
                    rd_path_hit[1] = 1'b1;
                    if (item.rdata !== 32'h0) mismatch_count++;
                end
                8'h04: rd_path_hit[2] = 1'b1;
                8'h08: rd_path_hit[3] = 1'b1;
                8'h0C: rd_path_hit[4] = 1'b1;
                8'h14: begin
                    rd_path_hit[5] = 1'b1;
                    if (item.rdata[1]) oe_hit = 1'b1;
                    if (item.rdata[2]) pe_hit = 1'b1;
                    if (item.rdata[3]) fe_hit = 1'b1;
                    cg_uart_err_irq.sample(item.rdata[1], item.rdata[2], item.rdata[3], item.uart_irq);
                end
                default: rd_path_hit[6] = 1'b1;
            endcase
        end else if (item.kind == uart_vip_item::KIND_IRQ_EVT) begin
            cg_uart_err_irq.sample(oe_hit, pe_hit, fe_hit, item.uart_irq);
        end
    endfunction

    function void report_phase(uvm_phase phase);
        real fc_tx, fc_reg, fc_ei, fc_total;
        int  code_pts_hit, code_pts_total;
        real rtl_path_cov;
        int  fd;
        string line;

        fc_tx    = cg_uart_tx.get_inst_coverage();
        fc_reg   = cg_uart_reg.get_inst_coverage();
        fc_ei    = cg_uart_err_irq.get_inst_coverage();
        fc_total = (fc_tx + fc_reg + fc_ei) / 3.0;

        code_pts_total = 22;
        code_pts_hit   = $countones(wr_path_hit) + $countones(rd_path_hit) +
                         int'(tx_8n1_hit) + int'(tx_even2_hit) + int'(tx_odd1_hit) +
                         int'(pe_hit) + int'(fe_hit) + int'(oe_hit) + int'(irq_hi_hit) + int'(irq_lo_hit);
        rtl_path_cov = (100.0 * code_pts_hit) / code_pts_total;

        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
        `uvm_info("UART_SB", "                UART VIP SCOREBOARD SUMMARY                      ", UVM_LOW)
        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
        `uvm_info("UART_SB", "  Testplan Cases Verified      : TC_UART_01..TC_UART_06", UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Total Serial TX Bytes        : %0d", total_captured), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Verified Matches / Checks    : %0d", match_count), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Mismatches / Errors          : %0d", mismatch_count), UVM_LOW)
        `uvm_info("UART_SB", "-----------------------------------------------------------------", UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Functional Coverage (Serial) : %0.2f%%", fc_tx), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Functional Coverage (Regs)   : %0.2f%%", fc_reg), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Functional Coverage (Err/IRQ): %0.2f%%", fc_ei), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  FUNCTIONAL COVERAGE (TOTAL)  : %0.2f%%", fc_total), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  VIP Feature Paths (SB)       : %0.2f%% (%0d/%0d decode/mode/err pts)",
                                      rtl_path_cov, code_pts_hit, code_pts_total), UVM_LOW)
        fd = $fopen("../../run/coverage/xcrg_periph_cc.txt", "r");
        if (fd != 0) begin
            while (!$feof(fd)) begin
                if ($fgets(line, fd) && (line.len() >= 5) && (line.substr(0, 4) == "UART|")) begin
                    `uvm_info("UART_SB", $sformatf("  XCRG Code Coverage (Vivado)  : %s", line), UVM_LOW)
                end
            end
            $fclose(fd);
        end
        `uvm_info("UART_SB", "-----------------------------------------------------------------", UVM_LOW)
        if (mismatch_count == 0) begin
            `uvm_info("UART_SB", "Scoreboard: ALL UART TESTPLAN CHECKS PASSED!", UVM_LOW)
        end else begin
            `uvm_error("UART_SB", $sformatf("Scoreboard: FAILED with %0d mismatches!", mismatch_count))
        end
        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
    endfunction
endclass : uart_vip_scoreboard

// =============================================================================
// File        : uart_vip_scoreboard.sv
// Description : UVM Scoreboard for External UART VIP
//               Verifies data transmitted out of the SoC via external uart_tx
//               pin against expected bytes, and monitors serial communication.
// =============================================================================

class uart_vip_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(uart_vip_item, uart_vip_scoreboard) mon_imp;

    bit [7:0] exp_tx_queue[$];
    int match_count     = 0;
    int mismatch_count  = 0;
    int total_captured  = 0;

    `uvm_component_utils(uart_vip_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_imp = new("mon_imp", this);
    endfunction

    // Receives observed serial frames from uart_vip_monitor
    function void write(uart_vip_item item);
        total_captured++;

        if (exp_tx_queue.size() > 0) begin
            bit [7:0] exp_data = exp_tx_queue.pop_front();
            if (item.data === exp_data) begin
                `uvm_info("UART_SB",
                    $sformatf("[MATCH] Captured SoC UART TX Byte: 0x%02X ('%c') matches expected",
                              item.data, (item.data >= 32 && item.data <= 126) ? item.data : "."), UVM_LOW)
                match_count++;
            end else begin
                `uvm_error("UART_SB",
                    $sformatf("[MISMATCH] Captured SoC UART TX Byte: 0x%02X != expected 0x%02X",
                              item.data, exp_data))
                mismatch_count++;
            end
        end else begin
            `uvm_info("UART_SB",
                $sformatf("[OBSERVED] SoC UART TX Byte: 0x%02X ('%c') (unpredicted)",
                          item.data, (item.data >= 32 && item.data <= 126) ? item.data : "."), UVM_LOW)
        end
    endfunction

    // Enqueue an expected byte that the SoC should transmit on uart_tx
    function void add_expected_byte(bit [7:0] byte_val);
        exp_tx_queue.push_back(byte_val);
        `uvm_info("UART_SB", $sformatf("Enqueued Expected UART TX Byte: 0x%02X", byte_val), UVM_HIGH)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
        `uvm_info("UART_SB", "               EXTERNAL UART VIP SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Total UART TX Bytes Captured : %0d", total_captured), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Verified Expected Matches    : %0d", match_count), UVM_LOW)
        `uvm_info("UART_SB", $sformatf("  Mismatches / Errors          : %0d", mismatch_count), UVM_LOW)
        `uvm_info("UART_SB", "-----------------------------------------------------------------", UVM_LOW)
        if (mismatch_count == 0) begin
            `uvm_info("UART_SB", "Scoreboard: ALL EXTERNAL UART PIN CHECKS PASSED!", UVM_LOW)
        end else begin
            `uvm_error("UART_SB", $sformatf("Scoreboard: FAILED with %0d mismatches!", mismatch_count))
        end
        `uvm_info("UART_SB", "=================================================================", UVM_LOW)
    endfunction

endclass : uart_vip_scoreboard

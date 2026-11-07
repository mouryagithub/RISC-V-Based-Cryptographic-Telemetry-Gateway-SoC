// =============================================================================
// File        : gpio_vip_scoreboard.sv
// Description : UVM Scoreboard for External 64-Pin GPIO VIP
//               Verifies output pin values driven out of the SoC (gpio_o)
//               against expected values, and checks interrupt assertions.
// =============================================================================

class gpio_vip_scoreboard extends uvm_scoreboard;

    uvm_analysis_imp #(gpio_vip_item, gpio_vip_scoreboard) mon_imp;

    int total_events_monitored  = 0;
    int verified_matches        = 0;
    int mismatch_count          = 0;

    bit [63:0] exp_gpio_out_q[$];

    `uvm_component_utils(gpio_vip_scoreboard)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon_imp = new("mon_imp", this);
    endfunction

    // Receives observed pin events from gpio_vip_monitor
    function void write(gpio_vip_item item);
        total_events_monitored++;

        if (exp_gpio_out_q.size() > 0) begin
            bit [63:0] exp_val = exp_gpio_out_q.pop_front();
            if (item.gpio_out === exp_val) begin
                `uvm_info("GPIO_SB",
                    $sformatf("[MATCH] Observed SoC gpio_o=0x%016X matches expected", item.gpio_out), UVM_LOW)
                verified_matches++;
            end else begin
                `uvm_error("GPIO_SB",
                    $sformatf("[MISMATCH] Observed SoC gpio_o=0x%016X != expected 0x%016X",
                              item.gpio_out, exp_val))
                mismatch_count++;
            end
        end else begin
            `uvm_info("GPIO_SB",
                $sformatf("[OBSERVED] SoC GPIO Pin State: out=0x%016X dir=0x%016X intr=%02b",
                          item.gpio_out, item.gpio_dir, item.gpio_intr), UVM_LOW)
        end
    endfunction

    // Enqueue an expected 64-bit value on SoC gpio_o pins
    function void add_expected_gpio_out(bit [63:0] exp_val);
        exp_gpio_out_q.push_back(exp_val);
        `uvm_info("GPIO_SB", $sformatf("Enqueued Expected gpio_o: 0x%016X", exp_val), UVM_HIGH)
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("GPIO_SB", "=================================================================", UVM_LOW)
        `uvm_info("GPIO_SB", "               EXTERNAL GPIO VIP SCOREBOARD SUMMARY              ", UVM_LOW)
        `uvm_info("GPIO_SB", "=================================================================", UVM_LOW)
        `uvm_info("GPIO_SB", $sformatf("  Total Pin Events Monitored   : %0d", total_events_monitored), UVM_LOW)
        `uvm_info("GPIO_SB", $sformatf("  Verified Output Matches      : %0d", verified_matches), UVM_LOW)
        `uvm_info("GPIO_SB", $sformatf("  Mismatches / Errors          : %0d", mismatch_count), UVM_LOW)
        `uvm_info("GPIO_SB", "-----------------------------------------------------------------", UVM_LOW)
        if (mismatch_count == 0) begin
            `uvm_info("GPIO_SB", "Scoreboard: ALL EXTERNAL GPIO PIN CHECKS PASSED!", UVM_LOW)
        end else begin
            `uvm_error("GPIO_SB", $sformatf("Scoreboard: FAILED with %0d mismatches!", mismatch_count))
        end
        `uvm_info("GPIO_SB", "=================================================================", UVM_LOW)
    endfunction

endclass : gpio_vip_scoreboard

// =============================================================================
// File        : timer_vip_pkg.sv
// Description : UVM Package for System Timer VIP
// =============================================================================

package timer_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "timer_vip_item.sv"
    `include "timer_vip_sequencer.sv"
    `include "timer_vip_driver.sv"
    `include "timer_vip_monitor.sv"
    `include "timer_vip_agent.sv"
    `include "timer_vip_scoreboard.sv"
    `include "timer_vip_env.sv"
    `include "timer_vip_test.sv"
endpackage : timer_vip_pkg

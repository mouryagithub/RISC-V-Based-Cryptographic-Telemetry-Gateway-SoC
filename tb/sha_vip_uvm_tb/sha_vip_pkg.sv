// =============================================================================
// File        : sha_vip_pkg.sv
// Description : UVM Package for SHA-256 VIP
// =============================================================================

package sha_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "sha_vip_item.sv"
    `include "sha_vip_sequencer.sv"
    `include "sha_vip_driver.sv"
    `include "sha_vip_monitor.sv"
    `include "sha_vip_agent.sv"
    `include "sha_vip_scoreboard.sv"
    `include "sha_vip_env.sv"
    `include "sha_vip_test.sv"
endpackage : sha_vip_pkg

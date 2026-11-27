// =============================================================================
// File        : aes_vip_pkg.sv
// Description : UVM Package for AES-256 VIP
// =============================================================================

package aes_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "aes_vip_item.sv"
    `include "aes_vip_sequencer.sv"
    `include "aes_vip_driver.sv"
    `include "aes_vip_monitor.sv"
    `include "aes_vip_agent.sv"
    `include "aes_vip_scoreboard.sv"
    `include "aes_vip_env.sv"
    `include "aes_vip_test.sv"
endpackage : aes_vip_pkg

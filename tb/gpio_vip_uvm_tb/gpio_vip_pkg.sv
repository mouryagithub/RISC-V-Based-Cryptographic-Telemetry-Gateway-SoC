// =============================================================================
// File        : gpio_vip_pkg.sv
// Description : UVM Package for External 64-Pin GPIO VIP (SoC Boundary Pins)
// =============================================================================

package gpio_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "gpio_vip_item.sv"
    `include "gpio_vip_sequencer.sv"
    `include "gpio_vip_driver.sv"
    `include "gpio_vip_monitor.sv"
    `include "gpio_vip_agent.sv"
    `include "gpio_vip_scoreboard.sv"
    `include "gpio_vip_env.sv"
    `include "gpio_vip_test.sv"
endpackage : gpio_vip_pkg

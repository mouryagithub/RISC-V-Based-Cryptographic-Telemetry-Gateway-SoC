// =============================================================================
// File        : dma_vip_pkg.sv
// Description : UVM Package for AXI DMA VIP
// =============================================================================

package dma_vip_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "dma_vip_item.sv"
    `include "dma_vip_sequencer.sv"
    `include "dma_vip_driver.sv"
    `include "dma_vip_monitor.sv"
    `include "dma_vip_agent.sv"
    `include "dma_vip_scoreboard.sv"
    `include "dma_vip_env.sv"
    `include "dma_vip_test.sv"
endpackage : dma_vip_pkg

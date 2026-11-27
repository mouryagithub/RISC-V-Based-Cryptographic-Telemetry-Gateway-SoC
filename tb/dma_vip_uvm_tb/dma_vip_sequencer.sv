// =============================================================================
// File        : dma_vip_sequencer.sv
// Description : UVM Sequencer for AXI DMA VIP
// =============================================================================

class dma_vip_sequencer extends uvm_sequencer #(dma_vip_item);
    `uvm_component_utils(dma_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : dma_vip_sequencer

// =============================================================================
// File        : sha_vip_sequencer.sv
// Description : UVM Sequencer for SHA-256 VIP
// =============================================================================

class sha_vip_sequencer extends uvm_sequencer #(sha_vip_item);
    `uvm_component_utils(sha_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : sha_vip_sequencer

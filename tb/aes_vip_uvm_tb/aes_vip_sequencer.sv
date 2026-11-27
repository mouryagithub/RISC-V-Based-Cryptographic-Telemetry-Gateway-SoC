// =============================================================================
// File        : aes_vip_sequencer.sv
// Description : UVM Sequencer for AES-256 VIP
// =============================================================================

class aes_vip_sequencer extends uvm_sequencer #(aes_vip_item);
    `uvm_component_utils(aes_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : aes_vip_sequencer

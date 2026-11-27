// =============================================================================
// File        : timer_vip_sequencer.sv
// Description : UVM Sequencer for System Timer VIP
// =============================================================================

class timer_vip_sequencer extends uvm_sequencer #(timer_vip_item);
    `uvm_component_utils(timer_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass : timer_vip_sequencer

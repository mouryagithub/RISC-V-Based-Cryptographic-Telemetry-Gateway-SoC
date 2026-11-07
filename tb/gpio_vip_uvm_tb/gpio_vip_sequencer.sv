// =============================================================================
// File        : gpio_vip_sequencer.sv
// Description : UVM Sequencer for External 64-Pin GPIO VIP
// =============================================================================

class gpio_vip_sequencer extends uvm_sequencer #(gpio_vip_item);

    `uvm_component_utils(gpio_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : gpio_vip_sequencer

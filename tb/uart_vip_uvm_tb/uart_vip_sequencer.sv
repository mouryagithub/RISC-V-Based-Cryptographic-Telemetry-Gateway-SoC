// =============================================================================
// File        : uart_vip_sequencer.sv
// Description : UVM Sequencer for External UART VIP
// =============================================================================

class uart_vip_sequencer extends uvm_sequencer #(uart_vip_item);

    `uvm_component_utils(uart_vip_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass : uart_vip_sequencer

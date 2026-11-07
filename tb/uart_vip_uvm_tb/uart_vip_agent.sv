// =============================================================================
// File        : uart_vip_agent.sv
// Description : UVM Agent for External UART VIP
// =============================================================================

class uart_vip_agent extends uvm_agent;

    uart_vip_driver     drv;
    uart_vip_monitor    mon;
    uart_vip_sequencer  seqr;

    uvm_analysis_port #(uart_vip_item) ap;

    `uvm_component_utils(uart_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = uart_vip_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            drv  = uart_vip_driver::type_id::create("drv", this);
            seqr = uart_vip_sequencer::type_id::create("seqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        ap = mon.ap;

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass : uart_vip_agent

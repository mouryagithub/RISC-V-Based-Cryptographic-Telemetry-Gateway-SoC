// =============================================================================
// File        : aes_vip_agent.sv
// Description : UVM Agent for AES-256 VIP
// =============================================================================

class aes_vip_agent extends uvm_agent;
    aes_vip_driver    drv;
    aes_vip_monitor   mon;
    aes_vip_sequencer seqr;
    uvm_analysis_port #(aes_vip_item) ap;

    `uvm_component_utils(aes_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = aes_vip_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = aes_vip_driver::type_id::create("drv", this);
            seqr = aes_vip_sequencer::type_id::create("seqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass : aes_vip_agent

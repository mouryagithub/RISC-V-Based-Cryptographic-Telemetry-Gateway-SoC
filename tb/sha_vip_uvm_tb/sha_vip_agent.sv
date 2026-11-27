// =============================================================================
// File        : sha_vip_agent.sv
// Description : UVM Agent for SHA-256 VIP
// =============================================================================

class sha_vip_agent extends uvm_agent;
    sha_vip_driver    drv;
    sha_vip_monitor   mon;
    sha_vip_sequencer seqr;
    uvm_analysis_port #(sha_vip_item) ap;

    `uvm_component_utils(sha_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        mon = sha_vip_monitor::type_id::create("mon", this);
        if (get_is_active() == UVM_ACTIVE) begin
            drv  = sha_vip_driver::type_id::create("drv", this);
            seqr = sha_vip_sequencer::type_id::create("seqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        ap = mon.ap;
        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction
endclass : sha_vip_agent

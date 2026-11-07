// =============================================================================
// File        : gpio_vip_agent.sv
// Description : UVM Agent for External 64-Pin GPIO VIP
// =============================================================================

class gpio_vip_agent extends uvm_agent;

    gpio_vip_driver     drv;
    gpio_vip_monitor    mon;
    gpio_vip_sequencer  seqr;

    uvm_analysis_port #(gpio_vip_item) ap;

    `uvm_component_utils(gpio_vip_agent)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        mon = gpio_vip_monitor::type_id::create("mon", this);

        if (get_is_active() == UVM_ACTIVE) begin
            drv  = gpio_vip_driver::type_id::create("drv", this);
            seqr = gpio_vip_sequencer::type_id::create("seqr", this);
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        ap = mon.ap;

        if (get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(seqr.seq_item_export);
        end
    endfunction

endclass : gpio_vip_agent

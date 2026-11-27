// =============================================================================
// File        : dma_vip_env.sv
// Description : UVM Environment for AXI DMA VIP
// =============================================================================

class dma_vip_env extends uvm_env;
    dma_vip_agent      agent;
    dma_vip_scoreboard sb;

    `uvm_component_utils(dma_vip_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = dma_vip_agent::type_id::create("agent", this);
        sb    = dma_vip_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.mon_imp);
    endfunction
endclass : dma_vip_env

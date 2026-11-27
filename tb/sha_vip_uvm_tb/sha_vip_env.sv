// =============================================================================
// File        : sha_vip_env.sv
// Description : UVM Environment for SHA-256 VIP
// =============================================================================

class sha_vip_env extends uvm_env;
    sha_vip_agent      agent;
    sha_vip_scoreboard sb;

    `uvm_component_utils(sha_vip_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = sha_vip_agent::type_id::create("agent", this);
        sb    = sha_vip_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.mon_imp);
    endfunction
endclass : sha_vip_env

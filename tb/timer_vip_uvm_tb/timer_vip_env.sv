// =============================================================================
// File        : timer_vip_env.sv
// Description : UVM Environment for System Timer VIP
// =============================================================================

class timer_vip_env extends uvm_env;
    timer_vip_agent      agent;
    timer_vip_scoreboard sb;

    `uvm_component_utils(timer_vip_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = timer_vip_agent::type_id::create("agent", this);
        sb    = timer_vip_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.mon_imp);
    endfunction
endclass : timer_vip_env

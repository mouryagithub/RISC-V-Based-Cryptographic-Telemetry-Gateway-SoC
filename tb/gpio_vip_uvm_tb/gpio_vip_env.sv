// =============================================================================
// File        : gpio_vip_env.sv
// Description : UVM Environment for External 64-Pin GPIO VIP
// =============================================================================

class gpio_vip_env extends uvm_env;

    gpio_vip_agent       agent;
    gpio_vip_scoreboard  sb;

    `uvm_component_utils(gpio_vip_env)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = gpio_vip_agent::type_id::create("agent", this);
        sb    = gpio_vip_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.ap.connect(sb.mon_imp);
    endfunction

endclass : gpio_vip_env

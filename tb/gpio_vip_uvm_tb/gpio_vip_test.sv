class gpio_vip_test extends uvm_test;
    gpio_vip_env env;
    `uvm_component_utils(gpio_vip_test)

    function new(string n, uvm_component p);
        super.new(n, p);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = gpio_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("GPIO_VIP_TEST", "=== GPIO VIP Test Started ===", UVM_LOW)
        #2000;
        `uvm_info("GPIO_VIP_TEST", "=== GPIO VIP Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

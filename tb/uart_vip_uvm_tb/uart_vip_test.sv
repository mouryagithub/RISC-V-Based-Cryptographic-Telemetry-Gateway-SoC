class uart_vip_test extends uvm_test;
    uart_vip_env env;
    `uvm_component_utils(uart_vip_test)

    function new(string n, uvm_component p);
        super.new(n, p);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        `uvm_info("UART_VIP_TEST", "=== UART VIP Test Started ===", UVM_LOW)
        #2000;
        `uvm_info("UART_VIP_TEST", "=== UART VIP Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

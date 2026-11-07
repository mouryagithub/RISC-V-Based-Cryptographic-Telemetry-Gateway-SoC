// =============================================================================
// File        : uart_vip_test.sv
// Description : Sequences and Tests for External UART VIP
//               Injects serial frames directly onto the SoC's external uart_rx pin.
// =============================================================================

// -----------------------------------------------------------------------------
// Sequence: Base UART Sequence
// -----------------------------------------------------------------------------
class uart_base_seq extends uvm_sequence #(uart_vip_item);
    `uvm_object_utils(uart_base_seq)

    function new(string name = "uart_base_seq");
        super.new(name);
    endfunction

    // Helper task to send an external serial byte into SoC uart_rx
    task send_byte(input bit [7:0] byte_data, input int clks = 434);
        uart_vip_item item = uart_vip_item::type_id::create("send_item");
        start_item(item);
        item.data         = byte_data;
        item.clks_per_bit = clks;
        item.direction    = uart_vip_item::DIR_RX_INTO_SOC;
        finish_item(item);
    endtask
endclass : uart_base_seq


// -----------------------------------------------------------------------------
// Sequence: Inject Test Bytes into SoC uart_rx
// -----------------------------------------------------------------------------
class uart_inject_seq extends uart_base_seq;
    `uvm_object_utils(uart_inject_seq)

    function new(string name = "uart_inject_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("UART_SEQ", ">>> Starting External UART Serial Injection Suite...", UVM_LOW)

        // Inject test characters into SoC
        send_byte(8'h5A); // 'Z'
        #100000;
        send_byte(8'hC9);
        #100000;
        send_byte(8'hBE);
        #100000;

        `uvm_info("UART_SEQ", ">>> External UART Serial Injection Suite Completed.", UVM_LOW)
    endtask
endclass : uart_inject_seq


// -----------------------------------------------------------------------------
// Standalone UVM Test for External UART VIP
// -----------------------------------------------------------------------------
class uart_vip_test extends uvm_test;
    uart_vip_env env;

    `uvm_component_utils(uart_vip_test)

    function new(string name = "uart_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = uart_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        uart_inject_seq seq;
        phase.raise_objection(this);

        `uvm_info("UART_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("UART_VIP_TEST", "   Starting External Pin UART VIP Verification Test          ", UVM_LOW)
        `uvm_info("UART_VIP_TEST", "=============================================================", UVM_LOW)

        seq = uart_inject_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #500000;
        `uvm_info("UART_VIP_TEST", "=== External UART VIP Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : uart_vip_test

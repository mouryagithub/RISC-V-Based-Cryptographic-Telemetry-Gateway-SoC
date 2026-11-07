// =============================================================================
// File        : gpio_vip_test.sv
// Description : Sequences and Tests for External 64-Pin GPIO VIP
//               Drives external input stimuli directly onto the SoC's gpio_i[63:0] pins.
// =============================================================================

// -----------------------------------------------------------------------------
// Sequence: Base GPIO Sequence
// -----------------------------------------------------------------------------
class gpio_base_seq extends uvm_sequence #(gpio_vip_item);
    `uvm_object_utils(gpio_base_seq)

    function new(string name = "gpio_base_seq");
        super.new(name);
    endfunction

    // Helper task to drive external pin values into SoC gpio_i
    task drive_pins(input bit [63:0] val, input int hold = 5);
        gpio_vip_item item = gpio_vip_item::type_id::create("pin_item");
        start_item(item);
        item.gpio_in     = val;
        item.hold_cycles = hold;
        finish_item(item);
    endtask
endclass : gpio_base_seq


// -----------------------------------------------------------------------------
// Sequence: Apply External Stimulus Vectors to SoC gpio_i
// -----------------------------------------------------------------------------
class gpio_stimulus_seq extends gpio_base_seq;
    `uvm_object_utils(gpio_stimulus_seq)

    function new(string name = "gpio_stimulus_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("GPIO_SEQ", ">>> Starting External GPIO Pin Stimulus Suite...", UVM_LOW)

        // 1. Initial All-Zero
        drive_pins(64'h0000_0000_0000_0000, 10);

        // 2. Drive Bank 0 and Bank 1 test pattern
        drive_pins(64'h9ABC_DEF0_1234_5678, 20);

        // 3. Drive Alternating Checkerboard Pattern
        drive_pins(64'hA5A5_5A5A_5A5A_A5A5, 20);

        // 4. Drive Walking 1s (Bit 0 transition for edge interrupts)
        drive_pins(64'h0000_0000_0000_0001, 15);
        drive_pins(64'h0000_0000_0000_0000, 15);
        drive_pins(64'h0000_0000_0000_0001, 15);

        // 5. High-Z / Inactive return
        drive_pins(64'h0000_0000_0000_0000, 10);

        `uvm_info("GPIO_SEQ", ">>> External GPIO Pin Stimulus Suite Completed.", UVM_LOW)
    endtask
endclass : gpio_stimulus_seq


// -----------------------------------------------------------------------------
// Standalone UVM Test for External GPIO VIP
// -----------------------------------------------------------------------------
class gpio_vip_test extends uvm_test;
    gpio_vip_env env;

    `uvm_component_utils(gpio_vip_test)

    function new(string name = "gpio_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = gpio_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        gpio_stimulus_seq seq;
        phase.raise_objection(this);

        `uvm_info("GPIO_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("GPIO_VIP_TEST", "   Starting External Pin GPIO VIP Verification Test          ", UVM_LOW)
        `uvm_info("GPIO_VIP_TEST", "=============================================================", UVM_LOW)

        seq = gpio_stimulus_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #1000;
        `uvm_info("GPIO_VIP_TEST", "=== External GPIO VIP Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : gpio_vip_test

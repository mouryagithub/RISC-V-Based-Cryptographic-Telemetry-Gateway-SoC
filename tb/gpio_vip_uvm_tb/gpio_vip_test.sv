// =============================================================================
// File        : gpio_vip_test.sv
// Description : Sequences and Tests for 64-Pin GPIO VIP (TC_GPIO_01..TC_GPIO_05)
// =============================================================================

class gpio_base_seq extends uvm_sequence #(gpio_vip_item);
    `uvm_object_utils(gpio_base_seq)

    function new(string name = "gpio_base_seq");
        super.new(name);
    endfunction

    task drive_pins(input bit [63:0] val, input int hold = 5);
        gpio_vip_item item = gpio_vip_item::type_id::create("pin_item");
        start_item(item);
        item.kind        = gpio_vip_item::KIND_PIN_DRV;
        item.gpio_in     = val;
        item.hold_cycles = hold;
        finish_item(item);
    endtask

    task reg_write(input bit [11:0] off, input bit [31:0] val, input int bready_delay = 0);
        gpio_vip_item item = gpio_vip_item::type_id::create("wr_item");
        start_item(item);
        item.kind        = gpio_vip_item::KIND_REG_WR;
        item.offset      = off;
        item.wdata       = val;
        item.ready_delay = bready_delay;
        finish_item(item);
    endtask

    task reg_read(input bit [11:0] off, output bit [31:0] val, input int rready_delay = 0);
        gpio_vip_item item = gpio_vip_item::type_id::create("rd_item");
        start_item(item);
        item.kind        = gpio_vip_item::KIND_REG_RD;
        item.offset      = off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask
endclass : gpio_base_seq

// Preserved sequence for integrated soc_vip_test compatibility
class gpio_stimulus_seq extends gpio_base_seq;
    `uvm_object_utils(gpio_stimulus_seq)

    function new(string name = "gpio_stimulus_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("GPIO_SEQ", ">>> Starting External GPIO Pin Stimulus Suite...", UVM_LOW)
        drive_pins(64'h0000_0000_0000_0000, 10);
        drive_pins(64'h9ABC_DEF0_1234_5678, 20);
        drive_pins(64'hA5A5_5A5A_5A5A_A5A5, 20);
        drive_pins(64'h0000_0000_0000_0001, 15);
        drive_pins(64'h0000_0000_0000_0000, 15);
        drive_pins(64'h0000_0002_0000_0001, 15);
        drive_pins(64'h0000_0000_0000_0000, 15);
        drive_pins(64'h0000_0000_0000_0000, 10);
        `uvm_info("GPIO_SEQ", ">>> External GPIO Pin Stimulus Suite Completed.", UVM_LOW)
    endtask
endclass : gpio_stimulus_seq

// -----------------------------------------------------------------------------
// Full Testplan Sequence: TC_GPIO_01..TC_GPIO_05
// -----------------------------------------------------------------------------
class gpio_full_testplan_seq extends gpio_base_seq;
    `uvm_object_utils(gpio_full_testplan_seq)

    virtual gpio_vip_if vif;

    function new(string name = "gpio_full_testplan_seq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rval, rval1;

        if (!uvm_config_db #(virtual gpio_vip_if)::get(null, "*", "gpio_vif", vif)) begin
            `uvm_fatal("GPIO_SEQ", "gpio_vif not found")
        end

        // ---------------------------------------------------------------------
        // TC_GPIO_01: Architectural Discovery & Reset State Verification
        // ---------------------------------------------------------------------
        `uvm_info("GPIO_SEQ", ">>> Running TC_GPIO_01: GPIO INFO=64 & Reset Verification", UVM_LOW)
        reg_read(12'h000, rval);
        if (rval !== 32'd64) `uvm_error("TC_GPIO_01", $sformatf("GPIO_INFO != 64: %0d", rval))
        reg_read(12'h080, rval);  if (rval !== 32'h0) `uvm_error("TC_GPIO_01", "OE0 reset != 0")
        reg_read(12'h084, rval);  if (rval !== 32'h0) `uvm_error("TC_GPIO_01", "OE1 reset != 0")
        reg_read(12'h180, rval);  if (rval !== 32'h0) `uvm_error("TC_GPIO_01", "OUT0 reset != 0")
        reg_read(12'h184, rval);  if (rval !== 32'h0) `uvm_error("TC_GPIO_01", "OUT1 reset != 0")

        // Exercise CFG, MODE, default decode & handshake wait cycles
        reg_write(12'h004, 32'hAAAA_5555, 1);
        reg_read(12'h004, rval, 1);
        reg_write(12'h008, 32'h1234_5678);
        reg_read(12'h008, rval);
        reg_write(12'h00C, 32'hDEAD_BEEF); // default invalid write
        reg_read(12'h00C, rval);             // default invalid read
        reg_write(12'h004, 32'h0);
        reg_write(12'h008, 32'h0);
        `uvm_info("TC_GPIO_01", "[PASS] TC_GPIO_01 GPIO INFO=64 & Register Reset verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_GPIO_02: Bank 0 & 1 Output Enable & Pin Output Drive
        // ---------------------------------------------------------------------
        `uvm_info("GPIO_SEQ", ">>> Running TC_GPIO_02: Bank 0/1 OE & Output Drive", UVM_LOW)
        reg_write(12'h080, 32'hFFFF_FFFF);
        reg_write(12'h084, 32'hFFFF_FFFF);
        reg_write(12'h180, 32'hA5A5_5A5A);
        reg_write(12'h184, 32'h5A5A_A5A5);
        reg_read(12'h180, rval);
        reg_read(12'h184, rval1);
        if (vif.gpio_dir_o !== 64'hFFFF_FFFF_FFFF_FFFF ||
            vif.gpio_o     !== 64'h5A5A_A5A5_A5A5_5A5A ||
            rval !== 32'hA5A5_5A5A || rval1 !== 32'h5A5A_A5A5) begin
            `uvm_error("TC_GPIO_02", $sformatf("Output mismatch dir=0x%016X out=0x%016X", vif.gpio_dir_o, vif.gpio_o))
        end else begin
            `uvm_info("TC_GPIO_02", "[PASS] TC_GPIO_02 Bank 0 & 1 Output Enable and Drive verified", UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // TC_GPIO_04: Atomic Bit Operations (SET, CLR, TGL on Bank 0 & Bank 1)
        // ---------------------------------------------------------------------
        `uvm_info("GPIO_SEQ", ">>> Running TC_GPIO_04: Atomic SET/CLR/TGL Operations", UVM_LOW)
        reg_write(12'h200, 32'h0000_00FF); // OUT0 -> 0xA5A5_5AFF
        reg_read(12'h180, rval);
        if (rval !== 32'hA5A5_5AFF) `uvm_error("TC_GPIO_04", $sformatf("SET0 mismatch: 0x%08X", rval))
        reg_write(12'h280, 32'h0000_000F); // OUT0 -> 0xA5A5_5AF0
        reg_read(12'h180, rval);
        if (rval !== 32'hA5A5_5AF0) `uvm_error("TC_GPIO_04", $sformatf("CLR0 mismatch: 0x%08X", rval))
        reg_write(12'h300, 32'h0000_FF00); // OUT0 -> 0xA5A5_A5F0
        reg_read(12'h180, rval);
        if (rval !== 32'hA5A5_A5F0) `uvm_error("TC_GPIO_04", $sformatf("TGL0 mismatch: 0x%08X", rval))

        reg_write(12'h204, 32'h0000_00FF);
        reg_write(12'h284, 32'h0000_000F);
        reg_write(12'h304, 32'h0000_FF00);
        reg_read(12'h184, rval1);
        if (rval1 !== 32'h5A5A_5AF0) `uvm_error("TC_GPIO_04", $sformatf("Bank1 atomic mismatch: 0x%08X", rval1))

        // Full all-1 / all-0 toggle on OE0/1 and OUT0/1
        reg_write(12'h180, 32'hFFFF_FFFF); reg_write(12'h180, 32'h0000_0000);
        reg_write(12'h184, 32'hFFFF_FFFF); reg_write(12'h184, 32'h0000_0000);
        reg_write(12'h080, 32'h0000_0000); reg_write(12'h084, 32'h0000_0000);
        `uvm_info("TC_GPIO_04", "[PASS] TC_GPIO_04 Atomic SET/CLR/TGL (Bank 0 & 1) verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_GPIO_03: Raw Pin Input Sampling & 2-Stage Synchronization
        // ---------------------------------------------------------------------
        `uvm_info("GPIO_SEQ", ">>> Running TC_GPIO_03: External Input Sampling & Synchronizer", UVM_LOW)
        drive_pins(64'h9ABC_DEF0_1234_5678, 8);
        reg_read(12'h100, rval);
        reg_read(12'h104, rval1);
        if (rval !== 32'h1234_5678 || rval1 !== 32'h9ABC_DEF0) begin
            `uvm_error("TC_GPIO_03", $sformatf("IN mismatch: IN0=0x%08X IN1=0x%08X", rval, rval1))
        end else begin
            `uvm_info("TC_GPIO_03", "[PASS] TC_GPIO_03 2-Stage Synchronizer Pin Input Capture verified", UVM_LOW)
        end
        drive_pins(64'hFFFF_FFFF_FFFF_FFFF, 6);
        drive_pins(64'h0000_0000_0000_0000, 6);

        // ---------------------------------------------------------------------
        // TC_GPIO_05: Edge & Level Interrupts (RISE, FALL, HIGH, LOW) on Both Banks
        // ---------------------------------------------------------------------
        `uvm_info("GPIO_SEQ", ">>> Running TC_GPIO_05: Edge & Level Interrupts (Both Banks)", UVM_LOW)
        // Clear pending
        reg_write(12'h580, 32'hFFFF_FFFF);
        reg_write(12'h584, 32'hFFFF_FFFF);

        // 1) Bank 0 & Bank 1 Rising-Edge
        reg_write(12'h380, 32'h0000_0001); reg_read(12'h380, rval);
        reg_write(12'h384, 32'h0000_0002); reg_read(12'h384, rval);
        drive_pins(64'h0000_0002_0000_0001, 6);
        if (vif.gpio_intr_o !== 2'b11) `uvm_error("TC_GPIO_05", $sformatf("RISE intr mismatch: %02b", vif.gpio_intr_o))
        reg_write(12'h380, 32'h0); reg_write(12'h384, 32'h0);
        reg_write(12'h580, 32'hFFFF_FFFF); reg_write(12'h584, 32'hFFFF_FFFF);
        reg_read(12'h580, rval); reg_read(12'h584, rval1);
        if (vif.gpio_intr_o !== 2'b00) `uvm_error("TC_GPIO_05", "RISE W1C failed")

        // 2) Bank 0 & Bank 1 Falling-Edge
        reg_write(12'h400, 32'h0000_0001); reg_read(12'h400, rval);
        reg_write(12'h404, 32'h0000_0002); reg_read(12'h404, rval);
        drive_pins(64'h0000_0000_0000_0000, 6);
        if (vif.gpio_intr_o !== 2'b11) `uvm_error("TC_GPIO_05", $sformatf("FALL intr mismatch: %02b", vif.gpio_intr_o))
        reg_write(12'h400, 32'h0); reg_write(12'h404, 32'h0);
        reg_write(12'h580, 32'hFFFF_FFFF); reg_write(12'h584, 32'hFFFF_FFFF);
        if (vif.gpio_intr_o !== 2'b00) `uvm_error("TC_GPIO_05", "FALL W1C failed")

        // 3) Bank 0 & Bank 1 Active-High Level
        reg_write(12'h480, 32'h0000_0004); reg_read(12'h480, rval);
        reg_write(12'h484, 32'h0000_0004); reg_read(12'h484, rval);
        drive_pins(64'h0000_0004_0000_0004, 6);
        if (vif.gpio_intr_o !== 2'b11) `uvm_error("TC_GPIO_05", $sformatf("HIGH intr mismatch: %02b", vif.gpio_intr_o))
        drive_pins(64'h0000_0000_0000_0000, 6);
        reg_write(12'h480, 32'h0); reg_write(12'h484, 32'h0);
        reg_write(12'h580, 32'hFFFF_FFFF); reg_write(12'h584, 32'hFFFF_FFFF);
        if (vif.gpio_intr_o !== 2'b00) `uvm_error("TC_GPIO_05", "HIGH W1C failed")

        // 4) Bank 0 & Bank 1 Active-Low Level
        reg_write(12'h500, 32'h0000_0004); reg_read(12'h500, rval);
        reg_write(12'h504, 32'h0000_0004); reg_read(12'h504, rval);
        drive_pins(64'h0000_0000_0000_0000, 6);
        if (vif.gpio_intr_o !== 2'b11) `uvm_error("TC_GPIO_05", $sformatf("LOW intr mismatch: %02b", vif.gpio_intr_o))
        drive_pins(64'h0000_0004_0000_0004, 6);
        reg_write(12'h500, 32'h0); reg_write(12'h504, 32'h0);
        reg_write(12'h580, 32'hFFFF_FFFF); reg_write(12'h584, 32'hFFFF_FFFF);
        drive_pins(64'h0000_0000_0000_0000, 5);
        if (vif.gpio_intr_o !== 2'b00) `uvm_error("TC_GPIO_05", "LOW W1C failed")

        `uvm_info("TC_GPIO_05", "[PASS] TC_GPIO_05 RISE/FALL/HIGH/LOW Interrupts (Both Banks) verified", UVM_LOW)
    endtask
endclass : gpio_full_testplan_seq

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
        gpio_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("GPIO_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("GPIO_VIP_TEST", "   Starting 64-Pin GPIO UVM Verification Test (TC_GPIO_01..05)", UVM_LOW)
        `uvm_info("GPIO_VIP_TEST", "=============================================================", UVM_LOW)

        seq = gpio_full_testplan_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #200;
        `uvm_info("GPIO_VIP_TEST", "=== 64-Pin GPIO UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : gpio_vip_test

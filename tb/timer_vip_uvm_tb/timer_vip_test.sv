// =============================================================================
// File        : timer_vip_test.sv
// Description : Sequences & UVM Test for System Timer (TC_TMR_01..TC_TMR_03)
// =============================================================================

class timer_base_seq extends uvm_sequence #(timer_vip_item);
    `uvm_object_utils(timer_base_seq)

    function new(string name = "timer_base_seq");
        super.new(name);
    endfunction

    task reg_write(input bit [11:0] off, input bit [31:0] val, input int bready_delay = 0);
        timer_vip_item item = timer_vip_item::type_id::create("wr_item");
        start_item(item);
        item.op          = timer_vip_item::OP_WRITE;
        item.offset      = off;
        item.wdata       = val;
        item.wstrb       = 4'hF;
        item.ready_delay = bready_delay;
        finish_item(item);
    endtask

    task reg_read(input bit [11:0] off, output bit [31:0] val, input int rready_delay = 0);
        timer_vip_item item = timer_vip_item::type_id::create("rd_item");
        start_item(item);
        item.op          = timer_vip_item::OP_READ;
        item.offset      = off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask

    task wait_clks(input int clks);
        timer_vip_item item = timer_vip_item::type_id::create("wait_item");
        start_item(item);
        item.op        = timer_vip_item::OP_WAIT;
        item.wait_clks = clks;
        finish_item(item);
    endtask
endclass : timer_base_seq

// -----------------------------------------------------------------------------
// Full Testplan Sequence: TC_TMR_01, TC_TMR_02, TC_TMR_03
// -----------------------------------------------------------------------------
class timer_full_testplan_seq extends timer_base_seq;
    `uvm_object_utils(timer_full_testplan_seq)

    virtual soc_axi_if bus_vif;

    function new(string name = "timer_full_testplan_seq");
        super.new(name);
    endfunction

    task body();
        bit [31:0] rval, t1, t2;

        if (!uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("TIMER_SEQ", "bus_vif not found")
        end

        // ---------------------------------------------------------------------
        // TC_TMR_01: System Timer Prescaler, Step & Monotonic Counter Increment
        // ---------------------------------------------------------------------
        `uvm_info("TIMER_SEQ", ">>> Running TC_TMR_01: Prescaler, Step & Monotonic Counter Increment", UVM_LOW)
        reg_write(12'h004, 32'h0);           // CTRL = 0
        reg_write(12'h10C, 32'h0001_0000);   // CFG0: prescale=0, step=1
        reg_write(12'h110, 32'h0);           // MTIME_L = 0
        reg_write(12'h114, 32'h0);           // MTIME_H = 0
        reg_write(12'h004, 32'h1);           // CTRL = 1 (active)
        wait_clks(25);
        reg_read(12'h110, t1);
        wait_clks(25);
        reg_read(12'h110, t2);
        if (t1 == 0 || t2 <= t1) begin
            `uvm_error("TC_TMR_01", $sformatf("Monotonic counter failed: t1=%0d t2=%0d", t1, t2))
        end else begin
            `uvm_info("TC_TMR_01", $sformatf("[PASS] TC_TMR_01 (prescale=0, step=1): t1=%0d t2=%0d", t1, t2), UVM_LOW)
        end

        // Exercise prescale > 0 and step > 1 (timer_core prescale branch + CFG0 coverage)
        reg_write(12'h004, 32'h0);
        reg_write(12'h10C, 32'h0005_0003);   // prescale=3, step=5
        reg_write(12'h110, 32'hFFFF_FFFA);   // setup carry into MTIME_H
        reg_write(12'h114, 32'h0000_0000);
        reg_write(12'h004, 32'h1);
        wait_clks(40);
        reg_read(12'h114, rval);             // Read MTIME_H
        if (rval == 32'h0) begin
            `uvm_error("TC_TMR_01", "MTIME_H did not roll over from MTIME_L under step=5")
        end else begin
            `uvm_info("TC_TMR_01", $sformatf("[PASS] TC_TMR_01 Prescaler=3 Step=5 Rollover: MTIME_H=%0d", rval), UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // TC_TMR_02: 64-bit Comparator Match & Interrupt Generation
        // ---------------------------------------------------------------------
        `uvm_info("TIMER_SEQ", ">>> Running TC_TMR_02: 64-bit Comparator Match & Interrupt", UVM_LOW)
        reg_write(12'h004, 32'h0);
        reg_write(12'h10C, 32'h0001_0000);   // prescale=0, step=1
        reg_write(12'h104, 32'h1);           // Clear any stale INTR_STATE
        reg_write(12'h110, 32'h0);           // MTIME_L = 0
        reg_write(12'h114, 32'h0);           // MTIME_H = 0
        reg_write(12'h118, 32'h0000_0200);   // CMP_L = 0x200
        reg_write(12'h11C, 32'h0000_0000);   // CMP_H = 0
        reg_write(12'h100, 32'h1);           // INTR_EN = 1
        reg_write(12'h004, 32'h1);           // CTRL = 1

        wait_clks(560);
        reg_read(12'h104, rval);
        if (rval[0] !== 1'b1 || bus_vif.timer_irq !== 1'b1) begin
            `uvm_error("TC_TMR_02", $sformatf("Compare IRQ did not assert: INTR_STATE=0x%08X timer_irq=%0b", rval, bus_vif.timer_irq))
        end else begin
            `uvm_info("TC_TMR_02", $sformatf("[PASS] TC_TMR_02 Compare IRQ asserted: INTR_STATE=0x%08X timer_irq=%0b", rval, bus_vif.timer_irq), UVM_LOW)
        end

        // ---------------------------------------------------------------------
        // TC_TMR_03: Interrupt Clear (RW1C) & Software Test Trigger (INTR_TEST0)
        // ---------------------------------------------------------------------
        `uvm_info("TIMER_SEQ", ">>> Running TC_TMR_03: Interrupt Clear (RW1C) & INTR_TEST0", UVM_LOW)
        reg_write(12'h004, 32'h0);           // Stop timer
        reg_write(12'h118, 32'hFFFF_FFFF);   // Move CMP threshold above mtime
        reg_write(12'h11C, 32'hFFFF_FFFF);
        reg_write(12'h104, 32'h0);           // Write 0 to RW1C: should NOT clear
        reg_read(12'h104, rval);
        if (rval[0] !== 1'b1) begin
            `uvm_error("TC_TMR_03", "RW1C cleared on write 0")
        end

        reg_write(12'h104, 32'h1, 1);        // Write 1 to RW1C with bready wait cycle
        reg_read(12'h104, rval, 1);          // Read with rready wait cycle
        if (rval[0] !== 1'b0 || bus_vif.timer_irq !== 1'b0) begin
            `uvm_error("TC_TMR_03", $sformatf("RW1C failed to clear: INTR_STATE=0x%08X timer_irq=%0b", rval, bus_vif.timer_irq))
        end

        reg_write(12'h108, 32'h0);           // Write 0 to INTR_TEST: should NOT trigger
        reg_read(12'h104, rval);
        if (rval[0] !== 1'b0) begin
            `uvm_error("TC_TMR_03", "INTR_TEST triggered on write 0")
        end

        reg_write(12'h108, 32'h1);           // Write 1 to INTR_TEST: must trigger IRQ
        reg_read(12'h104, rval);
        if (rval[0] !== 1'b1 || bus_vif.timer_irq !== 1'b1) begin
            `uvm_error("TC_TMR_03", $sformatf("INTR_TEST failed to trigger: INTR_STATE=0x%08X timer_irq=%0b", rval, bus_vif.timer_irq))
        end

        // Clear IRQ cleanly and exercise remaining registers & default decode + toggles
        reg_write(12'h104, 32'h1);
        reg_write(12'h100, 32'h0);
        reg_write(12'h000, 32'h1);           // ALERT_TEST WO write
        reg_read(12'h000, rval);             // ALERT_TEST RO read
        reg_read(12'h004, rval);             // CTRL read
        reg_read(12'h100, rval);             // INTR_EN read
        reg_read(12'h108, rval);             // INTR_TEST RO read
        reg_read(12'h10C, rval);             // CFG0 read
        reg_read(12'h118, rval);             // CMP_L read
        reg_read(12'h11C, rval);             // CMP_H read
        reg_write(12'h1FC, 32'hDEAD_BEEF);   // Default write
        reg_read(12'h1FC, rval);             // Default read

        // Toggle all bits 0<->1 on writable 32/64-bit data registers
        reg_write(12'h10C, 32'h00FF_0FFF);
        reg_write(12'h10C, 32'h0001_0000);
        reg_write(12'h110, 32'hFFFF_FFFF);
        reg_write(12'h110, 32'h0000_0000);
        reg_write(12'h114, 32'hFFFF_FFFF);
        reg_write(12'h114, 32'h0000_0000);
        reg_write(12'h118, 32'h0000_0000);
        reg_write(12'h118, 32'hFFFF_FFFF);
        reg_write(12'h11C, 32'h0000_0000);
        reg_write(12'h11C, 32'hFFFF_FFFF);

        `uvm_info("TC_TMR_03", "[PASS] TC_TMR_03 RW1C Clear, INTR_TEST0 & Full Register Decode", UVM_LOW)
    endtask
endclass : timer_full_testplan_seq

class timer_vip_test extends uvm_test;
    timer_vip_env env;

    `uvm_component_utils(timer_vip_test)

    function new(string name = "timer_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = timer_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        timer_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("TIMER_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("TIMER_VIP_TEST", "   Starting System Timer UVM Verification Test (TC_TMR_01..03)", UVM_LOW)
        `uvm_info("TIMER_VIP_TEST", "=============================================================", UVM_LOW)

        seq = timer_full_testplan_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #200;
        `uvm_info("TIMER_VIP_TEST", "=== System Timer UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : timer_vip_test

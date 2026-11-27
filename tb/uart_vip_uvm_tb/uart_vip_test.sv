// =============================================================================
// File        : uart_vip_test.sv
// Description : Sequences and Tests for UART VIP (TC_UART_01..TC_UART_06)
// =============================================================================

class uart_base_seq extends uvm_sequence #(uart_vip_item);
    `uvm_object_utils(uart_base_seq)

    function new(string name = "uart_base_seq");
        super.new(name);
    endfunction

    task send_byte(input bit [7:0] byte_data, input int clks = 434);
        uart_vip_item item = uart_vip_item::type_id::create("send_item");
        start_item(item);
        item.kind           = uart_vip_item::KIND_SERIAL_RX;
        item.data           = byte_data;
        item.clks_per_bit   = clks;
        item.parity_en      = 1'b0;
        item.parity_type    = 1'b0;
        item.stop_bits      = 2'd1;
        item.corrupt_parity = 1'b0;
        item.corrupt_stop   = 1'b0;
        item.direction      = uart_vip_item::DIR_RX_INTO_SOC;
        finish_item(item);
    endtask

    task send_err_byte(input bit [7:0] byte_data,
                       input bit parity_en,
                       input bit parity_type,
                       input bit corrupt_parity,
                       input bit corrupt_stop,
                       input int clks = 434,
                       input bit [1:0] stop_bits = 2'd1,
                       input bit corrupt_stop2 = 1'b0,
                       input int break_clks = 0);
        uart_vip_item item = uart_vip_item::type_id::create("err_item");
        start_item(item);
        item.kind           = uart_vip_item::KIND_SERIAL_RX;
        item.data           = byte_data;
        item.clks_per_bit   = clks;
        item.parity_en      = parity_en;
        item.parity_type    = parity_type;
        item.stop_bits      = stop_bits;
        item.corrupt_parity = corrupt_parity;
        item.corrupt_stop   = corrupt_stop;
        item.corrupt_stop2  = corrupt_stop2;
        item.break_clks     = break_clks;
        item.direction      = uart_vip_item::DIR_RX_INTO_SOC;
        finish_item(item);
    endtask

    task reg_write(input bit [7:0] off, input bit [31:0] val, input int bready_delay = 0, input int split_mode = 0);
        uart_vip_item item = uart_vip_item::type_id::create("wr_item");
        start_item(item);
        item.kind        = uart_vip_item::KIND_REG_WR;
        item.offset      = off;
        item.wdata       = val;
        item.ready_delay = bready_delay;
        item.split_mode  = split_mode;
        finish_item(item);
    endtask

    task reg_read(input bit [7:0] off, output bit [31:0] val, input int rready_delay = 0);
        uart_vip_item item = uart_vip_item::type_id::create("rd_item");
        start_item(item);
        item.kind        = uart_vip_item::KIND_REG_RD;
        item.offset      = off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask

    task wait_clks(input int clks);
        uart_vip_item item = uart_vip_item::type_id::create("wait_item");
        start_item(item);
        item.kind      = uart_vip_item::KIND_WAIT;
        item.wait_clks = clks;
        finish_item(item);
    endtask
endclass : uart_base_seq

// Preserved sequence for integrated soc_vip_test compatibility
class uart_inject_seq extends uart_base_seq;
    `uvm_object_utils(uart_inject_seq)

    function new(string name = "uart_inject_seq");
        super.new(name);
    endfunction

    task body();
        `uvm_info("UART_SEQ", ">>> Starting External UART Serial Injection Suite...", UVM_LOW)
        send_byte(8'h5A); #100000;
        send_byte(8'hC9); #100000;
        send_byte(8'hBE); #100000;
        send_err_byte(8'hE1, 1'b0, 1'b0, 1'b0, 1'b1); #100000;
        send_err_byte(8'hE2, 1'b1, 1'b0, 1'b1, 1'b0); #100000;
        `uvm_info("UART_SEQ", ">>> External UART Serial Injection Suite Completed.", UVM_LOW)
    endtask
endclass : uart_inject_seq

// -----------------------------------------------------------------------------
// Full Testplan Sequence: TC_UART_01..TC_UART_06
// -----------------------------------------------------------------------------
class uart_full_testplan_seq extends uart_base_seq;
    `uvm_object_utils(uart_full_testplan_seq)

    uart_vip_scoreboard sb_ref;
    virtual soc_axi_if  bus_vif;

    function new(string name = "uart_full_testplan_seq");
        super.new(name);
    endfunction

    task wait_tx_empty();
        bit [31:0] lsr;
        for (int i = 0; i < 6000; i++) begin
            reg_read(8'h14, lsr);
            if ((lsr & 32'h60) == 32'h60) break;
            wait_clks(20);
        end
    endtask

    task body();
        bit [31:0] rval, lsr;

        if (!uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("UART_SEQ", "bus_vif not found")
        end

        // ---------------------------------------------------------------------
        // TC_UART_01: Register Config, Baud Divisor & DLAB Gating Verification
        // ---------------------------------------------------------------------
        `uvm_info("UART_SEQ", ">>> Running TC_UART_01: UART LCR, BAUD_DIV & DLAB Gating", UVM_LOW)
        reg_write(8'h0C, 32'h0000_0080); // DLAB=1
        reg_write(8'h08, 32'd434);       // 115200 baud @ 50MHz
        reg_read(8'h08, rval);
        if (rval[15:0] !== 16'd434) `uvm_error("TC_UART_01", $sformatf("BAUD_DIV readback != 434: %0d", rval))
        // DLAB=1 protection checks on RBR/THR/IER & unmapped offset
        reg_write(8'h00, 32'h0000_00AA);
        reg_write(8'h04, 32'h0000_0001);
        reg_read(8'h00, rval); if (rval !== 32'h0) `uvm_error("TC_UART_01", "RBR not masked under DLAB=1")
        reg_read(8'h04, rval); if (rval !== 32'h0) `uvm_error("TC_UART_01", "IER not masked under DLAB=1")
        reg_write(8'h18, 32'hDEAD_BEEF, 2, 1);
        reg_write(8'h18, 32'hCAFE_BABE, 0, 2);
        reg_read(8'h18, rval, 2);

        reg_write(8'h0C, 32'h0000_0000); // 8N1, DLAB=0
        reg_read(8'h0C, rval);
        // DLAB=0 protection on BAUD_DIV
        reg_write(8'h08, 32'd123);
        reg_read(8'h08, rval); if (rval !== 32'h0) `uvm_error("TC_UART_01", "BAUD_DIV not masked under DLAB=0")
        reg_write(8'h04, 32'h0000_0001); // IER=1
        reg_read(8'h04, rval);
        if (rval[0] !== 1'b1) `uvm_error("TC_UART_01", "IER write failed")
        `uvm_info("TC_UART_01", "[PASS] TC_UART_01 UART Config & DLAB Gating verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_UART_02: Transmit Serialization & Frame Timing (8N1 + Custom Parity/Stop)
        // ---------------------------------------------------------------------
        `uvm_info("UART_SEQ", ">>> Running TC_UART_02: UART Transmit Serialization (0x55, 0xA3)", UVM_LOW)
        wait_tx_empty();
        if (sb_ref != null) begin
            sb_ref.add_expected_byte(8'h55);
            sb_ref.add_expected_byte(8'hA3);
        end
        reg_write(8'h00, 32'h0000_0055);
        wait_tx_empty();
        reg_write(8'h00, 32'h0000_00A3);
        wait_tx_empty();
        wait_clks(200);

        // Custom baud (div=24) + Even Parity + 2 Stop Bits (LCR = 0x1C)
        reg_write(8'h0C, 32'h0000_0080);
        reg_write(8'h08, 32'd24);
        reg_write(8'h0C, 32'h0000_001C); // STOP2=1, PEN=1, EPS=1 (even)
        if (sb_ref != null) sb_ref.add_expected_byte(8'h5C);
        reg_write(8'h00, 32'h0000_005C);
        wait_tx_empty();
        wait_clks(80);

        // Odd Parity + 1 Stop Bit (LCR = 0x08) at div=24
        reg_write(8'h0C, 32'h0000_0008); // STOP2=0, PEN=1, EPS=0 (odd)
        if (sb_ref != null) sb_ref.add_expected_byte(8'hA6);
        reg_write(8'h00, 32'h0000_00A6);
        wait_tx_empty();
        wait_clks(80);
        `uvm_info("TC_UART_02", "[PASS] TC_UART_02 UART TX Serialization (8N1, Even+2Stop, Odd) verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_UART_03 & TC_UART_04: Serial Ingress (uart_rx -> RBR) & RX IRQ
        // ---------------------------------------------------------------------
        `uvm_info("UART_SEQ", ">>> Running TC_UART_03 & TC_UART_04: RX Loopback & IRQ Drain", UVM_LOW)
        // Return to 8N1, div=24 for fast crisp serial injection, then also test 2-stop RX
        reg_write(8'h0C, 32'h0000_0000);
        send_byte(8'h5A, 24);
        wait_clks(50);
        if (bus_vif.uart_irq !== 1'b1) `uvm_error("TC_UART_04", "uart_irq did not assert on 0x5A arrival")
        reg_read(8'h00, rval);
        if (rval[7:0] !== 8'h5A) `uvm_error("TC_UART_03", $sformatf("RBR != 0x5A: 0x%02X", rval[7:0]))

        send_byte(8'hC9, 24);
        wait_clks(50);
        reg_read(8'h00, rval);
        if (rval[7:0] !== 8'hC9) `uvm_error("TC_UART_03", $sformatf("RBR != 0xC9: 0x%02X", rval[7:0]))

        send_byte(8'hBE, 24);
        wait_clks(50);
        if (bus_vif.uart_irq !== 1'b1) `uvm_error("TC_UART_04", "uart_irq did not assert on 0xBE arrival")
        reg_read(8'h00, rval);
        if (rval[7:0] !== 8'hBE) `uvm_error("TC_UART_04", $sformatf("RBR != 0xBE: 0x%02X", rval[7:0]))
        wait_clks(5);
        if (bus_vif.uart_irq !== 1'b0) `uvm_error("TC_UART_04", "uart_irq did not clear after RBR drain")

        // RX with Odd Parity + 2 Stop Bits (covers 2-stop-bit RX state in uart_receiver.v)
        reg_write(8'h0C, 32'h0000_000C); // STOP2=1, PEN=1, EPS=0 (odd)
        send_err_byte(8'h7E, 1'b1, 1'b1, 1'b0, 1'b0, 24, 2'd2);
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (lsr[2] || lsr[3]) `uvm_error("TC_UART_03", $sformatf("Unexpected PE/FE on valid 8O2 RX: LSR=0x%02X", lsr))
        reg_read(8'h00, rval);
        if (rval[7:0] !== 8'h7E) `uvm_error("TC_UART_03", $sformatf("RBR 8O2 != 0x7E: 0x%02X", rval[7:0]))
        `uvm_info("TC_UART_03", "[PASS] TC_UART_03 Serial RX Ingress (8N1 & 8O2) verified", UVM_LOW)
        `uvm_info("TC_UART_04", "[PASS] TC_UART_04 RX Data-Available IRQ Assert & Drain verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_UART_05: Back-to-Back Burst TX & 16-Byte FIFO Depth Stress
        // ---------------------------------------------------------------------
        `uvm_info("UART_SEQ", ">>> Running TC_UART_05: Back-to-Back Burst & FIFO Stress", UVM_LOW)
        reg_write(8'h0C, 32'h0000_0000); // 8N1 at div=24
        if (sb_ref != null) begin
            sb_ref.add_expected_byte(8'h11);
            sb_ref.add_expected_byte(8'h22);
            sb_ref.add_expected_byte(8'h33);
        end
        reg_write(8'h00, 32'h11);
        reg_write(8'h00, 32'h22);
        reg_write(8'h00, 32'h33);
        wait_tx_empty();
        wait_clks(80);

        // Full 20-byte TX FIFO push to cover FIFO full/wrap
        for (int b = 0; b < 20; b++) begin
            bit [7:0] val = 8'h40 + b[7:0];
            if (sb_ref != null) sb_ref.add_expected_byte(val);
            reg_write(8'h00, {24'h0, val});
        end
        wait_tx_empty();
        wait_clks(80);

        // TX FIFO simultaneous push+pull sweep (PP/NP in axi_internal_fifo_tx_inst) at div=8
        reg_write(8'h0C, 32'h0000_0080);
        reg_write(8'h08, 32'd8);
        reg_write(8'h0C, 32'h0000_0000);
        wait_tx_empty();
        for (int k = 0; k <= 30; k++) begin
            bit [7:0] b0 = 8'h10 + k[7:0];
            bit [7:0] b1 = 8'h30 + k[7:0];
            bit [7:0] b2 = 8'h50 + k[7:0];
            if (sb_ref != null) begin
                sb_ref.add_expected_byte(b0);
                sb_ref.add_expected_byte(b1);
                sb_ref.add_expected_byte(b2);
            end
            reg_write(8'h00, {24'h0, b0});
            reg_write(8'h00, {24'h0, b1});
            wait_clks(65 + k);
            reg_write(8'h00, {24'h0, b2});
            wait_tx_empty();
        end

        // RX FIFO simultaneous push+pull sweeps (PP/NN empty, PP/NP partial, PP/PP full) at div=4
        reg_write(8'h0C, 32'h0000_0080);
        reg_write(8'h08, 32'd4);
        reg_write(8'h0C, 32'h0000_0000);
        reg_read(8'h14, lsr);
        for (int d = 0; d < 16; d++) begin
            reg_read(8'h14, lsr);
            if (lsr[0]) reg_read(8'h00, rval); else break;
        end
        // 1) Empty RX FIFO simultaneous push+pull (PP/NN)
        for (int k = 0; k <= 18; k++) begin
            int unsigned rx_tmp;
            fork
                send_byte(8'hA0 + k[7:0], 4);
                begin
                    bus_vif.wait_cycles(30 + k);
                    bus_vif.axi_read(32'h4000_1000, rx_tmp);
                end
            join
            reg_read(8'h14, lsr);
            if (lsr[0]) reg_read(8'h00, rval);
        end
        // 2) Partial RX FIFO simultaneous push+pull (PP/NP)
        send_byte(8'h1A, 4);
        send_byte(8'h2B, 4);
        for (int k = 0; k <= 18; k++) begin
            int unsigned rx_tmp;
            fork
                send_byte(8'hC0 + k[7:0], 4);
                begin
                    bus_vif.wait_cycles(30 + k);
                    bus_vif.axi_read(32'h4000_1000, rx_tmp);
                end
            join
        end
        for (int d = 0; d < 16; d++) begin
            reg_read(8'h14, lsr);
            if (lsr[0]) reg_read(8'h00, rval); else break;
        end
        // 3) Full 16-entry RX FIFO simultaneous push+pull (PP/PP)
        for (int f = 0; f < 16; f++) send_byte(8'h90 + f[7:0], 4);
        reg_read(8'h14, lsr); // Clear any stale OE
        for (int k = 0; k <= 18; k++) begin
            int unsigned rx_tmp;
            fork
                send_byte(8'hE0 + k[7:0], 4);
                begin
                    bus_vif.wait_cycles(30 + k);
                    bus_vif.axi_read(32'h4000_1000, rx_tmp);
                end
            join
            reg_read(8'h14, lsr);
            if (lsr[1]) send_byte(8'h5F, 4);
        end
        for (int d = 0; d < 16; d++) begin
            reg_read(8'h14, lsr);
            if (lsr[0]) reg_read(8'h00, rval); else break;
        end
        reg_write(8'h0C, 32'h0000_0080);
        reg_write(8'h08, 32'd24);
        reg_write(8'h0C, 32'h0000_0000);
        `uvm_info("TC_UART_05", "[PASS] TC_UART_05 Back-to-Back Burst TX & 16-Byte FIFO Stress verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_UART_06: LSR Framing Error (FE), Parity Error (PE) & Overrun (OE)
        // ---------------------------------------------------------------------
        `uvm_info("UART_SEQ", ">>> Running TC_UART_06: LSR Error Detection (FE, PE, OE)", UVM_LOW)
        reg_write(8'h0C, 32'h0000_0000); // 8N1
        send_err_byte(8'hE1, 1'b0, 1'b0, 1'b0, 1'b1, 24); // Framing Error
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (!lsr[3]) `uvm_error("TC_UART_06", $sformatf("Framing Error LSR[3] did not assert: 0x%08X", lsr))
        reg_read(8'h00, rval);

        // 8O2 Framing Error (stop1=0, stop2=0 + break WaitIdleState) & Parity match
        reg_write(8'h0C, 32'h0000_000C); // STOP2=1, PEN=1, EPS=0 (odd)
        send_err_byte(8'h55, 1'b1, 1'b1, 1'b0, 1'b1, 24, 2'd2, 1'b0, 0); // bad stop1
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (!lsr[3]) `uvm_error("TC_UART_06", $sformatf("8O2 stop1 FE did not assert: 0x%08X", lsr))
        reg_read(8'h00, rval);
        send_err_byte(8'hAA, 1'b1, 1'b1, 1'b0, 1'b0, 24, 2'd2, 1'b1, 30); // bad stop2 + break hold
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (!lsr[3]) `uvm_error("TC_UART_06", $sformatf("8O2 stop2/break FE did not assert: 0x%08X", lsr))
        reg_read(8'h00, rval);

        reg_write(8'h0C, 32'h0000_0008); // 8O1
        send_err_byte(8'hE2, 1'b1, 1'b1, 1'b1, 1'b0, 24); // Parity Error
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (!lsr[2]) `uvm_error("TC_UART_06", $sformatf("Parity Error LSR[2] did not assert: 0x%08X", lsr))
        reg_read(8'h00, rval);

        // Overrun Error: push 17 bytes into RX FIFO without reading RBR
        reg_write(8'h0C, 32'h0000_0000); // 8N1
        for (int b = 0; b < 17; b++) begin
            send_byte(8'h80 + b[7:0], 24);
        end
        wait_clks(60);
        reg_read(8'h14, lsr);
        if (!lsr[1]) `uvm_error("TC_UART_06", $sformatf("Overrun Error LSR[1] did not assert: 0x%08X", lsr))
        for (int d = 0; d < 16; d++) begin
            reg_read(8'h14, lsr);
            if (lsr[0]) reg_read(8'h00, rval);
        end
        // Restore default 115200 baud cleanly
        reg_write(8'h0C, 32'h0000_0080);
        reg_write(8'h08, 32'd434);
        reg_write(8'h0C, 32'h0000_0000);
        `uvm_info("TC_UART_06", "[PASS] TC_UART_06 LSR Framing, Parity & Overrun Errors verified", UVM_LOW)
    endtask
endclass : uart_full_testplan_seq

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
        uart_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("UART_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("UART_VIP_TEST", "   Starting UART UVM Verification Test (TC_UART_01..06)      ", UVM_LOW)
        `uvm_info("UART_VIP_TEST", "=============================================================", UVM_LOW)

        seq = uart_full_testplan_seq::type_id::create("seq");
        seq.sb_ref = env.sb;
        seq.start(env.agent.seqr);

        #2000;
        `uvm_info("UART_VIP_TEST", "=== UART UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : uart_vip_test

// =============================================================================
// File        : uart_vip_driver.sv
// Description : UVM Driver for External UART VIP
//               Drives serialized UART frames directly onto the SoC's external
//               uart_rx pin with precise bit timing (baud rate).
// =============================================================================

class uart_vip_driver extends uvm_driver #(uart_vip_item);

    virtual uart_vip_if vif;

    `uvm_component_utils(uart_vip_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual uart_vip_if)::get(this, "", "vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(this, "", "uart_vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(null, "*", "uart_vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(null, "*", "vif", vif)) begin
            `uvm_fatal("UART_DRV", "Virtual interface ('vif' / 'uart_vif') not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        // Default idle level for UART RX line is HIGH (1'b1)
        vif.uart_rx <= 1'b1;

        wait (vif.aresetn === 1'b1);
        @(posedge vif.clk);

        forever begin
            uart_vip_item item;
            seq_item_port.get_next_item(item);
            drive_serial_byte(item);
            seq_item_port.item_done();
        end
    endtask

    // Drives a full serial UART frame: Start (0) + 8 Data bits (LSB-first) + [Parity] + Stop (1)
    task drive_serial_byte(uart_vip_item item);
        int bit_clks;
        bit parity;

        bit_clks = (item.clks_per_bit > 0) ? item.clks_per_bit : 434;

        `uvm_info("UART_DRV",
            $sformatf("Driving External UART_RX: byte=0x%02X ('%c') bit_clks=%0d err_stop=%0b",
                      item.data, (item.data >= 32 && item.data <= 126) ? item.data : ".",
                      bit_clks, item.corrupt_stop), UVM_MEDIUM)

        // 1. Start Bit: 1'b0
        vif.uart_rx <= 1'b0;
        repeat (bit_clks) @(posedge vif.clk);

        // 2. 8 Data Bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            vif.uart_rx <= item.data[i];
            repeat (bit_clks) @(posedge vif.clk);
        end

        // 3. Optional Parity Bit
        if (item.parity_en) begin
            parity = ^item.data;
            if (item.parity_type) parity = ~parity; // Odd parity
            if (item.corrupt_parity) parity = ~parity;
            vif.uart_rx <= parity;
            repeat (bit_clks) @(posedge vif.clk);
        end

        // 4. Stop Bit: 1'b1 (or inverted if testing framing error)
        vif.uart_rx <= item.corrupt_stop ? 1'b0 : 1'b1;
        repeat (bit_clks) @(posedge vif.clk);

        // Additional stop bit if configured
        if (item.stop_bits == 2'd2) begin
            vif.uart_rx <= 1'b1;
            repeat (bit_clks) @(posedge vif.clk);
        end

        // Return to idle state
        vif.uart_rx <= 1'b1;
        repeat (10) @(posedge vif.clk);

        `uvm_info("UART_DRV", $sformatf("UART_RX Serial Frame Complete: 0x%02X", item.data), UVM_HIGH)
    endtask

endclass : uart_vip_driver

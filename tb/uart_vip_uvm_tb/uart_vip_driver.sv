// =============================================================================
// File        : uart_vip_driver.sv
// Description : UVM Driver for External UART VIP (Serial RX + AXI Regs)
// =============================================================================

class uart_vip_driver extends uvm_driver #(uart_vip_item);
    virtual uart_vip_if vif;
    virtual soc_axi_if  bus_vif;

    localparam bit [31:0] UART_BASE = 32'h4000_1000;

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
        void'(uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif));
    endfunction

    task run_phase(uvm_phase phase);
        vif.uart_rx <= 1'b1;
        wait (vif.aresetn === 1'b1);
        @(posedge vif.clk);

        forever begin
            uart_vip_item item;
            int unsigned rsp_word, rd_word;

            seq_item_port.get_next_item(item);
            case (item.kind)
                uart_vip_item::KIND_SERIAL_RX: begin
                    drive_serial_byte(item);
                end
                uart_vip_item::KIND_REG_WR: begin
                    if (bus_vif == null) `uvm_fatal("UART_DRV", "bus_vif is null for KIND_REG_WR")
                    bus_vif.axi_write_ext(UART_BASE + {24'h0, item.offset}, item.wdata, 32'hF, item.split_mode, item.ready_delay, rsp_word);
                    item.resp     = rsp_word[1:0];
                    item.uart_irq = vif.uart_irq;
                end
                uart_vip_item::KIND_REG_RD: begin
                    if (bus_vif == null) `uvm_fatal("UART_DRV", "bus_vif is null for KIND_REG_RD")
                    bus_vif.axi_read_ext(UART_BASE + {24'h0, item.offset}, item.ready_delay, rd_word, rsp_word);
                    item.rdata    = rd_word;
                    item.resp     = rsp_word[1:0];
                    item.uart_irq = vif.uart_irq;
                end
                uart_vip_item::KIND_WAIT: begin
                    repeat ((item.wait_clks > 0) ? item.wait_clks : 1) @(posedge vif.clk);
                    item.uart_irq = vif.uart_irq;
                end
                default: ;
            endcase
            seq_item_port.item_done();
        end
    endtask

    task drive_serial_byte(uart_vip_item item);
        int bit_clks;
        bit parity;

        bit_clks = (item.clks_per_bit > 0) ? item.clks_per_bit : 434;

        // 1. Start Bit: 1'b0
        vif.uart_rx <= 1'b0;
        repeat (bit_clks) @(posedge vif.clk);

        // 2. 8 Data Bits (LSB first)
        for (int i = 0; i < 8; i++) begin
            vif.uart_rx <= item.data[i];
            repeat (bit_clks) @(posedge vif.clk);
        end

        // 3. Optional Parity Bit (0=even, 1=odd)
        if (item.parity_en) begin
            parity = ^item.data;
            if (item.parity_type) parity = ~parity;
            if (item.corrupt_parity) parity = ~parity;
            vif.uart_rx <= parity;
            repeat (bit_clks) @(posedge vif.clk);
        end

        // 4. Stop Bit(s)
        vif.uart_rx <= item.corrupt_stop ? 1'b0 : 1'b1;
        repeat (bit_clks) @(posedge vif.clk);

        if (item.stop_bits == 2'd2) begin
            vif.uart_rx <= item.corrupt_stop2 ? 1'b0 : 1'b1;
            repeat (bit_clks) @(posedge vif.clk);
        end

        if (item.break_clks > 0) begin
            vif.uart_rx <= 1'b0;
            repeat (item.break_clks) @(posedge vif.clk);
        end

        vif.uart_rx <= 1'b1;
        repeat (8) @(posedge vif.clk);
    endtask
endclass : uart_vip_driver

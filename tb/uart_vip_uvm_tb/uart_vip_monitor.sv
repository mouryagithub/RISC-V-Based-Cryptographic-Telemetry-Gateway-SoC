// =============================================================================
// File        : uart_vip_monitor.sv
// Description : UVM Monitor for External UART VIP
//               Passively samples the SoC's external uart_tx pin, reconstructs
//               the transmitted byte stream, and observes uart_irq pin transitions.
// =============================================================================

class uart_vip_monitor extends uvm_monitor;

    virtual uart_vip_if vif;
    uvm_analysis_port #(uart_vip_item) ap;

    int clks_per_bit = 434; // 115200 baud @ 50MHz

    `uvm_component_utils(uart_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual uart_vip_if)::get(this, "", "vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(this, "", "uart_vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(null, "*", "uart_vif", vif) &&
            !uvm_config_db #(virtual uart_vip_if)::get(null, "*", "vif", vif)) begin
            `uvm_fatal("UART_MON", "Virtual interface ('vif' / 'uart_vif') not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait (vif.aresetn === 1'b1);
        @(posedge vif.clk);

        fork
            monitor_uart_tx();
            monitor_uart_irq();
        join
    endtask

    // Reconstructs serial UART bytes from SoC uart_tx pin
    task monitor_uart_tx();
        bit [7:0] rx_byte;

        forever begin
            // Wait for Start bit falling edge on uart_tx
            @(negedge vif.uart_tx);

            if (vif.aresetn === 1'b1) begin
                uart_vip_item item = uart_vip_item::type_id::create("mon_tx_item");

                // Sample in middle of Start Bit to verify start condition
                repeat (clks_per_bit / 2) @(posedge vif.clk);
                if (vif.uart_tx === 1'b0) begin

                    // Sample 8 Data Bits (LSB first at bit center)
                    for (int b = 0; b < 8; b++) begin
                        repeat (clks_per_bit) @(posedge vif.clk);
                        rx_byte[b] = vif.uart_tx;
                    end

                    // Sample Stop Bit
                    repeat (clks_per_bit) @(posedge vif.clk);

                    item.data         = rx_byte;
                    item.direction    = uart_vip_item::DIR_TX_FROM_SOC;
                    item.clks_per_bit = clks_per_bit;
                    item.timestamp    = $time;

                    `uvm_info("UART_MON",
                        $sformatf("Captured UART TX Byte from SoC: 0x%02X ('%c')",
                                  rx_byte, (rx_byte >= 32 && rx_byte <= 126) ? rx_byte : "."), UVM_MEDIUM)

                    ap.write(item);
                end
            end
        end
    endtask

    // Observes UART interrupt output pin from SoC
    task monitor_uart_irq();
        logic prev_irq = 1'b0;
        forever begin
            @(posedge vif.clk);
            if (vif.uart_irq !== prev_irq) begin
                `uvm_info("UART_MON",
                    $sformatf("SoC UART IRQ pin changed: %b -> %b", prev_irq, vif.uart_irq), UVM_HIGH)
                prev_irq = vif.uart_irq;
            end
        end
    endtask

endclass : uart_vip_monitor

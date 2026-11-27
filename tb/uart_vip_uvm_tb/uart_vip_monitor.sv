// =============================================================================
// File        : uart_vip_monitor.sv
// Description : UVM Monitor for External UART VIP (Serial TX + AXI + IRQ)
// =============================================================================

class uart_vip_monitor extends uvm_monitor;
    virtual uart_vip_if vif;
    uvm_analysis_port #(uart_vip_item) ap;

    int       clks_per_bit   = 434; // TX bit period = clks_per_bit + 1 in RTL
    bit       cfg_dlab       = 1'b0;
    bit       cfg_parity_en  = 1'b0;
    bit       cfg_parity_eps = 1'b0; // 1=even, 0=odd (LCR[4])
    bit       cfg_stop_2bit  = 1'b0; // LCR[2]

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
            monitor_uart_axi();
        join
    endtask

    task monitor_uart_tx();
        bit [7:0] rx_byte;
        bit       par_bit, exp_par, stop1, stop2;

        forever begin
            int bit_period;
            @(negedge vif.uart_tx);

            if (vif.aresetn === 1'b1) begin
                uart_vip_item item = uart_vip_item::type_id::create("mon_tx_item");
                bit_period = clks_per_bit + 1;

                // Sample in middle of Start Bit
                repeat (bit_period / 2) @(posedge vif.clk);
                if (vif.uart_tx === 1'b0) begin
                    for (int b = 0; b < 8; b++) begin
                        repeat (bit_period) @(posedge vif.clk);
                        rx_byte[b] = vif.uart_tx;
                    end

                    item.parity_en   = cfg_parity_en;
                    item.parity_type = ~cfg_parity_eps; // 0=even, 1=odd on item
                    item.parity_ok   = 1'b1;
                    if (cfg_parity_en) begin
                        repeat (bit_period) @(posedge vif.clk);
                        par_bit = vif.uart_tx;
                        exp_par = cfg_parity_eps ? (^rx_byte) : ~(^rx_byte);
                        item.parity_ok = (par_bit === exp_par);
                    end

                    repeat (bit_period) @(posedge vif.clk);
                    stop1 = vif.uart_tx;
                    stop2 = 1'b1;
                    item.stop_bits = cfg_stop_2bit ? 2'd2 : 2'd1;
                    if (cfg_stop_2bit) begin
                        repeat (bit_period) @(posedge vif.clk);
                        stop2 = vif.uart_tx;
                    end
                    item.stop_ok = (stop1 === 1'b1) && (stop2 === 1'b1);

                    item.kind         = uart_vip_item::KIND_SERIAL_TX;
                    item.data         = rx_byte;
                    item.direction    = uart_vip_item::DIR_TX_FROM_SOC;
                    item.clks_per_bit = clks_per_bit;
                    item.uart_irq     = vif.uart_irq;
                    item.timestamp    = $time;

                    ap.write(item);
                end
            end
        end
    endtask

    task monitor_uart_irq();
        logic prev_irq = 1'b0;
        forever begin
            @(posedge vif.clk);
            if (vif.uart_irq !== prev_irq) begin
                uart_vip_item item = uart_vip_item::type_id::create("mon_irq_item");
                item.kind      = uart_vip_item::KIND_IRQ_EVT;
                item.uart_irq  = vif.uart_irq;
                item.timestamp = $time;
                ap.write(item);
                prev_irq = vif.uart_irq;
            end
        end
    endtask

    task monitor_uart_axi();
        bit [7:0]  aw_addr_q = 8'h0, rd_addr_q = 8'h0;
        bit [31:0] w_data_q  = 32'h0;
        bit        aw_got = 1'b0, w_got = 1'b0, rd_pend = 1'b0;

        forever begin
            @(posedge vif.clk);
            if (vif.axi_awvalid && vif.axi_awready) begin
                aw_addr_q = vif.axi_awaddr;
                aw_got    = 1'b1;
            end
            if (vif.axi_wvalid && vif.axi_wready) begin
                w_data_q = vif.axi_wdata;
                w_got    = 1'b1;
            end
            if (vif.axi_bvalid && vif.axi_bready && aw_got && w_got) begin
                uart_vip_item item = uart_vip_item::type_id::create("mon_wr_item");
                item.kind         = uart_vip_item::KIND_REG_WR;
                item.offset       = aw_addr_q;
                item.wdata        = w_data_q;
                item.resp         = vif.axi_bresp;
                item.uart_irq     = vif.uart_irq;
                item.clks_per_bit = clks_per_bit;
                item.timestamp    = $time;

                if (aw_addr_q == 8'h0C) begin
                    cfg_stop_2bit  = w_data_q[2];
                    cfg_parity_en  = w_data_q[3];
                    cfg_parity_eps = w_data_q[4];
                    cfg_dlab       = w_data_q[7];
                end else if (aw_addr_q == 8'h08 && cfg_dlab) begin
                    clks_per_bit   = (w_data_q[15:0] > 0) ? int'(w_data_q[15:0]) : 434;
                end

                ap.write(item);
                aw_got = 1'b0;
                w_got  = 1'b0;
            end

            if (vif.axi_arvalid && vif.axi_arready) begin
                rd_addr_q = vif.axi_araddr;
                rd_pend   = 1'b1;
            end
            if (rd_pend && vif.axi_rvalid && vif.axi_rready) begin
                uart_vip_item item = uart_vip_item::type_id::create("mon_rd_item");
                item.kind         = uart_vip_item::KIND_REG_RD;
                item.offset       = rd_addr_q;
                item.rdata        = vif.axi_rdata;
                item.resp         = vif.axi_rresp;
                item.uart_irq     = vif.uart_irq;
                item.clks_per_bit = clks_per_bit;
                item.timestamp    = $time;
                ap.write(item);
                rd_pend = 1'b0;
            end
        end
    endtask
endclass : uart_vip_monitor

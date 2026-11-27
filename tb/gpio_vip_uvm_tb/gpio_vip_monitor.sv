// =============================================================================
// File        : gpio_vip_monitor.sv
// Description : UVM Monitor for External 64-Pin GPIO VIP + AXI Snoop
// =============================================================================

class gpio_vip_monitor extends uvm_monitor;
    virtual gpio_vip_if vif;
    uvm_analysis_port #(gpio_vip_item) ap;

    `uvm_component_utils(gpio_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual gpio_vip_if)::get(this, "", "vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(this, "", "gpio_vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(null, "*", "gpio_vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(null, "*", "vif", vif)) begin
            `uvm_fatal("GPIO_MON", "Virtual interface ('vif' / 'gpio_vif') not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        logic [63:0] prev_gpio_o    = '0;
        logic [63:0] prev_gpio_dir  = '0;
        logic [1:0]  prev_gpio_intr = '0;
        logic [63:0] prev_gpio_i    = '0;
        bit [11:0]   wr_addr_q = 12'h0, rd_addr_q = 12'h0;
        bit [31:0]   wr_data_q = 32'h0;
        bit          wr_pend   = 1'b0, rd_pend = 1'b0;
        bit          b_stalled = 1'b0, r_stalled = 1'b0;

        wait (vif.aresetn === 1'b1);
        @(posedge vif.clk);

        prev_gpio_o    = vif.gpio_o;
        prev_gpio_dir  = vif.gpio_dir_o;
        prev_gpio_intr = vif.gpio_intr_o;
        prev_gpio_i    = vif.gpio_i;

        forever begin
            @(posedge vif.clk);

            if (vif.gpio_o !== prev_gpio_o ||
                vif.gpio_dir_o !== prev_gpio_dir ||
                vif.gpio_intr_o !== prev_gpio_intr ||
                vif.gpio_i !== prev_gpio_i) begin
                gpio_vip_item item = gpio_vip_item::type_id::create("mon_pin_item");
                item.kind       = gpio_vip_item::KIND_PIN_OBS;
                item.gpio_out   = vif.gpio_o;
                item.gpio_dir   = vif.gpio_dir_o;
                item.gpio_intr  = vif.gpio_intr_o;
                item.gpio_in    = vif.gpio_i;
                item.timestamp  = $time;
                ap.write(item);
                prev_gpio_o    = vif.gpio_o;
                prev_gpio_dir  = vif.gpio_dir_o;
                prev_gpio_intr = vif.gpio_intr_o;
                prev_gpio_i    = vif.gpio_i;
            end

            // Passive AXI Write Monitor
            if (vif.s_axi_awvalid && vif.s_axi_awready && vif.s_axi_wvalid && vif.s_axi_wready) begin
                wr_addr_q = vif.s_axi_awaddr;
                wr_data_q = vif.s_axi_wdata;
                wr_pend   = 1'b1;
                b_stalled = 1'b0;
            end
            if (wr_pend && vif.s_axi_bvalid && !vif.s_axi_bready) b_stalled = 1'b1;
            if (wr_pend && vif.s_axi_bvalid && vif.s_axi_bready) begin
                gpio_vip_item item = gpio_vip_item::type_id::create("mon_wr_item");
                item.kind        = gpio_vip_item::KIND_REG_WR;
                item.offset      = wr_addr_q;
                item.wdata       = wr_data_q;
                item.resp        = vif.s_axi_bresp;
                item.gpio_out    = vif.gpio_o;
                item.gpio_dir    = vif.gpio_dir_o;
                item.gpio_intr   = vif.gpio_intr_o;
                item.bready_wait = b_stalled;
                item.timestamp   = $time;
                ap.write(item);
                wr_pend   = 1'b0;
                b_stalled = 1'b0;
            end

            // Passive AXI Read Monitor
            if (vif.s_axi_arvalid && vif.s_axi_arready) begin
                rd_addr_q = vif.s_axi_araddr;
                rd_pend   = 1'b1;
                r_stalled = 1'b0;
            end
            if (rd_pend && vif.s_axi_rvalid && !vif.s_axi_rready) r_stalled = 1'b1;
            if (rd_pend && vif.s_axi_rvalid && vif.s_axi_rready) begin
                gpio_vip_item item = gpio_vip_item::type_id::create("mon_rd_item");
                item.kind        = gpio_vip_item::KIND_REG_RD;
                item.offset      = rd_addr_q;
                item.rdata       = vif.s_axi_rdata;
                item.resp        = vif.s_axi_rresp;
                item.gpio_out    = vif.gpio_o;
                item.gpio_dir    = vif.gpio_dir_o;
                item.gpio_intr   = vif.gpio_intr_o;
                item.rready_wait = r_stalled;
                item.timestamp   = $time;
                ap.write(item);
                rd_pend   = 1'b0;
                r_stalled = 1'b0;
            end
        end
    endtask
endclass : gpio_vip_monitor

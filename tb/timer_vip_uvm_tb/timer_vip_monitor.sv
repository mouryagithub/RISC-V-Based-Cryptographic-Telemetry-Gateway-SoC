// =============================================================================
// File        : timer_vip_monitor.sv
// Description : UVM Monitor for System Timer (axi_timer_top RTL boundary)
// =============================================================================

class timer_vip_monitor extends uvm_monitor;
    virtual timer_vip_if vif;
    uvm_analysis_port #(timer_vip_item) ap;

    `uvm_component_utils(timer_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual timer_vip_if)::get(this, "", "timer_vif", vif) &&
            !uvm_config_db #(virtual timer_vip_if)::get(null, "*", "timer_vif", vif)) begin
            `uvm_fatal("TIMER_MON", "Virtual interface 'timer_vif' not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [11:0] wr_addr_q, rd_addr_q;
        bit [31:0] wr_data_q;
        bit [3:0]  wr_strb_q;
        bit        wr_pending = 1'b0;
        bit        rd_pending = 1'b0;
        bit        b_stalled  = 1'b0;
        bit        r_stalled  = 1'b0;
        logic      prev_irq   = 1'b0;

        wait (vif.aresetn === 1'b1);
        @(posedge vif.aclk);

        forever begin
            @(posedge vif.aclk);

            // Capture Write Request
            if (vif.s_axi_awvalid && vif.s_axi_awready && vif.s_axi_wvalid && vif.s_axi_wready) begin
                wr_addr_q  = vif.s_axi_awaddr;
                wr_data_q  = vif.s_axi_wdata;
                wr_strb_q  = vif.s_axi_wstrb;
                wr_pending = 1'b1;
                b_stalled  = 1'b0;
            end

            if (wr_pending && vif.s_axi_bvalid && !vif.s_axi_bready) begin
                b_stalled = 1'b1;
            end

            if (wr_pending && vif.s_axi_bvalid && vif.s_axi_bready) begin
                timer_vip_item item = timer_vip_item::type_id::create("mon_wr_item");
                item.op          = timer_vip_item::OP_WRITE;
                item.offset      = wr_addr_q;
                item.wdata       = wr_data_q;
                item.wstrb       = wr_strb_q;
                item.resp        = vif.s_axi_bresp;
                item.timer_irq   = vif.timer_irq;
                item.bready_wait = b_stalled;
                item.timestamp   = $time;
                ap.write(item);
                wr_pending = 1'b0;
                b_stalled  = 1'b0;
            end

            // Capture Read Request & Response
            if (vif.s_axi_arvalid && vif.s_axi_arready) begin
                rd_addr_q  = vif.s_axi_araddr;
                rd_pending = 1'b1;
                r_stalled  = 1'b0;
            end

            if (rd_pending && vif.s_axi_rvalid && !vif.s_axi_rready) begin
                r_stalled = 1'b1;
            end

            if (rd_pending && vif.s_axi_rvalid && vif.s_axi_rready) begin
                timer_vip_item item = timer_vip_item::type_id::create("mon_rd_item");
                item.op          = timer_vip_item::OP_READ;
                item.offset      = rd_addr_q;
                item.rdata       = vif.s_axi_rdata;
                item.resp        = vif.s_axi_rresp;
                item.timer_irq   = vif.timer_irq;
                item.rready_wait = r_stalled;
                item.timestamp   = $time;
                ap.write(item);
                rd_pending = 1'b0;
                r_stalled  = 1'b0;
            end

            // Capture IRQ edge
            if (vif.timer_irq !== prev_irq) begin
                timer_vip_item item = timer_vip_item::type_id::create("mon_irq_item");
                item.op        = timer_vip_item::OP_IRQ;
                item.timer_irq = vif.timer_irq;
                item.timestamp = $time;
                ap.write(item);
                prev_irq = vif.timer_irq;
            end
        end
    endtask
endclass : timer_vip_monitor

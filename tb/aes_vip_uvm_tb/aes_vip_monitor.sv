// =============================================================================
// File        : aes_vip_monitor.sv
// Description : UVM Monitor for AES-256 VIP (aes_core_top RTL boundary)
// =============================================================================

class aes_vip_monitor extends uvm_monitor;
    virtual aes_vip_if vif;
    uvm_analysis_port #(aes_vip_item) ap;

    `uvm_component_utils(aes_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual aes_vip_if)::get(this, "", "aes_vif", vif) &&
            !uvm_config_db #(virtual aes_vip_if)::get(null, "*", "aes_vif", vif)) begin
            `uvm_fatal("AES_MON", "Virtual interface 'aes_vif' not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [7:0]  aw_addr_q = 8'h0;
        bit [31:0] w_data_q  = 32'h0;
        bit [3:0]  w_strb_q  = 4'h0;
        bit        aw_got    = 1'b0;
        bit        w_got     = 1'b0;
        bit [7:0]  rd_addr_q = 8'h0;
        bit        rd_pend   = 1'b0;
        bit        b_stalled = 1'b0;
        bit        r_stalled = 1'b0;
        logic      prev_irq  = 1'b0;

        wait (vif.aresetn === 1'b1);
        @(posedge vif.aclk);

        forever begin
            @(posedge vif.aclk);

            // aes_regfile accepts AW and W independently
            if (vif.s_axi_awvalid && vif.s_axi_awready) begin
                aw_addr_q = vif.s_axi_awaddr;
                aw_got    = 1'b1;
            end
            if (vif.s_axi_wvalid && vif.s_axi_wready) begin
                w_data_q = vif.s_axi_wdata;
                w_strb_q = vif.s_axi_wstrb;
                w_got    = 1'b1;
            end
            if (vif.s_axi_bvalid && !vif.s_axi_bready) begin
                b_stalled = 1'b1;
            end
            if (vif.s_axi_bvalid && vif.s_axi_bready && aw_got && w_got) begin
                aes_vip_item item = aes_vip_item::type_id::create("mon_wr_item");
                item.op          = aes_vip_item::OP_WRITE;
                item.offset      = aw_addr_q;
                item.wdata       = w_data_q;
                item.wstrb       = w_strb_q;
                item.resp        = vif.s_axi_bresp;
                item.irq         = vif.irq;
                item.bready_wait = b_stalled;
                item.timestamp   = $time;
                ap.write(item);
                aw_got    = 1'b0;
                w_got     = 1'b0;
                b_stalled = 1'b0;
            end

            if (vif.s_axi_arvalid && vif.s_axi_arready) begin
                rd_addr_q = vif.s_axi_araddr;
                rd_pend   = 1'b1;
                r_stalled = 1'b0;
            end
            if (rd_pend && vif.s_axi_rvalid && !vif.s_axi_rready) begin
                r_stalled = 1'b1;
            end
            if (rd_pend && vif.s_axi_rvalid && vif.s_axi_rready) begin
                aes_vip_item item = aes_vip_item::type_id::create("mon_rd_item");
                item.op          = aes_vip_item::OP_READ;
                item.offset      = rd_addr_q;
                item.rdata       = vif.s_axi_rdata;
                item.resp        = vif.s_axi_rresp;
                item.irq         = vif.irq;
                item.rready_wait = r_stalled;
                item.timestamp   = $time;
                ap.write(item);
                rd_pend   = 1'b0;
                r_stalled = 1'b0;
            end

            if (vif.irq !== prev_irq) begin
                aes_vip_item item = aes_vip_item::type_id::create("mon_irq_item");
                item.op        = aes_vip_item::OP_IRQ;
                item.irq       = vif.irq;
                item.timestamp = $time;
                ap.write(item);
                prev_irq = vif.irq;
            end
        end
    endtask
endclass : aes_vip_monitor

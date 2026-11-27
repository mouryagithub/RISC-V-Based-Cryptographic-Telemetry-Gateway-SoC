// =============================================================================
// File        : sha_vip_monitor.sv
// Description : UVM Monitor for SHA-256 VIP (axi_sha256_top RTL boundary)
// =============================================================================

class sha_vip_monitor extends uvm_monitor;
    virtual sha_vip_if vif;
    uvm_analysis_port #(sha_vip_item) ap;

    `uvm_component_utils(sha_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual sha_vip_if)::get(this, "", "sha_vif", vif) &&
            !uvm_config_db #(virtual sha_vip_if)::get(null, "*", "sha_vif", vif)) begin
            `uvm_fatal("SHA_MON", "Virtual interface 'sha_vif' not found in config_db")
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

            if (vif.s_axi_awvalid && vif.s_axi_awready && vif.s_axi_wvalid && vif.s_axi_wready) begin
                wr_addr_q  = vif.s_axi_awaddr;
                wr_data_q  = vif.s_axi_wdata;
                wr_strb_q  = vif.s_axi_wstrb;
                wr_pending = 1'b1;
                b_stalled  = 1'b0;
            end
            if (wr_pending && vif.s_axi_bvalid && !vif.s_axi_bready) b_stalled = 1'b1;
            if (wr_pending && vif.s_axi_bvalid && vif.s_axi_bready) begin
                sha_vip_item item = sha_vip_item::type_id::create("mon_wr_item");
                item.op          = sha_vip_item::OP_WRITE;
                item.offset      = wr_addr_q;
                item.wdata       = wr_data_q;
                item.wstrb       = wr_strb_q;
                item.resp        = vif.s_axi_bresp;
                item.sha_irq     = vif.sha_irq;
                item.bready_wait = b_stalled;
                item.timestamp   = $time;
                ap.write(item);
                wr_pending = 1'b0;
                b_stalled  = 1'b0;
            end

            if (vif.s_axi_arvalid && vif.s_axi_arready) begin
                rd_addr_q  = vif.s_axi_araddr;
                rd_pending = 1'b1;
                r_stalled  = 1'b0;
            end
            if (rd_pending && vif.s_axi_rvalid && !vif.s_axi_rready) r_stalled = 1'b1;
            if (rd_pending && vif.s_axi_rvalid && vif.s_axi_rready) begin
                sha_vip_item item = sha_vip_item::type_id::create("mon_rd_item");
                item.op          = sha_vip_item::OP_READ;
                item.offset      = rd_addr_q;
                item.rdata       = vif.s_axi_rdata;
                item.resp        = vif.s_axi_rresp;
                item.sha_irq     = vif.sha_irq;
                item.rready_wait = r_stalled;
                item.timestamp   = $time;
                ap.write(item);
                rd_pending = 1'b0;
                r_stalled  = 1'b0;
            end

            if (vif.sha_irq !== prev_irq) begin
                sha_vip_item item = sha_vip_item::type_id::create("mon_irq_item");
                item.op        = sha_vip_item::OP_IRQ;
                item.sha_irq   = vif.sha_irq;
                item.timestamp = $time;
                ap.write(item);
                prev_irq = vif.sha_irq;
            end
        end
    endtask
endclass : sha_vip_monitor

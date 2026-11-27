// =============================================================================
// File        : dma_vip_monitor.sv
// Description : UVM Monitor for AXI DMA VIP (CSR Slave + AXI4 Master + IRQs)
// =============================================================================

class dma_vip_monitor extends uvm_monitor;
    virtual dma_vip_if vif;
    uvm_analysis_port #(dma_vip_item) ap;

    `uvm_component_utils(dma_vip_monitor)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual dma_vip_if)::get(this, "", "dma_vif", vif) &&
            !uvm_config_db #(virtual dma_vip_if)::get(null, "*", "dma_vif", vif)) begin
            `uvm_fatal("DMA_MON", "Virtual interface 'dma_vif' not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        bit [31:0] csr_aw_q = 32'h0, csr_w_q = 32'h0, csr_ar_q = 32'h0;
        bit        csr_aw_got = 1'b0, csr_w_got = 1'b0, csr_rd_pend = 1'b0;
        logic      prev_done = 1'b0, prev_err = 1'b0;

        wait (vif.aresetn === 1'b1);
        @(posedge vif.clk);

        forever begin
            @(posedge vif.clk);

            // 1. CSR AXI4-Lite Slave Write Monitor
            if (vif.dma_s_awvalid && vif.dma_s_awready) begin
                csr_aw_q   = vif.dma_s_awaddr;
                csr_aw_got = 1'b1;
            end
            if (vif.dma_s_wvalid && vif.dma_s_wready) begin
                csr_w_q   = vif.dma_s_wdata;
                csr_w_got = 1'b1;
            end
            if (vif.dma_s_bvalid && vif.dma_s_bready && csr_aw_got && csr_w_got) begin
                dma_vip_item item = dma_vip_item::type_id::create("mon_csr_wr");
                item.op        = dma_vip_item::OP_CSR_WR;
                item.addr      = csr_aw_q;
                item.wdata     = csr_w_q;
                item.resp      = vif.dma_s_bresp;
                item.dma_done  = vif.dma_done_o;
                item.dma_error = vif.dma_error_o;
                item.timestamp = $time;
                ap.write(item);
                csr_aw_got = 1'b0;
                csr_w_got  = 1'b0;
            end

            // 2. CSR AXI4-Lite Slave Read Monitor
            if (vif.dma_s_arvalid && vif.dma_s_arready) begin
                csr_ar_q    = vif.dma_s_araddr;
                csr_rd_pend = 1'b1;
            end
            if (csr_rd_pend && vif.dma_s_rvalid && vif.dma_s_rready) begin
                dma_vip_item item = dma_vip_item::type_id::create("mon_csr_rd");
                item.op        = dma_vip_item::OP_CSR_RD;
                item.addr      = csr_ar_q;
                item.rdata     = vif.dma_s_rdata;
                item.resp      = vif.dma_s_rresp;
                item.dma_done  = vif.dma_done_o;
                item.dma_error = vif.dma_error_o;
                item.timestamp = $time;
                ap.write(item);
                csr_rd_pend = 1'b0;
            end

            // 3. AXI4 Master Write Request Monitor (s01 AW)
            if (vif.dma_m_awvalid && vif.dma_m_awready) begin
                dma_vip_item item = dma_vip_item::type_id::create("mon_m_aw");
                item.op        = dma_vip_item::OP_MEM_WR;
                item.addr      = vif.dma_m_awaddr;
                item.axlen     = vif.dma_m_awlen;
                item.axburst   = vif.dma_m_awburst;
                item.dma_done  = vif.dma_done_o;
                item.dma_error = vif.dma_error_o;
                item.timestamp = $time;
                ap.write(item);
            end

            // 4. AXI4 Master Read Request Monitor (s01 AR)
            if (vif.dma_m_arvalid && vif.dma_m_arready) begin
                dma_vip_item item = dma_vip_item::type_id::create("mon_m_ar");
                item.op        = dma_vip_item::OP_MEM_RD;
                item.addr      = vif.dma_m_araddr;
                item.axlen     = vif.dma_m_arlen;
                item.axburst   = vif.dma_m_arburst;
                item.dma_done  = vif.dma_done_o;
                item.dma_error = vif.dma_error_o;
                item.timestamp = $time;
                ap.write(item);
            end

            // 5. Done/Error Pin Change Monitor
            if (vif.dma_done_o !== prev_done || vif.dma_error_o !== prev_err) begin
                dma_vip_item item = dma_vip_item::type_id::create("mon_evt");
                item.op        = dma_vip_item::OP_EVT;
                item.dma_done  = vif.dma_done_o;
                item.dma_error = vif.dma_error_o;
                item.timestamp = $time;
                ap.write(item);
                prev_done = vif.dma_done_o;
                prev_err  = vif.dma_error_o;
            end
        end
    endtask
endclass : dma_vip_monitor

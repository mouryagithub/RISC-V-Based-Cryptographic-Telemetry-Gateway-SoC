// =============================================================================
// File        : dma_vip_driver.sv
// Description : UVM Driver for AXI DMA VIP (CSR & SRAM/Peripheral setup)
// =============================================================================

class dma_vip_driver extends uvm_driver #(dma_vip_item);
    virtual soc_axi_if bus_vif;

    `uvm_component_utils(dma_vip_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual soc_axi_if)::get(this, "", "bus_vif", bus_vif) &&
            !uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("DMA_DRV", "Virtual interface 'bus_vif' not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait (bus_vif.aresetn === 1'b1);
        @(posedge bus_vif.clk);

        forever begin
            dma_vip_item req_item;
            int unsigned rsp_word, rd_word;

            seq_item_port.get_next_item(req_item);
            case (req_item.op)
                dma_vip_item::OP_CSR_WR, dma_vip_item::OP_BUS_WR: begin
                    bus_vif.axi_write_ext(
                        req_item.addr,
                        req_item.wdata,
                        {28'h0, req_item.wstrb},
                        req_item.split_mode,
                        req_item.ready_delay,
                        rsp_word
                    );
                    req_item.resp      = rsp_word[1:0];
                    req_item.dma_done  = bus_vif.dma_done;
                    req_item.dma_error = bus_vif.dma_error;
                end
                dma_vip_item::OP_CSR_RD, dma_vip_item::OP_BUS_RD: begin
                    bus_vif.axi_read_ext(
                        req_item.addr,
                        req_item.ready_delay,
                        rd_word,
                        rsp_word
                    );
                    req_item.rdata     = rd_word;
                    req_item.resp      = rsp_word[1:0];
                    req_item.dma_done  = bus_vif.dma_done;
                    req_item.dma_error = bus_vif.dma_error;
                end
                dma_vip_item::OP_WAIT: begin
                    bus_vif.wait_cycles(req_item.wait_clks);
                    req_item.dma_done  = bus_vif.dma_done;
                    req_item.dma_error = bus_vif.dma_error;
                end
                default: ;
            endcase
            seq_item_port.item_done();
        end
    endtask
endclass : dma_vip_driver

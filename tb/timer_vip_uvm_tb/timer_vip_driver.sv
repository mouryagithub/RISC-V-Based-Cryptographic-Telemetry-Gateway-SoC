// =============================================================================
// File        : timer_vip_driver.sv
// Description : UVM Driver for System Timer VIP (drives via SoC AXI bus BFM)
// =============================================================================

class timer_vip_driver extends uvm_driver #(timer_vip_item);
    virtual soc_axi_if bus_vif;

    localparam bit [31:0] TIMER_BASE = 32'h4000_2000;

    `uvm_component_utils(timer_vip_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual soc_axi_if)::get(this, "", "bus_vif", bus_vif) &&
            !uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("TIMER_DRV", "Virtual interface 'bus_vif' not found in config_db")
        end
    endfunction

    task run_phase(uvm_phase phase);
        wait (bus_vif.aresetn === 1'b1);
        @(posedge bus_vif.clk);

        forever begin
            timer_vip_item req_item;
            int unsigned rsp_word;
            int unsigned rd_word;

            seq_item_port.get_next_item(req_item);
            case (req_item.op)
                timer_vip_item::OP_WRITE: begin
                    bus_vif.axi_write_ext(
                        TIMER_BASE + {20'h0, req_item.offset},
                        req_item.wdata,
                        {28'h0, req_item.wstrb},
                        req_item.split_mode,
                        req_item.ready_delay,
                        rsp_word
                    );
                    req_item.resp      = rsp_word[1:0];
                    req_item.timer_irq = bus_vif.timer_irq;
                end
                timer_vip_item::OP_READ: begin
                    bus_vif.axi_read_ext(
                        TIMER_BASE + {20'h0, req_item.offset},
                        req_item.ready_delay,
                        rd_word,
                        rsp_word
                    );
                    req_item.rdata     = rd_word;
                    req_item.resp      = rsp_word[1:0];
                    req_item.timer_irq = bus_vif.timer_irq;
                end
                timer_vip_item::OP_WAIT: begin
                    bus_vif.wait_cycles(req_item.wait_clks);
                    req_item.timer_irq = bus_vif.timer_irq;
                end
                default: ;
            endcase
            seq_item_port.item_done();
        end
    endtask
endclass : timer_vip_driver

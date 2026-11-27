// =============================================================================
// File        : gpio_vip_driver.sv
// Description : UVM Driver for 64-Pin GPIO VIP (External Pins + AXI Regs)
// =============================================================================

class gpio_vip_driver extends uvm_driver #(gpio_vip_item);
    virtual gpio_vip_if vif;
    virtual soc_axi_if  bus_vif;

    localparam bit [31:0] GPIO_BASE = 32'h4000_3000;

    `uvm_component_utils(gpio_vip_driver)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual gpio_vip_if)::get(this, "", "vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(this, "", "gpio_vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(null, "*", "gpio_vif", vif) &&
            !uvm_config_db #(virtual gpio_vip_if)::get(null, "*", "vif", vif)) begin
            `uvm_fatal("GPIO_DRV", "Virtual interface ('vif' / 'gpio_vif') not found in config_db")
        end
        void'(uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif));
    endfunction

    task run_phase(uvm_phase phase);
        vif.gpio_i <= 64'd0;
        wait (vif.aresetn === 1'b1);
        repeat (5) @(posedge vif.clk);

        forever begin
            gpio_vip_item req_item;
            int unsigned rsp_word, rd_word;

            seq_item_port.get_next_item(req_item);
            if (req_item.kind == gpio_vip_item::KIND_PIN_DRV) begin
                `uvm_info("GPIO_DRV",
                    $sformatf("Driving External SoC GPIO Input Pins: 0x%016X (hold %0d clks)",
                              req_item.gpio_in, req_item.hold_cycles), UVM_HIGH)
                vif.gpio_i <= req_item.gpio_in;
                repeat ((req_item.hold_cycles > 0) ? req_item.hold_cycles : 5) @(posedge vif.clk);
            end else if (req_item.kind == gpio_vip_item::KIND_REG_WR) begin
                if (bus_vif == null) `uvm_fatal("GPIO_DRV", "bus_vif is null for KIND_REG_WR")
                bus_vif.axi_write_ext(GPIO_BASE + {20'h0, req_item.offset}, req_item.wdata, 32'hF, 0, req_item.ready_delay, rsp_word);
                req_item.resp      = rsp_word[1:0];
                req_item.gpio_out  = vif.gpio_o;
                req_item.gpio_dir  = vif.gpio_dir_o;
                req_item.gpio_intr = vif.gpio_intr_o;
            end else if (req_item.kind == gpio_vip_item::KIND_REG_RD) begin
                if (bus_vif == null) `uvm_fatal("GPIO_DRV", "bus_vif is null for KIND_REG_RD")
                bus_vif.axi_read_ext(GPIO_BASE + {20'h0, req_item.offset}, req_item.ready_delay, rd_word, rsp_word);
                req_item.rdata     = rd_word;
                req_item.resp      = rsp_word[1:0];
                req_item.gpio_out  = vif.gpio_o;
                req_item.gpio_dir  = vif.gpio_dir_o;
                req_item.gpio_intr = vif.gpio_intr_o;
            end
            seq_item_port.item_done();
        end
    endtask
endclass : gpio_vip_driver

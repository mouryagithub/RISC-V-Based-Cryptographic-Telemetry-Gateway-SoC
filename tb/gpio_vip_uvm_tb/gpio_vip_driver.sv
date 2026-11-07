// =============================================================================
// File        : gpio_vip_driver.sv
// Description : UVM Driver for External 64-Pin GPIO VIP
//               Drives external input values directly onto the SoC's gpio_i[63:0]
//               pins with specified hold duration.
// =============================================================================

class gpio_vip_driver extends uvm_driver #(gpio_vip_item);

    virtual gpio_vip_if vif;

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
    endfunction

    task run_phase(uvm_phase phase);
        vif.gpio_i <= 64'd0;

        wait (vif.aresetn === 1'b1);
        repeat(5) @(posedge vif.clk);

        forever begin
            gpio_vip_item req_item;
            seq_item_port.get_next_item(req_item);

            `uvm_info("GPIO_DRV",
                $sformatf("Driving External SoC GPIO Input Pins: 0x%016X (hold %0d clks)",
                          req_item.gpio_in, req_item.hold_cycles), UVM_MEDIUM)

            vif.gpio_i <= req_item.gpio_in;
            repeat ((req_item.hold_cycles > 0) ? req_item.hold_cycles : 5) @(posedge vif.clk);

            seq_item_port.item_done();
        end
    endtask

endclass : gpio_vip_driver

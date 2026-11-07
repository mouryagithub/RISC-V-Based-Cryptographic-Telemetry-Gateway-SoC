// =============================================================================
// File        : gpio_vip_monitor.sv
// Description : UVM Monitor for External 64-Pin GPIO VIP
//               Passively samples the SoC's external gpio_o[63:0], gpio_dir_o[63:0],
//               and gpio_intr_o[1:0] pins, writing captured events to analysis port.
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
                item.gpio_out   = vif.gpio_o;
                item.gpio_dir   = vif.gpio_dir_o;
                item.gpio_intr  = vif.gpio_intr_o;
                item.gpio_in    = vif.gpio_i;
                item.timestamp  = $time;

                `uvm_info("GPIO_MON",
                    $sformatf("SoC GPIO Pin Change: out=0x%016X dir=0x%016X intr=%02b in=0x%016X",
                              item.gpio_out, item.gpio_dir, item.gpio_intr, item.gpio_in), UVM_MEDIUM)

                ap.write(item);

                prev_gpio_o    = vif.gpio_o;
                prev_gpio_dir  = vif.gpio_dir_o;
                prev_gpio_intr = vif.gpio_intr_o;
                prev_gpio_i    = vif.gpio_i;
            end
        end
    endtask

endclass : gpio_vip_monitor

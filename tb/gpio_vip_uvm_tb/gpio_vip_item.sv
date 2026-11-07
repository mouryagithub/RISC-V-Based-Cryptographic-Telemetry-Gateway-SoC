// =============================================================================
// File        : gpio_vip_item.sv
// Description : UVM Sequence Item for External 64-Pin GPIO VIP
//               Represents pin stimulus applied to gpio_i and pin observations
//               sampled from gpio_o, gpio_dir_o, and gpio_intr_o.
// =============================================================================

class gpio_vip_item extends uvm_sequence_item;

    // Pin Stimulus to Drive into SoC
    rand bit [63:0] gpio_in;
    rand int        hold_cycles;

    // Pin State Sampled from SoC
    bit [63:0]      gpio_out;
    bit [63:0]      gpio_dir;
    bit [1:0]       gpio_intr;
    time            timestamp;

    `uvm_object_utils_begin(gpio_vip_item)
        `uvm_field_int(gpio_in, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(hold_cycles, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(gpio_out, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_dir, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_intr, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "gpio_vip_item");
        super.new(name);
        gpio_in     = 64'd0;
        hold_cycles = 5;
        gpio_out    = 64'd0;
        gpio_dir    = 64'd0;
        gpio_intr   = 2'b00;
        timestamp   = 0;
    endfunction

    function string convert2string();
        string s;
        s = $sformatf("GPIO_ITEM: in=0x%016X out=0x%016X dir=0x%016X intr=%02b (hold=%0d clks)",
                      gpio_in, gpio_out, gpio_dir, gpio_intr, hold_cycles);
        return s;
    endfunction

endclass : gpio_vip_item

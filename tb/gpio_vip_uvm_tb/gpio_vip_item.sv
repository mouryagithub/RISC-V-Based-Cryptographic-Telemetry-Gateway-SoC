// =============================================================================
// File        : gpio_vip_item.sv
// Description : UVM Sequence Item for 64-Pin GPIO VIP
// =============================================================================

class gpio_vip_item extends uvm_sequence_item;
    typedef enum logic [1:0] {
        KIND_PIN_DRV = 2'd0,
        KIND_PIN_OBS = 2'd1,
        KIND_REG_WR  = 2'd2,
        KIND_REG_RD  = 2'd3
    } kind_e;

    kind_e          kind;
    rand bit [63:0] gpio_in;
    rand int        hold_cycles;

    // AXI Register Fields
    rand bit [11:0] offset;
    rand bit [31:0] wdata;
    bit [31:0]      rdata;
    bit [1:0]       resp;
    int             ready_delay;
    bit             bready_wait;
    bit             rready_wait;

    // Pin State Sampled from SoC
    bit [63:0]      gpio_out;
    bit [63:0]      gpio_dir;
    bit [1:0]       gpio_intr;
    time            timestamp;

    `uvm_object_utils_begin(gpio_vip_item)
        `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
        `uvm_field_int(gpio_in, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(hold_cycles, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(offset, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_out, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_dir, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(gpio_intr, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "gpio_vip_item");
        super.new(name);
        kind        = KIND_PIN_DRV;
        gpio_in     = 64'd0;
        hold_cycles = 5;
        offset      = 12'h000;
        wdata       = 32'h0;
        rdata       = 32'h0;
        resp        = 2'b00;
        ready_delay = 0;
        bready_wait = 1'b0;
        rready_wait = 1'b0;
        gpio_out    = 64'd0;
        gpio_dir    = 64'd0;
        gpio_intr   = 2'b00;
        timestamp   = 0;
    endfunction

    function string convert2string();
        return $sformatf("GPIO_ITEM [%s]: off=0x%03X wd=0x%08X rd=0x%08X in=0x%016X out=0x%016X dir=0x%016X intr=%02b",
                         kind.name(), offset, wdata, rdata, gpio_in, gpio_out, gpio_dir, gpio_intr);
    endfunction
endclass : gpio_vip_item

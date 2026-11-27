// =============================================================================
// File        : timer_vip_item.sv
// Description : UVM Sequence Item for System Timer VIP
// =============================================================================

class timer_vip_item extends uvm_sequence_item;
    typedef enum logic [1:0] {
        OP_WRITE = 2'd0,
        OP_READ  = 2'd1,
        OP_WAIT  = 2'd2,
        OP_IRQ   = 2'd3
    } op_e;

    rand op_e         op;
    rand bit [11:0]   offset;
    rand bit [31:0]   wdata;
    rand bit [3:0]    wstrb;
    bit [31:0]        rdata;
    bit [1:0]         resp;
    bit               timer_irq;
    bit               bready_wait;
    bit               rready_wait;
    int               split_mode;
    int               ready_delay;
    int               wait_clks;
    time              timestamp;

    `uvm_object_utils_begin(timer_vip_item)
        `uvm_field_enum(op_e, op, UVM_ALL_ON)
        `uvm_field_int(offset, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wstrb, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(resp, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(timer_irq, UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    function new(string name = "timer_vip_item");
        super.new(name);
        op          = OP_READ;
        offset      = 12'h000;
        wdata       = 32'h0;
        wstrb       = 4'hF;
        rdata       = 32'h0;
        resp        = 2'b00;
        timer_irq   = 1'b0;
        bready_wait = 1'b0;
        rready_wait = 1'b0;
        split_mode  = 0;
        ready_delay = 0;
        wait_clks   = 1;
        timestamp   = 0;
    endfunction
endclass : timer_vip_item

// =============================================================================
// File        : uart_vip_item.sv
// Description : UVM Sequence Item for UART VIP (Serial Frames + AXI Regs)
// =============================================================================

class uart_vip_item extends uvm_sequence_item;

    typedef enum bit {
        DIR_RX_INTO_SOC = 1'b0,
        DIR_TX_FROM_SOC = 1'b1
    } dir_e;

    typedef enum logic [2:0] {
        KIND_SERIAL_RX = 3'd0,
        KIND_SERIAL_TX = 3'd1,
        KIND_REG_WR    = 3'd2,
        KIND_REG_RD    = 3'd3,
        KIND_IRQ_EVT   = 3'd4,
        KIND_WAIT      = 3'd5
    } kind_e;

    kind_e          kind;
    rand bit [7:0]  data;
    rand int        clks_per_bit;
    rand bit        parity_en;
    rand bit        parity_type;    // 0: even, 1: odd (on wire)
    rand bit [1:0]  stop_bits;      // 1 or 2
    rand bit        corrupt_stop;
    rand bit        corrupt_stop2;
    rand bit        corrupt_parity;
    int             break_clks;
    bit             parity_ok;
    bit             stop_ok;

    // AXI Register Fields
    rand bit [7:0]  offset;
    rand bit [31:0] wdata;
    bit [31:0]      rdata;
    bit [1:0]       resp;
    int             ready_delay;
    int             split_mode;
    int             wait_clks;
    bit             uart_irq;

    dir_e           direction;
    time            timestamp;

    `uvm_object_utils_begin(uart_vip_item)
        `uvm_field_enum(kind_e, kind, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(clks_per_bit, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(parity_en, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(parity_type, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(stop_bits, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(corrupt_stop, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(corrupt_parity, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(offset, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_enum(dir_e, direction, UVM_ALL_ON)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "uart_vip_item");
        super.new(name);
        kind           = KIND_SERIAL_RX;
        data           = 8'h00;
        clks_per_bit   = 434;
        parity_en      = 1'b0;
        parity_type    = 1'b0;
        stop_bits      = 2'd1;
        corrupt_stop   = 1'b0;
        corrupt_parity = 1'b0;
        parity_ok      = 1'b1;
        stop_ok        = 1'b1;
        offset         = 8'h00;
        wdata          = 32'h0;
        rdata          = 32'h0;
        resp           = 2'b00;
        ready_delay    = 0;
        split_mode     = 0;
        wait_clks      = 1;
        uart_irq       = 1'b0;
        direction      = DIR_RX_INTO_SOC;
        timestamp      = 0;
    endfunction

    function string convert2string();
        return $sformatf("UART_ITEM [%s]: data=0x%02X off=0x%02X wd=0x%08X rd=0x%08X clks=%0d par=%0b/%0b stop=%0d",
                         kind.name(), data, offset, wdata, rdata, clks_per_bit, parity_en, parity_type, stop_bits);
    endfunction
endclass : uart_vip_item

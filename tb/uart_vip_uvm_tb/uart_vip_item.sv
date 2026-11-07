// =============================================================================
// File        : uart_vip_item.sv
// Description : UVM Sequence Item for External UART VIP
//               Represents a serialized UART frame on external pins (uart_rx/uart_tx).
// =============================================================================

class uart_vip_item extends uvm_sequence_item;

    typedef enum bit {
        DIR_RX_INTO_SOC = 1'b0,
        DIR_TX_FROM_SOC = 1'b1
    } dir_e;

    // Byte Payload
    rand bit [7:0]  data;

    // UART Timing & Protocol Configuration
    rand int        clks_per_bit;   // Clock cycles per bit (default: 434 for 115200 baud @ 50MHz)
    rand bit        parity_en;      // 0: none, 1: parity bit included
    rand bit        parity_type;    // 0: even, 1: odd
    rand bit [1:0]  stop_bits;      // 1 or 2 stop bits (default 1)

    // Error Injection
    rand bit        corrupt_stop;   // 1: corrupt stop bit (framing error)
    rand bit        corrupt_parity; // 1: corrupt parity bit (parity error)

    // Status & Metadata
    dir_e           direction;
    time            timestamp;

    `uvm_object_utils_begin(uart_vip_item)
        `uvm_field_int(data, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(clks_per_bit, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(parity_en, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(parity_type, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(stop_bits, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(corrupt_stop, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(corrupt_parity, UVM_ALL_ON | UVM_BIN)
        `uvm_field_enum(dir_e, direction, UVM_ALL_ON)
        `uvm_field_int(timestamp, UVM_ALL_ON | UVM_TIME)
    `uvm_object_utils_end

    function new(string name = "uart_vip_item");
        super.new(name);
        data           = 8'h00;
        clks_per_bit   = 434;
        parity_en      = 1'b0;
        parity_type    = 1'b0;
        stop_bits      = 2'd1;
        corrupt_stop   = 1'b0;
        corrupt_parity = 1'b0;
        direction      = DIR_RX_INTO_SOC;
        timestamp      = 0;
    endfunction

    // String representation for logging
    function string convert2string();
        string s;
        s = $sformatf("UART_ITEM [%s]: data=0x%02X ('%c') clks_per_bit=%0d par_en=%0b err_stop=%0b",
                      (direction == DIR_TX_FROM_SOC) ? "TX_FROM_SOC" : "RX_INTO_SOC",
                      data, (data >= 32 && data <= 126) ? data : ".",
                      clks_per_bit, parity_en, corrupt_stop);
        return s;
    endfunction

endclass : uart_vip_item

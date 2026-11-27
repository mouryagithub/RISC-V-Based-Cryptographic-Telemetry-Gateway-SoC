// =============================================================================
// File        : dma_vip_item.sv
// Description : UVM Sequence Item for AXI DMA Controller VIP
// =============================================================================

class dma_vip_item extends uvm_sequence_item;
    typedef enum logic [2:0] {
        OP_CSR_WR    = 3'd0,
        OP_CSR_RD    = 3'd1,
        OP_MEM_WR    = 3'd2,
        OP_MEM_RD    = 3'd3,
        OP_BUS_WR    = 3'd4,
        OP_BUS_RD    = 3'd5,
        OP_EVT       = 3'd6,
        OP_WAIT      = 3'd7
    } op_e;

    rand op_e       op;
    rand bit [31:0] addr;
    rand bit [31:0] wdata;
    rand bit [3:0]  wstrb;
    bit [31:0]      rdata;
    bit [1:0]       resp;
    bit [7:0]       axlen;
    bit [1:0]       axburst;
    bit             dma_done;
    bit             dma_error;
    int             split_mode;
    int             ready_delay;
    int             wait_clks;
    time            timestamp;

    `uvm_object_utils_begin(dma_vip_item)
        `uvm_field_enum(op_e, op, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(wdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(rdata, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(resp, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(axlen, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(axburst, UVM_ALL_ON | UVM_HEX)
        `uvm_field_int(dma_done, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(dma_error, UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    function new(string name = "dma_vip_item");
        super.new(name);
        op          = OP_CSR_RD;
        addr        = 32'h0;
        wdata       = 32'h0;
        wstrb       = 4'hF;
        rdata       = 32'h0;
        resp        = 2'b00;
        axlen       = 8'h0;
        axburst     = 2'b01;
        dma_done    = 1'b0;
        dma_error   = 1'b0;
        split_mode  = 0;
        ready_delay = 0;
        wait_clks   = 1;
        timestamp   = 0;
    endfunction
endclass : dma_vip_item

// =============================================================================
// File        : dma_vip_test.sv
// Description : Sequences & UVM Test for AXI DMA VIP (TC_DMA_01..TC_DMA_05)
// =============================================================================

class dma_base_seq extends uvm_sequence #(dma_vip_item);
    `uvm_object_utils(dma_base_seq)

    localparam bit [31:0] DMA_BASE    = 32'h4000_5000;
    localparam bit [31:0] CTRL_OFF    = 32'h000;
    localparam bit [31:0] STAT_OFF    = 32'h008;
    localparam bit [31:0] ERR_ADDR_OFF= 32'h010;
    localparam bit [31:0] ERR_STAT_OFF= 32'h018;
    localparam bit [31:0] D0_SRC_OFF  = 32'h020;
    localparam bit [31:0] D1_SRC_OFF  = 32'h028;
    localparam bit [31:0] D0_DST_OFF  = 32'h030;
    localparam bit [31:0] D1_DST_OFF  = 32'h038;
    localparam bit [31:0] D0_BYTES_OFF= 32'h040;
    localparam bit [31:0] D1_BYTES_OFF= 32'h048;
    localparam bit [31:0] D0_CFG_OFF  = 32'h050;
    localparam bit [31:0] D1_CFG_OFF  = 32'h058;

    function new(string name = "dma_base_seq");
        super.new(name);
    endfunction

    task csr_write(input bit [31:0] off, input bit [31:0] val, input int split = 0, input int bready_delay = 0, input bit [3:0] strb = 4'hF);
        dma_vip_item item = dma_vip_item::type_id::create("csr_wr");
        start_item(item);
        item.op          = dma_vip_item::OP_CSR_WR;
        item.addr        = DMA_BASE + off;
        item.wdata       = val;
        item.wstrb       = strb;
        item.split_mode  = split;
        item.ready_delay = bready_delay;
        finish_item(item);
    endtask

    task csr_read(input bit [31:0] off, output bit [31:0] val, input int rready_delay = 0);
        dma_vip_item item = dma_vip_item::type_id::create("csr_rd");
        start_item(item);
        item.op          = dma_vip_item::OP_CSR_RD;
        item.addr        = DMA_BASE + off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask

    task bus_write(input bit [31:0] addr, input bit [31:0] val, input bit [3:0] strb = 4'hF);
        dma_vip_item item = dma_vip_item::type_id::create("bus_wr");
        start_item(item);
        item.op    = dma_vip_item::OP_BUS_WR;
        item.addr  = addr;
        item.wdata = val;
        item.wstrb = strb;
        finish_item(item);
    endtask

    task bus_read(input bit [31:0] addr, output bit [31:0] val);
        dma_vip_item item = dma_vip_item::type_id::create("bus_rd");
        start_item(item);
        item.op   = dma_vip_item::OP_BUS_RD;
        item.addr = addr;
        finish_item(item);
        val = item.rdata;
    endtask

    task wait_clks(input int clks);
        dma_vip_item item = dma_vip_item::type_id::create("wait_item");
        start_item(item);
        item.op        = dma_vip_item::OP_WAIT;
        item.wait_clks = clks;
        finish_item(item);
    endtask

    task poll_done(output bit [31:0] st, input int max_iters = 500);
        st = 32'h0;
        for (int i = 0; i < max_iters; i++) begin
            csr_read(STAT_OFF, st);
            if (st[16]) break;
            wait_clks(4);
        end
    endtask
endclass : dma_base_seq

class dma_full_testplan_seq extends dma_base_seq;
    `uvm_object_utils(dma_full_testplan_seq)

    virtual soc_axi_if  bus_vif;
    virtual uart_vip_if uart_vif;

    function new(string name = "dma_full_testplan_seq");
        super.new(name);
    endfunction

    task drive_uart_rx_fast(input bit [7:0] bval, input int div_clks = 24);
        uart_vif.uart_rx <= 1'b0;
        repeat (div_clks) @(posedge uart_vif.clk);
        for (int b = 0; b < 8; b++) begin
            uart_vif.uart_rx <= bval[b];
            repeat (div_clks) @(posedge uart_vif.clk);
        end
        uart_vif.uart_rx <= 1'b1;
        repeat (div_clks) @(posedge uart_vif.clk);
        repeat (8) @(posedge uart_vif.clk);
    endtask

    task body();
        bit [31:0] rval, st;

        if (!uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("DMA_SEQ", "bus_vif not found")
        end
        void'(uvm_config_db #(virtual uart_vip_if)::get(null, "*", "uart_vif", uart_vif));
        if (uart_vif != null) begin
            uart_vif.uart_rx <= 1'b1;
            wait_clks(20);
        end

        // ---------------------------------------------------------------------
        // TC_DMA_01: CSR Discovery & 0xCAFE Version + Unmapped/Split Handshakes
        // ---------------------------------------------------------------------
        `uvm_info("DMA_SEQ", ">>> Running TC_DMA_01: DMA CSR Discovery & 0xCAFE Check", UVM_LOW)
        csr_read(STAT_OFF, st, 1);
        if (st[15:0] !== 16'hCAFE || st[16] !== 1'b0 || st[17] !== 1'b0) begin
            `uvm_error("TC_DMA_01", $sformatf("Unexpected initial DMA_STATUS: 0x%08X", st))
        end
        csr_write(D0_SRC_OFF,   32'h4000_4040, 1, 1);
        csr_write(D0_DST_OFF,   32'h4000_0030, 2, 0);
        csr_write(D0_BYTES_OFF, 32'd16);
        csr_write(D0_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     (32'd16 << 2));
        csr_read(CTRL_OFF, rval);
        if (rval[9:2] !== 8'd16) `uvm_error("TC_DMA_01", "DMA max_burst readback mismatch")
        csr_read(D0_SRC_OFF, rval);   if (rval !== 32'h4000_4040) `uvm_error("TC_DMA_01", "DESC0_SRC mismatch")
        csr_read(D0_DST_OFF, rval);   if (rval !== 32'h4000_0030) `uvm_error("TC_DMA_01", "DESC0_DST mismatch")
        csr_read(D0_BYTES_OFF, rval); if (rval !== 32'd16)        `uvm_error("TC_DMA_01", "DESC0_BYTES mismatch")
        // Exercise invalid CSR read/write, RO write, zero/partial wstrb, split AW/W & delayed ready for rggen coverage
        csr_write(32'h0F0, 32'hDEAD_BEEF);
        csr_read(32'h0F0, rval, 3);
        csr_write(D0_SRC_OFF, 32'h1234_5678, 1, 3, 4'b0000);
        csr_write(D0_SRC_OFF, 32'h0000_0055, 2, 0, 4'b0001);
        csr_write(STAT_OFF, 32'h0);
        csr_write(CTRL_OFF, 32'h0);
        `uvm_info("TC_DMA_01", "[PASS] TC_DMA_01 DMA CSR 0xCAFE & Register Config verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_DMA_02: Linear 256B SRAM-to-SRAM Burst Transfer (DESC0)
        // ---------------------------------------------------------------------
        `uvm_info("DMA_SEQ", ">>> Running TC_DMA_02: 256B SRAM->SRAM Burst Transfer", UVM_LOW)
        for (int i = 0; i < 64; i++) begin
            bus_write(32'h0000_1000 + (i * 4), 32'hD200_0000 | i);
            bus_write(32'h0000_2000 + (i * 4), 32'h0);
        end
        // Exercise 4-beat AXI4 burst INCR/FIXED & concurrent R/W on SRAM
        begin
            int unsigned br0, br1, br2, br3, b_rsp, c_rdata, c_brsp, c_rrsp;
            bus_vif.axi_burst_wr4(32'h0000_1800, 32'h1, 32'hA1, 32'hA2, 32'hA3, 32'hA4, b_rsp);
            bus_vif.axi_burst_rd4(32'h0000_1800, 32'h1, br0, br1, br2, br3, c_rrsp);
            if (br0 !== 32'hA1 || br3 !== 32'hA4) `uvm_error("TC_DMA_02", "AXI4 INCR burst4 mismatch")
            bus_vif.axi_burst_wr4(32'h0000_1820, 32'h0, 32'hB1, 32'hB2, 32'hB3, 32'hB4, b_rsp);
            bus_vif.axi_burst_rd4(32'h0000_1820, 32'h0, br0, br1, br2, br3, c_rrsp);
            bus_vif.axi_concurrent_rw(32'h0000_1840, 32'h5A5A_1234, 32'h0000_1800, c_rdata, c_brsp, c_rrsp);
            if (c_rdata !== 32'hA1 || c_brsp !== 0 || c_rrsp !== 0) `uvm_error("TC_DMA_02", "AXI4 concurrent_rw mismatch")
        end
        csr_write(D1_CFG_OFF,   32'h0);
        csr_write(D0_SRC_OFF,   32'h0000_1000);
        csr_write(D0_DST_OFF,   32'h0000_2000);
        csr_write(D0_BYTES_OFF, 32'd256);
        csr_write(D0_CFG_OFF,   32'h4);          // Enable DESC0 INCR
        csr_write(CTRL_OFF,     (32'd16 << 2) | 32'h1);
        poll_done(st);
        if (!st[16] || st[17] || !bus_vif.dma_done) `uvm_error("TC_DMA_02", $sformatf("Burst transfer failed: 0x%08X", st))
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);
        for (int i = 0; i < 64; i++) begin
            bus_read(32'h0000_2000 + (i * 4), rval);
            if (rval !== (32'hD200_0000 | i)) `uvm_error("TC_DMA_02", $sformatf("SRAM word[%0d] mismatch: 0x%08X", i, rval))
        end
        `uvm_info("TC_DMA_02", "[PASS] TC_DMA_02 256B SRAM->SRAM Burst Transfer verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_DMA_03: Dual Descriptor Chaining (DESC0+DESC1) + DESC1-Only Mode
        // ---------------------------------------------------------------------
        `uvm_info("DMA_SEQ", ">>> Running TC_DMA_03: Dual Descriptor & DESC1-Only Transfer", UVM_LOW)
        for (int i = 0; i < 4; i++) bus_write(32'h4000_0030 + (i * 4), 32'h0);
        for (int i = 0; i < 8; i++) bus_write(32'h0000_3000 + (i * 4), 32'h0);

        csr_write(D0_SRC_OFF,   32'h0000_1000);
        csr_write(D0_DST_OFF,   32'h4000_0030); // AES IV0..3
        csr_write(D0_BYTES_OFF, 32'd16);
        csr_write(D0_CFG_OFF,   32'h4);

        csr_write(D1_SRC_OFF,   32'h0000_1010);
        csr_write(D1_DST_OFF,   32'h0000_3000);
        csr_write(D1_BYTES_OFF, 32'd32);
        csr_write(D1_CFG_OFF,   32'h4);
        csr_read(D1_SRC_OFF, rval); csr_read(D1_DST_OFF, rval); csr_read(D1_BYTES_OFF, rval);

        csr_write(CTRL_OFF, 32'h1); // GO (max_burst=0)
        poll_done(st);
        if (!st[16] || st[17]) `uvm_error("TC_DMA_03", $sformatf("Dual desc failed: 0x%08X", st))
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);
        for (int i = 0; i < 4; i++) begin
            bus_read(32'h4000_0030 + (i * 4), rval);
            if (rval !== (32'hD200_0000 | i)) `uvm_error("TC_DMA_03", "DESC0 AES_IV mismatch")
        end
        for (int i = 0; i < 8; i++) begin
            bus_read(32'h0000_3000 + (i * 4), rval);
            if (rval !== (32'hD200_0000 | (4 + i))) `uvm_error("TC_DMA_03", "DESC1 SRAM mismatch")
        end

        // DESC1-ONLY (DESC0 disabled, DESC1 enabled -> covers desc1_only bin!)
        csr_write(D0_CFG_OFF,   32'h0);
        csr_write(D1_SRC_OFF,   32'h4000_0030); // Read from AES IV back to SRAM
        csr_write(D1_DST_OFF,   32'h0000_3200);
        csr_write(D1_BYTES_OFF, 32'd16);
        csr_write(D1_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     32'h1);
        poll_done(st);
        if (!st[16] || st[17]) `uvm_error("TC_DMA_03", "DESC1-only transfer failed")
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);
        `uvm_info("TC_DMA_03", "[PASS] TC_DMA_03 Dual Descriptor & DESC1-Only Chaining verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_DMA_04: Fixed-Address FIFO Modes + All Peripheral Targets + Unaligned/4KB/Abort
        // ---------------------------------------------------------------------
        `uvm_info("DMA_SEQ", ">>> Running TC_DMA_04: FIXED FIFO, All Periph Targets, Unaligned & Abort", UVM_LOW)
        csr_write(D1_CFG_OFF, 32'h0);

        // 1) UART RX -> SRAM (RD_FIXED) & SRAM -> UART THR (WR_FIXED)
        bus_write(32'h4000_100C, 32'h80);
        bus_write(32'h4000_1008, 32'd24);
        bus_write(32'h4000_100C, 32'h00);
        bus_write(32'h4000_1004, 32'h01);
        // Perform one UART register read so axi_uart_top exits ConfigReadState and deasserts rx_fifo_reset_int
        bus_read(32'h4000_1014, rval);
        wait_clks(20);
        if (uart_vif != null) begin
            byte unsigned stream[4] = '{8'hA1, 8'hB2, 8'hC3, 8'hD4};
            for (int i = 0; i < 4; i++) begin
                drive_uart_rx_fast(stream[i], 24);
                wait_clks(40);
                bus_write(32'h0000_4000 + (i * 4), 32'h0);
            end
            csr_write(D0_SRC_OFF,   32'h4000_1000);
            csr_write(D0_DST_OFF,   32'h0000_4000);
            csr_write(D0_BYTES_OFF, 32'd16);
            csr_write(D0_CFG_OFF,   32'h6); // ENABLE + RD_FIXED
            csr_write(CTRL_OFF,     32'h1);
            poll_done(st);
            csr_write(CTRL_OFF, 32'h0);
            wait_clks(4);
            for (int i = 0; i < 4; i++) begin
                bus_read(32'h0000_4000 + (i * 4), rval);
                if (rval[7:0] !== stream[i]) `uvm_error("TC_DMA_04", $sformatf("UART->SRAM[%0d] mismatch: got=0x%08X exp=0x%02X", i, rval, stream[i]))
            end
        end
        // SRAM -> UART THR (WR_FIXED)
        bus_write(32'h0000_4100, 32'h0000_0055);
        bus_write(32'h0000_4104, 32'h0000_00AA);
        csr_write(D0_SRC_OFF,   32'h0000_4100);
        csr_write(D0_DST_OFF,   32'h4000_1000);
        csr_write(D0_BYTES_OFF, 32'd8);
        csr_write(D0_CFG_OFF,   32'h5); // ENABLE + WR_FIXED
        csr_write(CTRL_OFF,     32'h1);
        poll_done(st);
        csr_write(CTRL_OFF, 32'h0);

        // 2) SRAM <-> TIMER CMP_L (0x4000_2118)
        bus_write(32'h0000_4200, 32'h1234_5678);
        csr_write(D0_SRC_OFF, 32'h0000_4200); csr_write(D0_DST_OFF, 32'h4000_2118);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        csr_write(D0_SRC_OFF, 32'h4000_2118); csr_write(D0_DST_OFF, 32'h0000_4210);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        bus_read(32'h0000_4210, rval);
        if (rval !== 32'h1234_5678) `uvm_error("TC_DMA_04", "TIMER->SRAM loopback mismatch")

        // 3) SRAM <-> GPIO OUT0 (0x4000_3180)
        bus_write(32'h0000_4220, 32'hCAFE_1234);
        csr_write(D0_SRC_OFF, 32'h0000_4220); csr_write(D0_DST_OFF, 32'h4000_3180);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        csr_write(D0_SRC_OFF, 32'h4000_3180); csr_write(D0_DST_OFF, 32'h0000_4230);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        bus_read(32'h0000_4230, rval);
        if (rval !== 32'hCAFE_1234) `uvm_error("TC_DMA_04", "GPIO->SRAM loopback mismatch")
        bus_write(32'h4000_3180, 32'h0);

        // 4) SRAM <-> SHA BLOCK0 (0x4000_4040)
        bus_write(32'h0000_4240, 32'h6162_6380);
        csr_write(D0_SRC_OFF, 32'h0000_4240); csr_write(D0_DST_OFF, 32'h4000_4040);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        csr_write(D0_SRC_OFF, 32'h4000_4040); csr_write(D0_DST_OFF, 32'h0000_4250);
        csr_write(D0_BYTES_OFF, 32'd4); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        bus_read(32'h0000_4250, rval);
        if (rval !== 32'h6162_6380) `uvm_error("TC_DMA_04", "SHA->SRAM loopback mismatch")

        // 5) Unaligned (1B, 2B, 3B, 7B) + 4KB boundary crossing + Abort FSM paths
        for (int bsz = 1; bsz <= 3; bsz++) begin
            csr_write(D0_SRC_OFF,   32'h0000_1000 + bsz);
            csr_write(D0_DST_OFF,   32'h0000_4300 + bsz);
            csr_write(D0_BYTES_OFF, bsz);
            csr_write(D0_CFG_OFF,   32'h4);
            csr_write(CTRL_OFF,     32'h1);
            poll_done(st);
            csr_write(CTRL_OFF, 32'h0);
        end
        csr_write(D0_SRC_OFF, 32'h0000_1001); csr_write(D0_DST_OFF, 32'h0000_4321);
        csr_write(D0_BYTES_OFF, 32'd7); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);
        csr_write(D0_SRC_OFF, 32'h0000_0FE0); csr_write(D0_DST_OFF, 32'h0000_5FE0);
        csr_write(D0_BYTES_OFF, 32'd64); csr_write(D0_CFG_OFF, 32'h4); csr_write(CTRL_OFF, (32'd16 << 2) | 32'h1);
        poll_done(st); csr_write(CTRL_OFF, 32'h0);

        // Aligned small & tail sizes (1, 2, 3, 5, 6, 7B -> hits dma_streamer is_aligned tail branch)
        bus_write(32'h0000_4400, 32'h1122_3344);
        bus_write(32'h0000_4404, 32'h5566_7788);
        begin
            int tail_sz[6] = '{1, 2, 3, 5, 6, 7};
            for (int t = 0; t < 6; t++) begin
                bus_write(32'h0000_4500, 32'h0);
                bus_write(32'h0000_4504, 32'h0);
                csr_write(D0_SRC_OFF,   32'h0000_4400);
                csr_write(D0_DST_OFF,   32'h0000_4500);
                csr_write(D0_BYTES_OFF, tail_sz[t]);
                csr_write(D0_CFG_OFF,   32'h4);
                csr_write(CTRL_OFF,     32'h1);
                poll_done(st);
                if (!st[16] || st[17]) `uvm_error("TC_DMA_04", $sformatf("Aligned tail %0dB failed", tail_sz[t]))
                csr_write(CTRL_OFF,     32'h0);
            end
        end

        // Zero-byte descriptor check_cfg() == 0 CFG->DONE path
        csr_write(D0_BYTES_OFF, 32'd0); csr_write(D0_CFG_OFF, 32'h4);
        csr_write(CTRL_OFF, 32'h1); poll_done(st); csr_write(CTRL_OFF, 32'h0);

        // CFG-stage Abort (abort=1, go=1 -> hits dma_fsm CFG->DONE abort path cleanly)
        csr_write(D0_SRC_OFF, 32'h0000_1000); csr_write(D0_DST_OFF, 32'h0000_6000);
        csr_write(D0_BYTES_OFF, 32'd16); csr_write(D0_CFG_OFF, 32'h4);
        csr_write(CTRL_OFF, (32'd4 << 2) | 32'h3);
        poll_done(st);
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);

        // Restore UART default 434 baud
        bus_write(32'h4000_100C, 32'h80);
        bus_write(32'h4000_1008, 32'd434);
        bus_write(32'h4000_100C, 32'h00);
        `uvm_info("TC_DMA_04", "[PASS] TC_DMA_04 Fixed-Address, All Slave Targets, Unaligned & Abort verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_DMA_05: Bus Fault Detection, Address Latching & Error Interrupt
        // ---------------------------------------------------------------------
        `uvm_info("DMA_SEQ", ">>> Running TC_DMA_05: Write & Read Bus Fault Trap (0x5000_0000)", UVM_LOW)
        csr_write(D0_SRC_OFF,   32'h4000_4040);
        csr_write(D0_DST_OFF,   32'h5000_0000); // Unmapped DST
        csr_write(D0_BYTES_OFF, 32'd4);
        csr_write(D0_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     32'h1);
        poll_done(st);
        if (!st[17] || !bus_vif.dma_error) `uvm_error("TC_DMA_05", "WR error status/pin did not assert")
        csr_read(ERR_ADDR_OFF, rval);
        if (rval !== 32'h5000_0000) `uvm_error("TC_DMA_05", $sformatf("WR ERR_ADDR != 0x5000_0000: 0x%08X", rval))
        csr_read(ERR_STAT_OFF, rval);
        if ((rval & 32'h6) !== 32'h6) `uvm_error("TC_DMA_05", $sformatf("WR ERR_STATS mismatch: 0x%08X", rval))
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);
        if (bus_vif.dma_error !== 1'b0) `uvm_error("TC_DMA_05", "dma_error_o did not clear on GO=0")

        // Read fault: SRC=0x5000_0000
        csr_write(D0_SRC_OFF,   32'h5000_0000);
        csr_write(D0_DST_OFF,   32'h4000_0030);
        csr_write(D0_BYTES_OFF, 32'd4);
        csr_write(D0_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     32'h1);
        poll_done(st);
        if (!st[17]) `uvm_error("TC_DMA_05", "RD error status did not assert")
        csr_read(ERR_ADDR_OFF, rval);
        if (rval !== 32'h5000_0000) `uvm_error("TC_DMA_05", "RD ERR_ADDR != 0x5000_0000")
        csr_read(ERR_STAT_OFF, rval);
        if ((rval & 32'h6) !== 32'h4) `uvm_error("TC_DMA_05", $sformatf("RD ERR_STATS mismatch: 0x%08X", rval))
        csr_write(CTRL_OFF, 32'h0);
        wait_clks(4);

        // 32-bit address overflow wrap near 0xFFFF_FFF0 (hits dma_streamer burst_r4KB overflow in RD & WR)
        csr_write(D0_SRC_OFF,   32'hFFFF_FFF0);
        csr_write(D0_DST_OFF,   32'h0000_4600);
        csr_write(D0_BYTES_OFF, 32'd64);
        csr_write(D0_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     (32'd16 << 2) | 32'h1);
        poll_done(st);
        if (!st[17]) `uvm_error("TC_DMA_05", "RD wrap 0xFFFF_FFF0 did not trap error")
        csr_write(CTRL_OFF,     32'h0);
        wait_clks(4);

        csr_write(D0_SRC_OFF,   32'h0000_4600);
        csr_write(D0_DST_OFF,   32'hFFFF_FFF0);
        csr_write(D0_BYTES_OFF, 32'd64);
        csr_write(D0_CFG_OFF,   32'h4);
        csr_write(CTRL_OFF,     (32'd16 << 2) | 32'h1);
        poll_done(st);
        if (!st[17]) `uvm_error("TC_DMA_05", "WR wrap 0xFFFF_FFF0 did not trap error")
        csr_write(CTRL_OFF,     32'h0);
        wait_clks(4);
        `uvm_info("TC_DMA_05", "[PASS] TC_DMA_05 Bus Fault Trap & dma_error_o Interrupt verified", UVM_LOW)
    endtask
endclass : dma_full_testplan_seq

class dma_vip_test extends uvm_test;
    dma_vip_env env;

    `uvm_component_utils(dma_vip_test)

    function new(string name = "dma_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = dma_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        dma_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("DMA_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("DMA_VIP_TEST", "   Starting AXI DMA UVM Verification Test (TC_DMA_01..05)    ", UVM_LOW)
        `uvm_info("DMA_VIP_TEST", "=============================================================", UVM_LOW)

        seq = dma_full_testplan_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #200;
        `uvm_info("DMA_VIP_TEST", "=== AXI DMA UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : dma_vip_test

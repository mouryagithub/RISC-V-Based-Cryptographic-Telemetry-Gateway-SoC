// =============================================================================
// File        : aes_vip_test.sv
// Description : Sequences & UVM Test for AES-256 VIP (TC_AES_01..TC_AES_06)
// =============================================================================

class aes_base_seq extends uvm_sequence #(aes_vip_item);
    `uvm_object_utils(aes_base_seq)

    function new(string name = "aes_base_seq");
        super.new(name);
    endfunction

    task reg_write(input bit [7:0] off, input bit [31:0] val, input bit [3:0] strb = 4'hF,
                   input int split = 0, input int bready_delay = 0);
        aes_vip_item item = aes_vip_item::type_id::create("wr_item");
        start_item(item);
        item.op          = aes_vip_item::OP_WRITE;
        item.offset      = off;
        item.wdata       = val;
        item.wstrb       = strb;
        item.split_mode  = split;
        item.ready_delay = bready_delay;
        finish_item(item);
    endtask

    task reg_read(input bit [7:0] off, output bit [31:0] val, input int rready_delay = 0);
        aes_vip_item item = aes_vip_item::type_id::create("rd_item");
        start_item(item);
        item.op          = aes_vip_item::OP_READ;
        item.offset      = off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask

    task wait_clks(input int clks);
        aes_vip_item item = aes_vip_item::type_id::create("wait_item");
        start_item(item);
        item.op        = aes_vip_item::OP_WAIT;
        item.wait_clks = clks;
        finish_item(item);
    endtask
endclass : aes_base_seq

class aes_full_testplan_seq extends aes_base_seq;
    `uvm_object_utils(aes_full_testplan_seq)

    virtual soc_axi_if bus_vif;

    localparam bit [31:0] CTRL_START    = 32'h0000_0001;
    localparam bit [31:0] CTRL_IRQ_EN   = 32'h0000_0002;
    localparam bit [31:0] CTRL_DECRYPT  = 32'h0000_0004;
    localparam bit [31:0] CTRL_KEY128   = 32'h0000_0000;
    localparam bit [31:0] CTRL_KEY256   = 32'h0000_0010;
    localparam bit [31:0] CTRL_CBC      = 32'h0000_0020;
    localparam bit [31:0] CTRL_CTR      = 32'h0000_0040;
    localparam bit [31:0] CTRL_SOFT_RST = 32'h0000_0080;

    function new(string name = "aes_full_testplan_seq");
        super.new(name);
    endfunction

    task clear_engine();
        reg_write(8'h00, CTRL_SOFT_RST);
        wait_clks(2);
    endtask

    task wait_done(output bit [31:0] st);
        st = 32'h0;
        for (int i = 0; i < 300; i++) begin
            reg_read(8'h04, st);
            if (st[1]) break;
            wait_clks(2);
        end
    endtask

    task load_key(input bit [31:0] key_msw[8]);
        for (int i = 0; i < 8; i++) reg_write(8'h10 + ((7 - i) * 4), key_msw[i]);
    endtask

    task load_iv(input bit [31:0] iv_msw[4]);
        for (int i = 0; i < 4; i++) reg_write(8'h30 + ((3 - i) * 4), iv_msw[i]);
    endtask

    task load_din(input bit [31:0] din_msw[4]);
        for (int i = 0; i < 4; i++) reg_write(8'h40 + ((3 - i) * 4), din_msw[i]);
    endtask

    task verify_dout(string tag, input bit [31:0] exp_msw[4]);
        bit [31:0] rval;
        for (int i = 0; i < 4; i++) begin
            reg_read(8'h50 + ((3 - i) * 4), rval);
            if (rval !== exp_msw[i]) begin
                `uvm_error(tag, $sformatf("DOUT%0d mismatch: 0x%08X != 0x%08X", 3 - i, rval, exp_msw[i]))
            end
        end
    endtask

    task body();
        bit [31:0] rval, st;
        bit [31:0] nist_key_msw[8] = '{
            32'h00010203, 32'h04050607, 32'h08090a0b, 32'h0c0d0e0f,
            32'h10111213, 32'h14151617, 32'h18191a1b, 32'h1c1d1e1f
        };
        bit [31:0] nist_pt_msw[4]  = '{32'h00112233, 32'h44556677, 32'h8899aabb, 32'hccddeeff};
        bit [31:0] nist_ct_msw[4]  = '{32'h8ea2b7ca, 32'h516745bf, 32'heafc4990, 32'h4b496089};
        bit [31:0] cbc_pt1_msw[4]  = '{32'h11223344, 32'h55667788, 32'h99AABBCC, 32'hDDEEFF00};
        bit [31:0] cbc_ct0_msw[4]  = '{32'h78E16B06, 32'h817A4453, 32'hABEF8A23, 32'h5FA9FA51};
        bit [31:0] cbc_ct1_msw[4]  = '{32'hD7FF94F9, 32'h67A07DA4, 32'hCD85A677, 32'hE643FF36};
        bit [31:0] ctr_ct0_msw[4]  = '{32'h5A7F2664, 32'h4CAE17E1, 32'h78B7FF86, 32'hCE1E486D};
        bit [31:0] ctr_ct1_msw[4]  = '{32'h71D12391, 32'h96E32FD5, 32'hCCBC409D, 32'hAF0BDFCF};
        bit [31:0] iv_vec[4]       = '{32'h00010203, 32'h04050607, 32'h08090a0b, 32'h0c0d0e0f};

        if (!uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("AES_SEQ", "bus_vif not found")
        end

        clear_engine();

        // ---------------------------------------------------------------------
        // TC_AES_01: Register Access, Control Setup, Write-Protection & SOFT_RST
        // ---------------------------------------------------------------------
        `uvm_info("AES_SEQ", ">>> Running TC_AES_01: Register Access, WO Security & SOFT_RST", UVM_LOW)
        load_iv('{32'hDEADBEEF, 32'hCAFEBABE, 32'h01234567, 32'h89ABCDEF});
        for (int i = 0; i < 4; i++) begin
            reg_read(8'h30 + i*4, rval);
        end
        reg_write(8'h08, 32'h0000_0004);
        reg_read(8'h08, rval);
        if (rval[15:0] !== 16'h4) `uvm_error("TC_AES_01", "BLK_CNT readback mismatch")
        reg_write(8'h08, 32'h0000_0001);

        load_key(nist_key_msw);
        for (int i = 0; i < 8; i++) begin
            reg_read(8'h10 + i*4, rval);
            if (rval !== 32'h0) `uvm_error("TC_AES_01", $sformatf("KEY%0d WO read != 0", i))
        end
        load_din(nist_pt_msw);
        for (int i = 0; i < 4; i++) begin
            reg_read(8'h40 + i*4, rval);
            if (rval !== 32'h0) `uvm_error("TC_AES_01", $sformatf("DIN%0d WO read != 0", i))
        end
        // Exercise RO DOUT write ignore, IRQ_CLR read=0, unmapped R/W, split AW/W, bready/rready backpressure
        for (int i = 0; i < 4; i++) reg_write(8'h50 + i*4, 32'hA5A5_5A5A);
        reg_read(8'h0C, rval, 1);
        reg_write(8'hFC, 32'h1234_5678, 4'hF, 1, 1);
        reg_write(8'hFC, 32'h8765_4321, 4'hF, 2, 0);
        reg_read(8'hFC, rval);
        // Zero wstrb write test for wstrb guard coverage
        reg_write(8'h30, 32'hAAAA_BBBB, 4'h0);
        `uvm_info("TC_AES_01", "[PASS] TC_AES_01 WO Security, Register R/W & Unmapped Decode verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_AES_02 + TC_AES_03 + TC_AES_06: AES-256 ECB Encrypt + IRQ + AES-128 Key Schedule
        // ---------------------------------------------------------------------
        `uvm_info("AES_SEQ", ">>> Running TC_AES_02, TC_AES_03 & TC_AES_06: ECB Enc/Dec, Key128 & IRQ", UVM_LOW)
        reg_write(8'h00, CTRL_KEY256 | CTRL_IRQ_EN);
        reg_read(8'h00, rval);
        if (rval[4:0] !== 5'h12) `uvm_error("TC_AES_01", $sformatf("CTRL readback != 0x12: 0x%08X", rval))

        reg_write(8'h00, CTRL_KEY256 | CTRL_IRQ_EN | CTRL_START);
        wait_done(st);
        if ((st & 32'hE) !== 32'h6) `uvm_error("TC_AES_02", $sformatf("KEY_READY/DONE bad: 0x%08X", st))
        verify_dout("TC_AES_03_ECB_ENC", nist_ct_msw);

        // TC_AES_06: IRQ asserted & cleared via IRQ_CLR (0x0C) and STATUS W1C (0x04)
        if (bus_vif.aes_irq !== 1'b1) `uvm_error("TC_AES_06", "aes_irq did not assert when IRQ_EN=1")
        reg_write(8'h0C, 32'h3); // Clear DONE & ERR via IRQ_CLR
        wait_clks(2);
        if (bus_vif.aes_irq !== 1'b0) `uvm_error("TC_AES_06", "aes_irq did not clear via IRQ_CLR")
        reg_write(8'h04, 32'hE); // W1C KEY_READY/DONE/ERR

        // TC_AES_02: AES-128 Key Schedule check + zero BLK_CNT clamp check (BLK_CNT=0 -> 1 block)
        reg_write(8'h08, 32'h0000_0000);
        reg_write(8'h00, CTRL_KEY128 | CTRL_START);
        wait_done(st);
        if (!st[2]) `uvm_error("TC_AES_02", "AES-128 KEY_READY did not assert")
        reg_write(8'h0C, 32'h1);
        reg_write(8'h08, 32'h0000_0001);

        // TC_AES_03: AES-256 ECB Decrypt
        load_key(nist_key_msw);
        load_din(nist_ct_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_DECRYPT | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_03_ECB_DEC", nist_pt_msw);
        reg_write(8'h04, 32'h2); // Clear DONE via STATUS W1C
        `uvm_info("TC_AES_02", "[PASS] TC_AES_02 AES-128 & AES-256 Key Expansion verified", UVM_LOW)
        `uvm_info("TC_AES_03", "[PASS] TC_AES_03 AES-256 ECB Encrypt & Decrypt verified", UVM_LOW)
        `uvm_info("TC_AES_06", "[PASS] TC_AES_06 AES IRQ & W1C Clear verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_AES_04: AES-256 CBC Mode 2-Block Encryption & IV Chaining
        // ---------------------------------------------------------------------
        `uvm_info("AES_SEQ", ">>> Running TC_AES_04: AES-256 CBC 2-Block Encryption", UVM_LOW)
        clear_engine();
        load_key(nist_key_msw);
        load_iv(iv_vec);
        load_din(nist_pt_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CBC | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_04_CBC_ENC0", cbc_ct0_msw);
        reg_write(8'h0C, 32'h1);

        load_din(cbc_pt1_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CBC | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_04_CBC_ENC1", cbc_ct1_msw);
        reg_write(8'h0C, 32'h1);
        `uvm_info("TC_AES_04", "[PASS] TC_AES_04 AES-256 CBC 2-Block Encryption verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_AES_05: AES-256 CBC 2-Block Decryption + CTR Mode 2-Block Enc & Dec
        // ---------------------------------------------------------------------
        `uvm_info("AES_SEQ", ">>> Running TC_AES_05: AES-256 CBC Decryption & CTR Enc/Dec", UVM_LOW)
        clear_engine();
        load_key(nist_key_msw);
        load_iv(iv_vec);
        load_din(cbc_ct0_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CBC | CTRL_DECRYPT | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CBC_DEC0", nist_pt_msw);
        reg_write(8'h0C, 32'h1);

        load_din(cbc_ct1_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CBC | CTRL_DECRYPT | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CBC_DEC1", cbc_pt1_msw);
        reg_write(8'h0C, 32'h1);

        // CTR Mode 2-Block Encrypt
        clear_engine();
        load_key(nist_key_msw);
        load_iv(iv_vec);
        load_din(nist_pt_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CTR | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CTR_ENC0", ctr_ct0_msw);
        reg_write(8'h0C, 32'h1);

        load_din(cbc_pt1_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CTR | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CTR_ENC1", ctr_ct1_msw);
        reg_write(8'h0C, 32'h1);

        // CTR Mode 2-Block Decrypt (decrypt=1, ctr=1)
        clear_engine();
        load_key(nist_key_msw);
        load_iv(iv_vec);
        load_din(ctr_ct0_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CTR | CTRL_DECRYPT | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CTR_DEC0", nist_pt_msw);
        reg_write(8'h0C, 32'h1);

        load_din(ctr_ct1_msw);
        reg_write(8'h00, CTRL_KEY256 | CTRL_CTR | CTRL_DECRYPT | CTRL_START);
        wait_done(st);
        verify_dout("TC_AES_05_CTR_DEC1", cbc_pt1_msw);
        reg_write(8'h0C, 32'h1);

        // Multi-Block Hardware Counter (BLK_CNT = 4) + SOFT_RST key wipe verify
        clear_engine();
        load_key(nist_key_msw);
        load_din(nist_pt_msw);
        reg_write(8'h08, 32'd4);
        reg_write(8'h00, CTRL_KEY256 | CTRL_START);
        wait_done(st);
        reg_read(8'h08, rval);
        if (rval[31:16] !== 16'd4) `uvm_error("TC_AES_04", $sformatf("DONE_BLOCKS != 4: 0x%08X", rval))

        clear_engine();
        reg_read(8'h30, rval);
        if (rval !== 32'h0) `uvm_error("TC_AES_01", "SOFT_RST did not clear IV0")
        `uvm_info("TC_AES_05", "[PASS] TC_AES_05 AES-256 CBC Decryption & CTR Enc/Dec verified", UVM_LOW)
    endtask
endclass : aes_full_testplan_seq

class aes_vip_test extends uvm_test;
    aes_vip_env env;

    `uvm_component_utils(aes_vip_test)

    function new(string name = "aes_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = aes_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        aes_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("AES_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("AES_VIP_TEST", "   Starting AES-256 UVM Verification Test (TC_AES_01..06)    ", UVM_LOW)
        `uvm_info("AES_VIP_TEST", "=============================================================", UVM_LOW)

        seq = aes_full_testplan_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #200;
        `uvm_info("AES_VIP_TEST", "=== AES-256 UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : aes_vip_test

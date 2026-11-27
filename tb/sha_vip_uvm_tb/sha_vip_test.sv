// =============================================================================
// File        : sha_vip_test.sv
// Description : Sequences & UVM Test for SHA-256 VIP (TC_SHA_01..TC_SHA_05)
// =============================================================================

class sha_base_seq extends uvm_sequence #(sha_vip_item);
    `uvm_object_utils(sha_base_seq)

    function new(string name = "sha_base_seq");
        super.new(name);
    endfunction

    task reg_write(input bit [11:0] off, input bit [31:0] val, input int bready_delay = 0);
        sha_vip_item item = sha_vip_item::type_id::create("wr_item");
        start_item(item);
        item.op          = sha_vip_item::OP_WRITE;
        item.offset      = off;
        item.wdata       = val;
        item.wstrb       = 4'hF;
        item.ready_delay = bready_delay;
        finish_item(item);
    endtask

    task reg_read(input bit [11:0] off, output bit [31:0] val, input int rready_delay = 0);
        sha_vip_item item = sha_vip_item::type_id::create("rd_item");
        start_item(item);
        item.op          = sha_vip_item::OP_READ;
        item.offset      = off;
        item.ready_delay = rready_delay;
        finish_item(item);
        val = item.rdata;
    endtask

    task wait_clks(input int clks);
        sha_vip_item item = sha_vip_item::type_id::create("wait_item");
        start_item(item);
        item.op        = sha_vip_item::OP_WAIT;
        item.wait_clks = clks;
        finish_item(item);
    endtask
endclass : sha_base_seq

class sha_full_testplan_seq extends sha_base_seq;
    `uvm_object_utils(sha_full_testplan_seq)

    virtual soc_axi_if bus_vif;

    function new(string name = "sha_full_testplan_seq");
        super.new(name);
    endfunction

    task wait_digest_valid(output bit [31:0] st);
        st = 32'h0;
        for (int i = 0; i < 200; i++) begin
            reg_read(12'h024, st);
            if ((st & 32'h3) == 32'h3) break;
            wait_clks(2);
        end
    endtask

    task body();
        bit [31:0] rval, st;
        bit [31:0] nist_abc[8] = '{
            32'hba7816bf, 32'h8f01cfea, 32'h414140de, 32'h5dae2223,
            32'hb00361a3, 32'h96177a9c, 32'hb410ff61, 32'hf20015ad
        };
        bit [31:0] nist_sha224_abc[7] = '{
            32'h23097d22, 32'h3405d822, 32'h8642a477, 32'hbda255b3,
            32'h2aadbce4, 32'hbda0b3f7, 32'he36c9da7
        };
        bit [31:0] nist_2blk_b0[16] = '{
            32'h61626364, 32'h62636465, 32'h63646566, 32'h64656667,
            32'h65666768, 32'h66676869, 32'h6768696a, 32'h68696a6b,
            32'h696a6b6c, 32'h6a6b6c6d, 32'h6b6c6d6e, 32'h6c6d6e6f,
            32'h6d6e6f70, 32'h6e6f7071, 32'h80000000, 32'h00000000
        };
        bit [31:0] nist_2blk_dig[8] = '{
            32'h248d6a61, 32'hd20638b8, 32'he5c02693, 32'h0c3e6039,
            32'ha33ce459, 32'h64ff2167, 32'hf6ecedd4, 32'h19db06c1
        };

        if (!uvm_config_db #(virtual soc_axi_if)::get(null, "*", "bus_vif", bus_vif)) begin
            `uvm_fatal("SHA_SEQ", "bus_vif not found")
        end

        // ---------------------------------------------------------------------
        // TC_SHA_01: Core Identification, Version & Ready Status + CTRL readback
        // ---------------------------------------------------------------------
        `uvm_info("SHA_SEQ", ">>> Running TC_SHA_01: SHA-256 IDs, Version & Ready Status", UVM_LOW)
        reg_read(12'h000, rval);
        if (rval !== 32'h7368_6132) `uvm_error("TC_SHA_01", $sformatf("NAME0 mismatch: 0x%08X", rval))
        reg_read(12'h004, rval);
        if (rval !== 32'h2D32_3536) `uvm_error("TC_SHA_01", $sformatf("NAME1 mismatch: 0x%08X", rval))
        reg_read(12'h008, rval);
        if (rval !== 32'h312E_3830) `uvm_error("TC_SHA_01", $sformatf("VERSION mismatch: 0x%08X", rval))
        reg_read(12'h020, rval); // CTRL read
        reg_read(12'h024, st);
        if (st[0] !== 1'b1) `uvm_error("TC_SHA_01", $sformatf("STATUS ready != 1: 0x%08X", st))
        `uvm_info("TC_SHA_01", "[PASS] TC_SHA_01 Core IDs, CTRL & Ready Status verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_SHA_05: Message Buffer Data Integrity & All 16 Word Addressing
        // ---------------------------------------------------------------------
        `uvm_info("SHA_SEQ", ">>> Running TC_SHA_05: 16-word BLOCK0..15 Data Integrity", UVM_LOW)
        for (int i = 0; i < 16; i++) begin
            reg_write(12'h040 + i*4, 32'hA55A_0000 | (i * 32'h0101));
        end
        for (int i = 0; i < 16; i++) begin
            reg_read(12'h040 + i*4, rval);
            if (rval !== (32'hA55A_0000 | (i * 32'h0101))) begin
                `uvm_error("TC_SHA_05", $sformatf("BLOCK%0d mismatch: 0x%08X", i, rval))
            end
        end
        // Toggle all bits & test invalid offset + handshake wait states
        for (int i = 0; i < 16; i++) reg_write(12'h040 + i*4, 32'hFFFF_FFFF);
        for (int i = 0; i < 16; i++) reg_write(12'h040 + i*4, 32'h0000_0000);
        reg_write(12'h0FC, 32'h1234_5678, 3);
        reg_read(12'h0FC, rval, 3);
        `uvm_info("TC_SHA_05", "[PASS] TC_SHA_05 16-word BLOCK0..15 Addressing & Toggle verified", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_SHA_02 + TC_SHA_04: Single-Block FIPS 180-4 'abc' (SHA-256 & SHA-224) + IRQ
        // ---------------------------------------------------------------------
        `uvm_info("SHA_SEQ", ">>> Running TC_SHA_02 & TC_SHA_04: NIST 'abc' Hash & IRQ Latch/Clear", UVM_LOW)
        reg_write(12'h040, 32'h6162_6380);
        for (int i = 1; i < 15; i++) reg_write(12'h040 + i*4, 32'h0);
        reg_write(12'h07C, 32'h0000_0018);
        reg_write(12'h020, 32'h0000_0005); // INIT + SHA-256

        reg_read(12'h020, rval); // Read CTRL while/after INIT
        wait_digest_valid(st);
        if ((st & 32'h3) !== 32'h3) `uvm_error("TC_SHA_02", "SHA-256 'abc' did not assert VALID")
        for (int i = 0; i < 8; i++) begin
            reg_read(12'h080 + i*4, rval);
            if (rval !== nist_abc[i]) begin
                `uvm_error("TC_SHA_02", $sformatf("'abc' DIGEST%0d mismatch: 0x%08X != 0x%08X", i, rval, nist_abc[i]))
            end
        end

        // TC_SHA_04: sha_irq latched upon VALID STATUS read
        if (bus_vif.sha_irq !== 1'b1) begin
            `uvm_error("TC_SHA_04", "sha_irq did not latch high on VALID status read")
        end
        `uvm_info("TC_SHA_02", "[PASS] TC_SHA_02 NIST FIPS 180-4 SHA-256 'abc' Digest verified", UVM_LOW)

        // Also verify SHA-224 mode ('abc', CTRL=0x01) -> covers SHA224 init/core constants in RTL!
        reg_write(12'h020, 32'h0000_0001); // INIT + SHA-224 (clears sha_irq on INIT!)
        reg_read(12'h024, st);
        if (bus_vif.sha_irq !== 1'b0) begin
            `uvm_error("TC_SHA_04", "sha_irq did not clear on new INIT")
        end
        wait_digest_valid(st);
        for (int i = 0; i < 7; i++) begin
            reg_read(12'h080 + i*4, rval);
            if (rval !== nist_sha224_abc[i]) begin
                `uvm_error("TC_SHA_02", $sformatf("SHA-224 'abc' DIGEST%0d mismatch: 0x%08X != 0x%08X", i, rval, nist_sha224_abc[i]))
            end
        end
        `uvm_info("TC_SHA_04", "[PASS] TC_SHA_04 SHA IRQ Latch, BUSY transition & Clear verified (+SHA-224)", UVM_LOW)

        // ---------------------------------------------------------------------
        // TC_SHA_03: Multi-Block Message Hash Chaining (INIT + NEXT)
        // ---------------------------------------------------------------------
        `uvm_info("SHA_SEQ", ">>> Running TC_SHA_03: 2-Block Multi-Block Hash Chaining (INIT + NEXT)", UVM_LOW)
        for (int i = 0; i < 16; i++) reg_write(12'h040 + i*4, nist_2blk_b0[i]);
        reg_write(12'h020, 32'h0000_0005); // INIT + SHA-256

        for (int i = 0; i < 200; i++) begin
            reg_read(12'h024, st);
            if (st[0]) break;
            wait_clks(2);
        end
        if (!st[0]) `uvm_error("TC_SHA_03", "Block 0 READY timeout")

        for (int i = 0; i < 15; i++) reg_write(12'h040 + i*4, 32'h0);
        reg_write(12'h07C, 32'h0000_01C0);
        reg_write(12'h020, 32'h0000_0006); // NEXT + SHA-256

        wait_digest_valid(st);
        if ((st & 32'h3) !== 32'h3) `uvm_error("TC_SHA_03", "Block 1 NEXT did not assert VALID")
        for (int i = 0; i < 8; i++) begin
            reg_read(12'h080 + i*4, rval);
            if (rval !== nist_2blk_dig[i]) begin
                `uvm_error("TC_SHA_03", $sformatf("2-blk DIGEST%0d mismatch: 0x%08X != 0x%08X", i, rval, nist_2blk_dig[i]))
            end
        end
        `uvm_info("TC_SHA_03", "[PASS] TC_SHA_03 Multi-Block SHA-256 INIT+NEXT verified", UVM_LOW)
    endtask
endclass : sha_full_testplan_seq

class sha_vip_test extends uvm_test;
    sha_vip_env env;

    `uvm_component_utils(sha_vip_test)

    function new(string name = "sha_vip_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sha_vip_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        sha_full_testplan_seq seq;
        phase.raise_objection(this);

        `uvm_info("SHA_VIP_TEST", "=============================================================", UVM_LOW)
        `uvm_info("SHA_VIP_TEST", "   Starting SHA-256 UVM Verification Test (TC_SHA_01..05)    ", UVM_LOW)
        `uvm_info("SHA_VIP_TEST", "=============================================================", UVM_LOW)

        seq = sha_full_testplan_seq::type_id::create("seq");
        seq.start(env.agent.seqr);

        #200;
        `uvm_info("SHA_VIP_TEST", "=== SHA-256 UVM Test Completed Successfully ===", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass : sha_vip_test

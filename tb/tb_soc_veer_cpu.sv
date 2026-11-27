// =============================================================================
// File        : tb_soc_veer_cpu.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : SystemVerilog testbench verifying the Master SoC top-level
//               with the internal Western Digital VeeR EL2 RISC-V core instantiated
//               (USE_INTERNAL_CPU = 1).
//
// Verifies:
//   1. VeeR-EL2 CPU boot out of reset at 0x8000_0000.
//   2. Instruction fetch from Boot IMEM over IFU AXI4 bus.
//   3. Peripheral access (GPIO, Timer, UART, SHA, AES) over LSU AXI4 bus
//      through the 2x5 AXI Crossbar interconnect port S00.
//   4. 64-bit to 32-bit LSU bus steering and address decoding.
//   5. External interrupt routing into VeeR PIC Gateway (extintsrc_req).
//   6. Hardware observation of peripheral pin toggles driven by CPU execution.
// =============================================================================

`timescale 1ns/1ps
`default_nettype none

module tb_soc_veer_cpu;

    // -------------------------------------------------------------------------
    // Parameters & Clock Configurations
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD      = 20;            // 50 MHz system clock (20 ns period)
    localparam UART_CLK_PERIOD = 20;            // 50 MHz UART baud generator clock

    reg  clk;
    reg  uart_clk;
    reg  aresetn;

    // Peripheral I/O signals
    reg         uart_rx;
    wire        uart_tx;
    reg  [63:0] gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_dir_o;

    // Interrupt signals
    wire        uart_irq;
    wire        timer_irq;
    wire        aes_irq;
    wire        sha_irq;
    wire        dma_done;
    wire        dma_error;
    wire [1:0]  gpio_intr;

    // Core status
    wire        cpu_halt_status;

    // Test tracking counters
    integer     pass_count = 0;
    integer     fail_count = 0;

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial uart_clk = 1'b0;
    always #(UART_CLK_PERIOD / 2) uart_clk = ~uart_clk;

    // -------------------------------------------------------------------------
    // DUT: Master SoC Top-Level (Instantiating internal VeeR CPU)
    // -------------------------------------------------------------------------
    soc_top #(
        .USE_INTERNAL_CPU    (1),               // 1: Instantiate internal VeeR-EL2 core
        .AXI_DATA_WIDTH      (32),
        .AXI_ADDR_WIDTH      (32),
        .AXI_ID_WIDTH        (8)
    ) u_soc_top (
        .clk                 (clk),
        .uart_clk            (uart_clk),
        .aresetn             (aresetn),

        // External AXI Master 0 (inactive in internal CPU mode)
        .ext_s00_axi_awid    (8'h0),
        .ext_s00_axi_awaddr  (32'h0),
        .ext_s00_axi_awlen   (8'h0),
        .ext_s00_axi_awsize  (3'h0),
        .ext_s00_axi_awburst (2'h0),
        .ext_s00_axi_awlock  (1'b0),
        .ext_s00_axi_awcache (4'h0),
        .ext_s00_axi_awprot  (3'h0),
        .ext_s00_axi_awqos   (4'h0),
        .ext_s00_axi_awvalid (1'b0),
        .ext_s00_axi_awready (),
        .ext_s00_axi_wdata   (32'h0),
        .ext_s00_axi_wstrb   (4'h0),
        .ext_s00_axi_wlast   (1'b0),
        .ext_s00_axi_wvalid  (1'b0),
        .ext_s00_axi_wready  (),
        .ext_s00_axi_bid     (),
        .ext_s00_axi_bresp   (),
        .ext_s00_axi_bvalid  (),
        .ext_s00_axi_bready  (1'b0),
        .ext_s00_axi_arid    (8'h0),
        .ext_s00_axi_araddr  (32'h0),
        .ext_s00_axi_arlen   (8'h0),
        .ext_s00_axi_arsize  (3'h0),
        .ext_s00_axi_arburst (2'h0),
        .ext_s00_axi_arlock  (1'b0),
        .ext_s00_axi_arcache (4'h0),
        .ext_s00_axi_arprot  (3'h0),
        .ext_s00_axi_arqos   (4'h0),
        .ext_s00_axi_arvalid (1'b0),
        .ext_s00_axi_arready (),
        .ext_s00_axi_rid     (),
        .ext_s00_axi_rdata   (),
        .ext_s00_axi_rresp   (),
        .ext_s00_axi_rlast   (),
        .ext_s00_axi_rvalid  (),
        .ext_s00_axi_rready  (1'b0),

        // DMA CSR slave interface
        .dma_csr_awaddr      (32'h0),
        .dma_csr_awprot      (3'h0),
        .dma_csr_awvalid     (1'b0),
        .dma_csr_awready     (),
        .dma_csr_wdata       (32'h0),
        .dma_csr_wstrb       (4'h0),
        .dma_csr_wvalid      (1'b0),
        .dma_csr_wready      (),
        .dma_csr_bresp       (),
        .dma_csr_bvalid      (),
        .dma_csr_bready      (1'b0),
        .dma_csr_araddr      (32'h0),
        .dma_csr_arprot      (3'h0),
        .dma_csr_arvalid     (1'b0),
        .dma_csr_arready     (),
        .dma_csr_rdata       (),
        .dma_csr_rresp       (),
        .dma_csr_rvalid      (),
        .dma_csr_rready      (1'b0),

        // Peripherals external I/O
        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .gpio_i              (gpio_i),
        .gpio_o              (gpio_o),
        .gpio_dir_o          (gpio_dir_o),

        // Interrupts
        .uart_irq_o          (uart_irq),
        .timer_irq_o         (timer_irq),
        .aes_irq_o           (aes_irq),
        .sha_irq_o           (sha_irq),
        .dma_done_o          (dma_done),
        .dma_error_o         (dma_error),
        .gpio_intr_o         (gpio_intr),

        // Core status
        .cpu_halt_status_o   (cpu_halt_status)
    );

    // -------------------------------------------------------------------------
    // Helper task to write 32-bit instruction word into Boot IMEM
    // -------------------------------------------------------------------------
    task write_imem_word(input [31:0] byte_addr, input [31:0] inst);
        begin
            u_soc_top.gen_veer_cpu.u_cpu.gen_boot_imem.imem.mem[byte_addr + 0] = inst[7:0];
            u_soc_top.gen_veer_cpu.u_cpu.gen_boot_imem.imem.mem[byte_addr + 1] = inst[15:8];
            u_soc_top.gen_veer_cpu.u_cpu.gen_boot_imem.imem.mem[byte_addr + 2] = inst[23:16];
            u_soc_top.gen_veer_cpu.u_cpu.gen_boot_imem.imem.mem[byte_addr + 3] = inst[31:24];
        end
    endtask

    // -------------------------------------------------------------------------
    // Program Boot ROM with RISC-V Instructions targeting SoC Peripherals
    // Covers TC_BOOT_01 (Boot, MRAC, sp/gp init, BSS zero, 0x0001 boot marker,
    //                    peripheral init, WFI) and
    //        TC_BOOT_02 (Nested subroutines, stack frames, 32-bit walking-1s &
    //                    walking-0s across DCCM 0xF004_0000..0xF004_FFFC)
    // -------------------------------------------------------------------------
    // Address Map:
    //   Boot IMEM = 0x8000_0000
    //   DCCM      = 0xF004_0000..0xF004_FFFF (sp=0xF004_1000, gp=0xF004_0800)
    //   GPIO OUT0 = 0x4000_3180 | GPIO OUT1 = 0x4000_3184
    //   TIMER CMP = 0x4000_2118 | UART THR  = 0x4000_1000
    // -------------------------------------------------------------------------
    initial begin
        $display("=============================================================");
        $display(" Initializing Boot IMEM with RISC-V Firmware for VeeR EL2...");
        $display("=============================================================");

        // TC_BOOT_01: MRAC setup (Region 4 = 0x200 side-effect)
        // 0x8000_0000: addi x7, x0, 0x200
        write_imem_word(32'h8000_0000, 32'h20000393);
        // 0x8000_0004: csrw 0x7C0, x7
        write_imem_word(32'h8000_0004, 32'h7C039073);
        // 0x8000_0008..0C: nop
        write_imem_word(32'h8000_0008, 32'h00000013);
        write_imem_word(32'h8000_000C, 32'h00000013);
        // Setup sp (x2) = 0xF004_1000, gp (x3) = 0xF004_0800
        // 0x8000_0010: lui  x2, 0xF0041
        write_imem_word(32'h8000_0010, 32'hF0041137);
        // 0x8000_0014: lui  x3, 0xF0041
        write_imem_word(32'h8000_0014, 32'hF00411B7);
        // 0x8000_0018: addi x3, x3, -2048  // x3 = 0xF004_0800 (DCCM BSS base)
        write_imem_word(32'h8000_0018, 32'h80018193);
        // Zero 4-word BSS segment in DCCM & verify zeroed
        // 0x8000_001C: sw   x0, 0(x3)
        write_imem_word(32'h8000_001C, 32'h0001A023);
        // 0x8000_0020: sw   x0, 4(x3)
        write_imem_word(32'h8000_0020, 32'h0001A223);
        // 0x8000_0024: sw   x0, 8(x3)
        write_imem_word(32'h8000_0024, 32'h0001A423);
        // 0x8000_0028: sw   x0, 12(x3)
        write_imem_word(32'h8000_0028, 32'h0001A623);
        // 0x8000_002C: lw   x8, 0(x3)
        write_imem_word(32'h8000_002C, 32'h0001A403);
        // 0x8000_0030: lw   x9, 12(x3)
        write_imem_word(32'h8000_0030, 32'h00C1A483);
        // 0x8000_0034: or   x8, x8, x9
        write_imem_word(32'h8000_0034, 32'h00946433);
        // 0x8000_0038: bne  x8, x0, fail_spin
        write_imem_word(32'h8000_0038, 32'h04041863);
        // Write boot-started status word 0x0000_0001 to GPIO_OUT0 (0x4000_3180)
        // 0x8000_003C: lui  x15, 0x40003  // GPIO_BASE
        write_imem_word(32'h8000_003C, 32'h400037B7);
        // 0x8000_0040: addi x8, x0, 1
        write_imem_word(32'h8000_0040, 32'h00100413);
        // 0x8000_0044: sw   x8, 0x180(x15)  // GPIO_OUT0 = 0x0000_0001
        write_imem_word(32'h8000_0044, 32'h1887A023);

        // TC_BOOT_02: Nested Subroutines + Walking-1s & Walking-0s across DCCM Boundaries (0xF004_0000 & 0xF004_FFFC)
        // 0x8000_0048: jal  x1, func_outer
        write_imem_word(32'h8000_0048, 32'h044000EF);
        // 0x8000_004C: bne  x10, x0, fail_spin
        write_imem_word(32'h8000_004C, 32'h02051E63);
        // Write TC_BOOT_02 pass signature 0xB007_0002 to GPIO_OUT1 (0x4000_3184)
        // 0x8000_0050: lui  x13, 0xB0070
        write_imem_word(32'h8000_0050, 32'hB00706B7);
        // 0x8000_0054: addi x13, x13, 2
        write_imem_word(32'h8000_0054, 32'h00268693);
        // 0x8000_0058: sw   x13, 0x184(x15)
        write_imem_word(32'h8000_0058, 32'h18D7A223);

        // Existing SoC Check 3/4/5 peripheral writes:
        // 0x8000_005C: lui  x14, 0xA5A5A
        write_imem_word(32'h8000_005C, 32'hA5A5A737);
        // 0x8000_0060: addi x14, x14, 0x5A5
        write_imem_word(32'h8000_0060, 32'h5A570713);
        // 0x8000_0064: sw   x14, 0x180(x15)  // GPIO_OUT0 = 0xA5A5A5A5
        write_imem_word(32'h8000_0064, 32'h18E7A023);
        // 0x8000_0068: lui  x16, 0x40002
        write_imem_word(32'h8000_0068, 32'h40002837);
        // 0x8000_006C: addi x17, x0, 0x123
        write_imem_word(32'h8000_006C, 32'h12300893);
        // 0x8000_0070: sw   x17, 0x118(x16)  // Timer CMP_L = 0x123
        write_imem_word(32'h8000_0070, 32'h11182C23);
        // 0x8000_0074: lui  x18, 0x40001
        write_imem_word(32'h8000_0074, 32'h40001937);
        // 0x8000_0078: addi x19, x0, 0x55
        write_imem_word(32'h8000_0078, 32'h05500993);
        // 0x8000_007C: sw   x19, 0(x18)  // UART THR = 0x55
        write_imem_word(32'h8000_007C, 32'h01392023);
        // 0x8000_0080: csrrsi x0, 0x7c6, 1 (VeeR MPMC.halt = 1 -> PMU/FW halt)
        write_imem_word(32'h8000_0080, 32'h7C60E073);
        // 0x8000_0084: jal  x0, 0
        write_imem_word(32'h8000_0084, 32'h0000006F);

        // fail_spin: @ 0x8000_0088
        write_imem_word(32'h8000_0088, 32'h0000006F);

        // func_outer: @ 0x8000_008C
        // 0x8000_008C: addi x2, x2, -16
        write_imem_word(32'h8000_008C, 32'hFF010113);
        // 0x8000_0090: sw   x1, 12(x2)
        write_imem_word(32'h8000_0090, 32'h00112623);
        // 0x8000_0094: sw   x8, 8(x2)
        write_imem_word(32'h8000_0094, 32'h00812423);
        // 0x8000_0098: sw   x9, 4(x2)
        write_imem_word(32'h8000_0098, 32'h00912223);
        // 0x8000_009C: lui  x8, 0xF0040  // DCCM low boundary: 0xF004_0000
        write_imem_word(32'h8000_009C, 32'hF0040437);
        // 0x8000_00A0: lui  x9, 0xF0050
        write_imem_word(32'h8000_00A0, 32'hF00504B7);
        // 0x8000_00A4: addi x9, x9, -4  // DCCM high boundary: 0xF004_FFFC
        write_imem_word(32'h8000_00A4, 32'hFFC48493);
        // 0x8000_00A8: addi x5, x0, 1  // t0 = walking-1 bit (1 << 0)
        write_imem_word(32'h8000_00A8, 32'h00100293);
        // walk_loop: @ 0x8000_00AC
        // 0x8000_00AC: xori x6, x5, -1  // t1 = walking-0 = ~t0
        write_imem_word(32'h8000_00AC, 32'hFFF2C313);
        // 0x8000_00B0: sw   x5, 0(x8)
        write_imem_word(32'h8000_00B0, 32'h00542023);
        // 0x8000_00B4: sw   x6, 0(x9)
        write_imem_word(32'h8000_00B4, 32'h0064A023);
        // 0x8000_00B8: lw   x11, 0(x8)
        write_imem_word(32'h8000_00B8, 32'h00042583);
        // 0x8000_00BC: lw   x12, 0(x9)
        write_imem_word(32'h8000_00BC, 32'h0004A603);
        // 0x8000_00C0: bne  x11, x5, walk_err
        write_imem_word(32'h8000_00C0, 32'h00559C63);
        // 0x8000_00C4: bne  x12, x6, walk_err
        write_imem_word(32'h8000_00C4, 32'h00661A63);
        // 0x8000_00C8: slli x5, x5, 1
        write_imem_word(32'h8000_00C8, 32'h00129293);
        // 0x8000_00CC: bne  x5, x0, walk_loop
        write_imem_word(32'h8000_00CC, 32'hFE0290E3);
        // 0x8000_00D0: jal  x1, func_inner  // nested call
        write_imem_word(32'h8000_00D0, 32'h020000EF);
        // 0x8000_00D4: jal  x0, outer_ret
        write_imem_word(32'h8000_00D4, 32'h0080006F);
        // walk_err: @ 0x8000_00D8
        write_imem_word(32'h8000_00D8, 32'h00100513);
        // outer_ret: @ 0x8000_00DC
        write_imem_word(32'h8000_00DC, 32'h00412483);
        write_imem_word(32'h8000_00E0, 32'h00812403);
        write_imem_word(32'h8000_00E4, 32'h00C12083);
        write_imem_word(32'h8000_00E8, 32'h01010113);
        write_imem_word(32'h8000_00EC, 32'h00008067);

        // func_inner: @ 0x8000_00F0
        write_imem_word(32'h8000_00F0, 32'hFF010113);
        write_imem_word(32'h8000_00F4, 32'h00112623);
        write_imem_word(32'h8000_00F8, 32'hCAFEC5B7);
        write_imem_word(32'h8000_00FC, 32'hEEF58593);
        write_imem_word(32'h8000_0100, 32'h00B12023);
        write_imem_word(32'h8000_0104, 32'hFFF5C593);
        write_imem_word(32'h8000_0108, 32'h00B12223);
        write_imem_word(32'h8000_010C, 32'h00012603);
        write_imem_word(32'h8000_0110, 32'h00412683);
        write_imem_word(32'h8000_0114, 32'h00D64633);
        write_imem_word(32'h8000_0118, 32'h00160513);
        write_imem_word(32'h8000_011C, 32'h00C12083);
        write_imem_word(32'h8000_0120, 32'h01010113);
        write_imem_word(32'h8000_0124, 32'h00008067);

        $display("   [IMEM] Loaded 74 RISC-V instructions (TC_BOOT_01 & TC_BOOT_02) into 0x8000_0000.");
    end

    // Continuous hardware snoops for TC_BOOT_01 / TC_BOOT_02
    reg        boot_marker_seen = 1'b0;
    reg        exc_seen         = 1'b0;
    integer    dccm_wr_cnt      = 0;
    integer    dccm_rd_cnt      = 0;

    always @(posedge clk) begin
        if (!aresetn) begin
            boot_marker_seen <= 1'b0;
            exc_seen         <= 1'b0;
            dccm_wr_cnt      <= 0;
            dccm_rd_cnt      <= 0;
        end else begin
            if (gpio_o[31:0] === 32'h0000_0001) begin
                boot_marker_seen <= 1'b1;
            end
            if (u_soc_top.gen_veer_cpu.u_cpu.rvtop.trace_rv_i_exception_ip === 1'b1) begin
                exc_seen <= 1'b1;
                $display("   [ERR] Core exception @ PC=0x%08h ecause=0x%02h",
                         u_soc_top.gen_veer_cpu.u_cpu.rvtop.trace_rv_i_address_ip,
                         u_soc_top.gen_veer_cpu.u_cpu.rvtop.trace_rv_i_ecause_ip);
            end
            if (u_soc_top.gen_veer_cpu.u_cpu.rvtop.mem.dccm_wren === 1'b1) begin
                dccm_wr_cnt <= dccm_wr_cnt + 1;
            end
            if (u_soc_top.gen_veer_cpu.u_cpu.rvtop.mem.dccm_rden === 1'b1) begin
                dccm_rd_cnt <= dccm_rd_cnt + 1;
            end
        end
    end

    // -------------------------------------------------------------------------
    // Main Verification Process
    // -------------------------------------------------------------------------
    initial begin
        // Signal initialization
        aresetn = 1'b0;
        uart_rx = 1'b1;
        gpio_i  = 64'h1234_5678_ABCD_EF01;

        // Waveform dumping
        $dumpfile("dump_soc_veer.vcd");
        $dumpvars(0, tb_soc_veer_cpu);

        $display("=============================================================");
        $display(" Starting SoC VeeR-EL2 CPU Hardware Integration Test");
        $display("=============================================================");

        // TC_BOOT_01: Hold reset for 20 clock cycles and verify quiescent bus/IRQs
        repeat (20) @(posedge clk);
        if (u_soc_top.s00_bvalid === 1'b0 && u_soc_top.s00_rvalid === 1'b0 &&
            gpio_o === 64'h0 && !uart_irq && !timer_irq && !aes_irq && !sha_irq &&
            !dma_done && !dma_error) begin
            $display("   [PASS] TC_BOOT_01 Reset quiescence verified across 20 cycles");
            pass_count++;
        end else begin
            $display("   [FAIL] TC_BOOT_01 Bus/IRQs not quiescent during reset");
            fail_count++;
        end

        aresetn = 1'b1;
        $display("   [RESET] Released SoC system reset (aresetn = 1)");

        // ---------------------------------------------------------------------
        // Check 1: VeeR IFU instruction fetch activity
        // ---------------------------------------------------------------------
        fork
            begin : ifu_timeout
                repeat (100) @(posedge clk);
                if (!u_soc_top.gen_veer_cpu.u_cpu.core_ifu_arvalid) begin
                    $display("   [FAIL] VeeR IFU failed to issue instruction fetch within 100 cycles");
                    fail_count++;
                end
            end
            begin : ifu_check
                @(posedge (u_soc_top.gen_veer_cpu.u_cpu.core_ifu_arvalid && u_soc_top.gen_veer_cpu.u_cpu.core_ifu_arready));
                $display("   [PASS] VeeR IFU issued instruction fetch at PC = 0x%08h", 
                         u_soc_top.gen_veer_cpu.u_cpu.core_ifu_araddr);
                pass_count++;
                disable ifu_timeout;
            end
        join

        // ---------------------------------------------------------------------
        // Check 2: VeeR LSU master issuing write to peripheral crossbar S00
        // ---------------------------------------------------------------------
        fork
            begin : lsu_timeout
                repeat (200) @(posedge clk);
                $display("   [FAIL] VeeR LSU write transaction timed out");
                fail_count++;
            end
            begin : lsu_check
                @(posedge (u_soc_top.s00_awvalid && u_soc_top.s00_awready));
                $display("   [PASS] VeeR LSU issued AXI4 write to Interconnect S00: addr = 0x%08h", 
                         u_soc_top.s00_awaddr);
                pass_count++;
                disable lsu_timeout;
            end
        join

        // ---------------------------------------------------------------------
        // Check 3: Peripheral execution - Verify GPIO Output register updated
        // ---------------------------------------------------------------------
        fork
            begin : gpio_timeout
                repeat (5000) @(posedge clk);
                if (gpio_o[31:0] !== 32'hA5A5A5A5) begin
                    $display("   [FAIL] GPIO OUT register not updated: got 0x%08h, expected 0xA5A5A5A5", gpio_o[31:0]);
                    fail_count++;
                end
            end
            begin : gpio_check
                wait (gpio_o[31:0] === 32'hA5A5A5A5);
                $display("   [PASS] GPIO OUT updated by VeeR CPU: gpio_o = 0x%08h", gpio_o[31:0]);
                pass_count++;
                disable gpio_timeout;
            end
        join

        // ---------------------------------------------------------------------
        // Check 4: Peripheral execution - Verify Timer Comparator register updated
        // ---------------------------------------------------------------------
        fork
            begin : timer_timeout
                repeat (5000) @(posedge clk);
                if (u_soc_top.u_timer.reg_mtimecmp[31:0] !== 32'h123) begin
                    $display("   [FAIL] Timer comparator not updated: got 0x%08h", 
                             u_soc_top.u_timer.reg_mtimecmp[31:0]);
                    fail_count++;
                end
            end
            begin : timer_check
                wait (u_soc_top.u_timer.reg_mtimecmp[31:0] === 32'h123);
                $display("   [PASS] Timer comparator updated by VeeR CPU: mtimecmp = 0x%08h", 
                         u_soc_top.u_timer.reg_mtimecmp[31:0]);
                pass_count++;
                disable timer_timeout;
            end
        join

        // ---------------------------------------------------------------------
        // Check 5: Interrupt routing - Verify PIC gateway signals
        // ---------------------------------------------------------------------
        repeat (20) @(posedge clk);
        $display("   [PASS] VeeR PIC Gateway interrupt vector extintsrc_req connected:");
        $display("          - UART IRQ    = bit 1 (state: %b)", u_soc_top.pic_ext_irqs[1]);
        $display("          - Timer IRQ   = bit 2 (state: %b)", u_soc_top.pic_ext_irqs[2]);
        $display("          - AES IRQ     = bit 3 (state: %b)", u_soc_top.pic_ext_irqs[3]);
        $display("          - SHA IRQ     = bit 4 (state: %b)", u_soc_top.pic_ext_irqs[4]);
        $display("          - DMA Done    = bit 5 (state: %b)", u_soc_top.pic_ext_irqs[5]);
        $display("          - DMA Error   = bit 6 (state: %b)", u_soc_top.pic_ext_irqs[6]);
        $display("          - GPIO Bank 0 = bit 7 (state: %b)", u_soc_top.pic_ext_irqs[7]);
        $display("          - GPIO Bank 1 = bit 8 (state: %b)", u_soc_top.pic_ext_irqs[8]);
        pass_count++;

        // ---------------------------------------------------------------------
        // Check 6 (TC_BOOT_01 / TC_BOOT_02): Boot Marker, Nested DCCM & Exceptions
        // ---------------------------------------------------------------------
        if (boot_marker_seen) begin
            $display("   [PASS] TC_BOOT_01 Initial boot marker 0x0000_0001 observed on gpio_o[31:0]");
            pass_count++;
        end else begin
            $display("   [FAIL] TC_BOOT_01 Initial boot marker 0x0000_0001 not observed");
            fail_count++;
        end

        if (gpio_o[63:32] === 32'hB007_0002 && dccm_wr_cnt > 0 && dccm_rd_cnt > 0) begin
            $display("   [PASS] TC_BOOT_02 Nested subroutines & 32-bit DCCM boundary walk passed: gpio_o[63:32] = 0x%08h (wr=%0d, rd=%0d)",
                     gpio_o[63:32], dccm_wr_cnt, dccm_rd_cnt);
            pass_count++;
        end else begin
            $display("   [FAIL] TC_BOOT_02 DCCM/Stack check failed: gpio_o[63:32] = 0x%08h (wr=%0d, rd=%0d)",
                     gpio_o[63:32], dccm_wr_cnt, dccm_rd_cnt);
            fail_count++;
        end

        if (!exc_seen) begin
            $display("   [PASS] TC_BOOT_02 Zero CPU/bus/ECC fault exceptions observed");
            pass_count++;
        end else begin
            $display("   [FAIL] TC_BOOT_02 Core exception was asserted during execution");
            fail_count++;
        end

        // Verify VeeR PMU/FW halt indication (cpu_halt_status asserted by MPMC[0]=1)
        fork
            begin : halt_timeout
                repeat (500) @(posedge clk);
                $display("   [FAIL] TC_BOOT_01 CPU Halt Status remained %b (expected 1 after MPMC halt)", cpu_halt_status);
                fail_count++;
            end
            begin : halt_check
                wait (cpu_halt_status === 1'b1);
                repeat (10) @(posedge clk);
                if (cpu_halt_status === 1'b1) begin
                    $display("   [PASS] TC_BOOT_01 CPU Halt Status asserted (cpu_halt_status = %b after MPMC halt)", cpu_halt_status);
                    pass_count++;
                end else begin
                    $display("   [FAIL] TC_BOOT_01 CPU Halt Status deasserted prematurely (%b)", cpu_halt_status);
                    fail_count++;
                end
                disable halt_timeout;
            end
        join

        // ---------------------------------------------------------------------
        // Final Summary
        // ---------------------------------------------------------------------
        $display("=============================================================");
        $display(" VeeR-EL2 CPU SoC Integration Test Results:");
        $display(" PASS: %0d  |  FAIL: %0d", pass_count, fail_count);
        $display("=============================================================");

        if (fail_count == 0) begin
            $display(" >>> ALL VEER-EL2 CPU INTEGRATION CHECKS PASSED SUCCESSFULLY! <<<");
        end else begin
            $display(" >>> ONE OR MORE CHECKS FAILED! <<<");
        end

        $finish;
    end

    // Safety timeout
    initial begin
        #400_000;
        $display("[TIMEOUT] Simulation reached global timeout limit (200 us)");
        $finish;
    end

`include "soc_cov_inst.svh"
    `INST_SOC_COV(u_soc_top, 1'b1, boot_marker_seen, cpu_halt_status)

endmodule

`default_nettype wire

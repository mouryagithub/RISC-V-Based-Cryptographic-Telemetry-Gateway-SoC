// =============================================================================
// File        : tb_soc_c_test.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : SystemVerilog DPI-C Testbench for soc_top.
//               Executes C firmware verification test suite via DPI-C bridge.
// =============================================================================

`timescale 1ns/10ps
`default_nettype none

module tb_soc_c_test;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam CLK_PERIOD = 20;       // 50 MHz primary clock
    localparam BAUD_DIV   = 16'd434;  // 115200 baud @ 50 MHz

    // =========================================================================
    // Clocks and Reset
    // =========================================================================
    reg clk;
    reg uart_clk;
    reg aresetn;

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial uart_clk = 0;
    always #(CLK_PERIOD/2) uart_clk = ~uart_clk;

    // =========================================================================
    // AXI4 Master 0 Signals (s00 of soc_top)
    // =========================================================================
    reg  [7:0]  m_awid;
    reg  [31:0] m_awaddr;
    reg  [7:0]  m_awlen;
    reg  [2:0]  m_awsize;
    reg  [1:0]  m_awburst;
    reg         m_awlock;
    reg  [3:0]  m_awcache;
    reg  [2:0]  m_awprot;
    reg  [3:0]  m_awqos;
    reg         m_awvalid;
    wire        m_awready;

    reg  [31:0] m_wdata;
    reg  [3:0]  m_wstrb;
    reg         m_wlast;
    reg         m_wvalid;
    wire        m_wready;

    wire [7:0]  m_bid;
    wire [1:0]  m_bresp;
    wire        m_bvalid;
    reg         m_bready;

    reg  [7:0]  m_arid;
    reg  [31:0] m_araddr;
    reg  [7:0]  m_arlen;
    reg  [2:0]  m_arsize;
    reg  [1:0]  m_arburst;
    reg         m_arlock;
    reg  [3:0]  m_arcache;
    reg  [2:0]  m_arprot;
    reg  [3:0]  m_arqos;
    reg         m_arvalid;
    wire        m_arready;

    wire [7:0]  m_rid;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rlast;
    wire        m_rvalid;
    reg         m_rready;

    // UART serial lines
    wire        uart_tx;
    reg         uart_rx;

    // GPIO signals
    reg  [63:0] gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_dir_o;
    wire [1:0]  gpio_intr;

    // Peripheral Interrupt observation lines
    wire        uart_irq;
    wire        timer_irq;
    wire        aes_irq;
    wire        sha_irq;
    wire        dma_done;
    wire        dma_error;

    // =========================================================================
    // DUT: soc_top (Master SoC Top with 2x5 Interconnect)
    // =========================================================================
    soc_top #(
        .USE_INTERNAL_CPU    (0),
        .AXI_DATA_WIDTH      (32),
        .AXI_ADDR_WIDTH      (32),
        .AXI_ID_WIDTH        (8)
    ) u_soc_top (
        .clk                 (clk),
        .uart_clk            (uart_clk),
        .aresetn             (aresetn),

        // External Master 0 (TB master -> s00 of interconnect)
        .ext_s00_axi_awid    (m_awid),
        .ext_s00_axi_awaddr  (m_awaddr),
        .ext_s00_axi_awlen   (m_awlen),
        .ext_s00_axi_awsize  (m_awsize),
        .ext_s00_axi_awburst (m_awburst),
        .ext_s00_axi_awlock  (m_awlock),
        .ext_s00_axi_awcache (m_awcache),
        .ext_s00_axi_awprot  (m_awprot),
        .ext_s00_axi_awqos   (m_awqos),
        .ext_s00_axi_awvalid (m_awvalid),
        .ext_s00_axi_awready (m_awready),
        .ext_s00_axi_wdata   (m_wdata),
        .ext_s00_axi_wstrb   (m_wstrb),
        .ext_s00_axi_wlast   (m_wlast),
        .ext_s00_axi_wvalid  (m_wvalid),
        .ext_s00_axi_wready  (m_wready),
        .ext_s00_axi_bid     (m_bid),
        .ext_s00_axi_bresp   (m_bresp),
        .ext_s00_axi_bvalid  (m_bvalid),
        .ext_s00_axi_bready  (m_bready),
        .ext_s00_axi_arid    (m_arid),
        .ext_s00_axi_araddr  (m_araddr),
        .ext_s00_axi_arlen   (m_arlen),
        .ext_s00_axi_arsize  (m_arsize),
        .ext_s00_axi_arburst (m_arburst),
        .ext_s00_axi_arlock  (m_arlock),
        .ext_s00_axi_arcache (m_arcache),
        .ext_s00_axi_arprot  (m_arprot),
        .ext_s00_axi_arqos   (m_arqos),
        .ext_s00_axi_arvalid (m_arvalid),
        .ext_s00_axi_arready (m_arready),
        .ext_s00_axi_rid     (m_rid),
        .ext_s00_axi_rdata   (m_rdata),
        .ext_s00_axi_rresp   (m_rresp),
        .ext_s00_axi_rlast   (m_rlast),
        .ext_s00_axi_rvalid  (m_rvalid),
        .ext_s00_axi_rready  (m_rready),

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
        .cpu_halt_status_o   ()
    );

    // =========================================================================
    // DPI-C Exported Tasks (Callable from C Test Suite)
    // =========================================================================
    export "DPI-C" task sv_axi_write;
    export "DPI-C" task sv_axi_read;
    export "DPI-C" task sv_delay_cycles;
    export "DPI-C" task sv_uart_send_byte;
    export "DPI-C" task sv_uart_recv_byte;
    export "DPI-C" task sv_uart_tx_loopback;
    export "DPI-C" task sv_uart_b2b_tx;
    export "DPI-C" task sv_set_gpio_in;
    export "DPI-C" task sv_get_gpio_out;
    export "DPI-C" task sv_get_irqs;

    // DPI-C Imported C Test Suite Entry Point
    import "DPI-C" context task soc_c_main(output int status);

    // AXI single-beat 32-bit write
    task sv_axi_write(input int unsigned addr, input int unsigned data);
        reg aw_done;
        reg w_done;
        begin
            @(posedge clk);
            m_awid    <= 8'h01;
            m_awaddr  <= addr;
            m_awlen   <= 8'h00;
            m_awsize  <= 3'b010;
            m_awburst <= 2'b01;
            m_awlock  <= 1'b0;
            m_awcache <= 4'b0010;
            m_awprot  <= 3'b000;
            m_awqos   <= 4'h0;
            m_awvalid <= 1'b1;
            m_wdata   <= data;
            m_wstrb   <= 4'hF;
            m_wlast   <= 1'b1;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;
            aw_done    = 1'b0;
            w_done     = 1'b0;

            while (!aw_done || !w_done) begin
                @(posedge clk);
                if (m_awvalid && m_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done = 1'b1;
                end
                if (m_wvalid && m_wready) begin
                    m_wvalid <= 1'b0;
                    m_wlast  <= 1'b0;
                    w_done = 1'b1;
                end
            end

            while (!m_bvalid) begin
                @(posedge clk);
            end
            m_bready <= 1'b0;
            @(posedge clk);
        end
    endtask

    // AXI single-beat 32-bit read
    task sv_axi_read(input int unsigned addr, output int unsigned data);
        reg ar_done;
        begin
            @(posedge clk);
            m_arid    <= 8'h01;
            m_araddr  <= addr;
            m_arlen   <= 8'h00;
            m_arsize  <= 3'b010;
            m_arburst <= 2'b01;
            m_arlock  <= 1'b0;
            m_arcache <= 4'b0010;
            m_arprot  <= 3'b000;
            m_arqos   <= 4'h0;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;
            ar_done    = 1'b0;

            while (!ar_done) begin
                @(posedge clk);
                if (m_arvalid && m_arready) begin
                    m_arvalid <= 1'b0;
                    ar_done = 1'b1;
                end
            end

            while (!m_rvalid) begin
                @(posedge clk);
            end
            data = m_rdata;
            m_rready <= 1'b0;
            @(posedge clk);
        end
    endtask

    // Delay helper
    task sv_delay_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    // Bit-bang transmit one byte to UART RX
    task sv_uart_send_byte(input byte unsigned byte_val);
        integer baud_clks, b;
        begin
            baud_clks = BAUD_DIV;
            uart_rx = 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx = byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_rx = 1'b1; // stop bit
            repeat (baud_clks) @(posedge uart_clk);
        end
    endtask

    // Synchronously receive one byte from UART TX
    task sv_uart_recv_byte(output byte unsigned rx_byte);
        integer half_baud, baud_clks, b;
        begin
            half_baud = BAUD_DIV / 2;
            baud_clks = BAUD_DIV;
            rx_byte   = 8'h00;

            @(posedge uart_clk);
            while (uart_tx !== 1'b1) @(posedge uart_clk);
            while (uart_tx !== 1'b0) @(posedge uart_clk);

            repeat (half_baud + baud_clks) @(posedge uart_clk);

            for (b = 0; b < 8; b = b + 1) begin
                rx_byte[b] = uart_tx;
                repeat (baud_clks) @(posedge uart_clk);
            end

            repeat (10) @(posedge uart_clk);
        end
    endtask

    // Concurrent TX loopback task: forks AXI THR write with UART receiver
    task sv_uart_tx_loopback(input byte unsigned tx_val, output byte unsigned rx_cap);
        fork
            begin
                sv_axi_write(32'h4000_1000, {24'h0, tx_val});
            end
            begin
                sv_uart_recv_byte(rx_cap);
            end
        join
    endtask

    // Concurrent back-to-back TX task
    task sv_uart_b2b_tx(input byte unsigned b0, input byte unsigned b1, input byte unsigned b2,
                        output byte unsigned r0, output byte unsigned r1, output byte unsigned r2);
        fork
            begin
                sv_axi_write(32'h4000_1000, {24'h0, b0});
                sv_axi_write(32'h4000_1000, {24'h0, b1});
                sv_axi_write(32'h4000_1000, {24'h0, b2});
            end
            begin
                sv_uart_recv_byte(r0);
                sv_uart_recv_byte(r1);
                sv_uart_recv_byte(r2);
            end
        join
    endtask

    // GPIO drive / sample helpers
    task sv_set_gpio_in(input int unsigned in_val_low, input int unsigned in_val_high);
        begin
            gpio_i = {in_val_high, in_val_low};
        end
    endtask

    task sv_get_gpio_out(output int unsigned out_val_low, output int unsigned out_val_high);
        begin
            out_val_low  = gpio_o[31:0];
            out_val_high = gpio_o[63:32];
        end
    endtask

    // Interrupt line status helper
    task sv_get_irqs(output int unsigned uart_irq_val, output int unsigned timer_irq_val,
                     output int unsigned aes_irq_val, output int unsigned sha_irq_val,
                     output int unsigned dma_done_val, output int unsigned dma_error_val);
        begin
            uart_irq_val  = uart_irq;
            timer_irq_val = timer_irq;
            aes_irq_val   = aes_irq;
            sha_irq_val   = sha_irq;
            dma_done_val  = dma_done;
            dma_error_val = dma_error;
        end
    endtask

    // =========================================================================
    // Waveform Dumping (VCD & FSDB / VPD support)
    // =========================================================================
    string vcd_path;
    string fsdb_path;
    string vpd_path;

    initial begin
        // Standard VCD dumping (always active by default, works with GTKWave/Verdi/DVE)
        if (!$value$plusargs("VCD_FILE=%s", vcd_path)) begin
            vcd_path = "dump.vcd";
        end
        $dumpfile(vcd_path);
        $dumpvars(0, tb_soc_c_test);
        $display("[TB] >>> Waveform dumping enabled (VCD): %s <<<", vcd_path);

`ifdef FSDB
        // Verdi FSDB dumping (standard dump.fsdb for Verdi -ssf)
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_path)) begin
            fsdb_path = "dump.fsdb";
        end
        $fsdbDumpfile(fsdb_path);
        $fsdbDumpvars(0, tb_soc_c_test, "+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
        $display("[TB] >>> Verdi FSDB dumping enabled: %s <<<", fsdb_path);
`endif

`ifdef VPD
        // Synopsys VPD dumping
        if (!$value$plusargs("VPD_FILE=%s", vpd_path)) begin
            vpd_path = "dump.vpd";
        end
        $vcdplusfile(vpd_path);
        $vcdpluson(0, tb_soc_c_test);
        $display("[TB] >>> Synopsys VPD dumping enabled: %s <<<", vpd_path);
`endif
    end

    // =========================================================================
    // Test Control Execution
    // =========================================================================
    int test_status;

    initial begin
        // Initialize AXI master outputs to idle
        m_awid    = 8'h0;   m_awaddr  = 32'h0;  m_awlen   = 8'h0;
        m_awsize  = 3'h0;   m_awburst = 2'h0;   m_awlock  = 1'b0;
        m_awcache = 4'h0;   m_awprot  = 3'h0;   m_awqos   = 4'h0;
        m_awvalid = 1'b0;
        m_wdata   = 32'h0;  m_wstrb   = 4'h0;   m_wlast   = 1'b0;
        m_wvalid  = 1'b0;   m_bready  = 1'b0;
        m_arid    = 8'h0;   m_araddr  = 32'h0;  m_arlen   = 8'h0;
        m_arsize  = 3'h0;   m_arburst = 2'h0;   m_arlock  = 1'b0;
        m_arcache = 4'h0;   m_arprot  = 3'h0;   m_arqos   = 4'h0;
        m_arvalid = 1'b0;   m_rready  = 1'b0;
        uart_rx   = 1'b1;   // UART idle is HIGH
        gpio_i    = 64'h0;

        // Reset sequence
        aresetn = 1'b0;
        repeat (10) @(posedge clk);
        aresetn = 1'b1;
        repeat (5)  @(posedge clk);

        $display("=============================================================");
        $display("  SystemVerilog DPI-C Testbench Initiated for soc_top");
        $display("  Calling C firmware test main function...");
        $display("=============================================================");

        // Hand over control to the C test suite
        soc_c_main(test_status);

        $display("=============================================================");
        $display("  C Test Suite Completed. Status Exit Code: %0d", test_status);
        if (test_status == 0)
            $display("  >>> ALL C TESTS PASSED SUCCESSFULLY! <<<");
        else
            $display("  >>> C TESTS FAILED WITH %0d ERRORS! <<<", test_status);
        $display("=============================================================");

        repeat (10) @(posedge clk);
        $dumpflush;
`ifdef FSDB
        $fsdbDumpflush;
`endif
`ifdef VPD
        $vcdplusflush;
`endif
        $display("[TB] >>> Simulation finished. Waveforms saved successfully. <<<");
        $finish;
    end

    // Watchdog timeout
    initial begin
        #100_000_000;
        $display("[TIMEOUT] Simulation time limit exceeded.");
        $finish;
    end

endmodule

`default_nettype wire

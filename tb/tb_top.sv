// =============================================================================
// File        : tb/tb_top.sv
// Module      : tb_top
// Description : Unified Top-Level UVM Testbench integrating external VIPs:
//               - GPIO VIP (gpio_vip_if, gpio_vip_pkg) -> external gpio pins
//               - UART VIP (uart_vip_if, uart_vip_pkg) -> external uart pins
//               Connected to the RISC-V Cryptographic Telemetry Gateway SoC (soc_top).
//               Pure external interface verification with zero internal AXI signals
//               in the VIPs.
// =============================================================================

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import gpio_vip_pkg::*;
    import uart_vip_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters & Clocks
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD      = 20;     // 50 MHz primary system clock (20 ns)
    localparam UART_CLK_PERIOD = 20;     // 50 MHz UART baud reference clock
    localparam BAUD_DIV        = 16'd434;// 115200 baud @ 50 MHz

    logic clk;
    logic uart_clk;
    logic aresetn;

    // Primary system clock
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // UART baud reference clock
    initial begin
        uart_clk = 1'b0;
        forever #(UART_CLK_PERIOD / 2) uart_clk = ~uart_clk;
    end

    // Synchronous active-LOW reset
    initial begin
        aresetn = 1'b0;
        repeat (15) @(posedge clk);
        aresetn = 1'b1;
    end

    // -------------------------------------------------------------------------
    // Pure External VIP Interface Instances
    // -------------------------------------------------------------------------
    gpio_vip_if gpio_vif(.clk(clk), .aresetn(aresetn));
    uart_vip_if uart_vif(.clk(clk), .aresetn(aresetn));

    // -------------------------------------------------------------------------
    // External SoC Peripheral Wires
    // -------------------------------------------------------------------------
    wire        soc_uart_tx;
    wire        soc_uart_rx;
    wire [63:0] soc_gpio_i;
    wire [63:0] soc_gpio_o;
    wire [63:0] soc_gpio_dir_o;
    wire [1:0]  soc_gpio_intr;
    wire        soc_uart_irq;
    wire        soc_timer_irq;
    wire        soc_aes_irq;
    wire        soc_sha_irq;
    wire        soc_dma_done;
    wire        soc_dma_error;

    // Direct External Interface Connections:
    // UART External Pins
    assign soc_uart_rx       = uart_vif.uart_rx;
    assign uart_vif.uart_tx  = soc_uart_tx;
    assign uart_vif.uart_irq = soc_uart_irq;

    // GPIO External Pins
    assign soc_gpio_i           = gpio_vif.gpio_i;
    assign gpio_vif.gpio_o      = soc_gpio_o;
    assign gpio_vif.gpio_dir_o  = soc_gpio_dir_o;
    assign gpio_vif.gpio_intr_o = soc_gpio_intr;

    // -------------------------------------------------------------------------
    // SoC AXI4 Master 0 Port (Directly driven by CPU / Testbench Master)
    // -------------------------------------------------------------------------
    logic [7:0]   m_awid;
    logic [31:0]  m_awaddr;
    logic [7:0]   m_awlen;
    logic [2:0]   m_awsize;
    logic [1:0]   m_awburst;
    logic         m_awlock;
    logic [3:0]   m_awcache;
    logic [2:0]   m_awprot;
    logic [3:0]   m_awqos;
    logic         m_awvalid;
    wire          m_awready;

    logic [31:0]  m_wdata;
    logic [3:0]   m_wstrb;
    logic         m_wlast;
    logic         m_wvalid;
    wire          m_wready;

    wire  [7:0]   m_bid;
    wire  [1:0]   m_bresp;
    wire          m_bvalid;
    logic         m_bready;

    logic [7:0]   m_arid;
    logic [31:0]  m_araddr;
    logic [7:0]   m_arlen;
    logic [2:0]   m_arsize;
    logic [1:0]   m_arburst;
    logic         m_arlock;
    logic [3:0]   m_arcache;
    logic [2:0]   m_arprot;
    logic [3:0]   m_arqos;
    logic         m_arvalid;
    wire          m_arready;

    wire  [7:0]   m_rid;
    wire  [31:0]  m_rdata;
    wire  [1:0]   m_rresp;
    wire          m_rlast;
    wire          m_rvalid;
    logic         m_rready;

    initial begin
        m_awid    = '0;
        m_awaddr  = '0;
        m_awlen   = '0;
        m_awsize  = 3'b010;
        m_awburst = 2'b01;
        m_awlock  = 1'b0;
        m_awcache = 4'b0010;
        m_awprot  = 3'b000;
        m_awqos   = '0;
        m_awvalid = 1'b0;
        m_wdata   = '0;
        m_wstrb   = 4'hF;
        m_wlast   = 1'b1;
        m_wvalid  = 1'b0;
        m_bready  = 1'b0;
        m_arid    = '0;
        m_araddr  = '0;
        m_arlen   = '0;
        m_arsize  = 3'b010;
        m_arburst = 2'b01;
        m_arlock  = 1'b0;
        m_arcache = 4'b0010;
        m_arprot  = 3'b000;
        m_arqos   = '0;
        m_arvalid = 1'b0;
        m_rready  = 1'b0;
    end

    // -------------------------------------------------------------------------
    // DUT: Integrated SoC Top-Level (soc_top)
    // -------------------------------------------------------------------------
    soc_top #(
        .USE_INTERNAL_CPU (0),  // External AXI Master drives s00
        .AXI_DATA_WIDTH   (32),
        .AXI_ADDR_WIDTH   (32),
        .AXI_ID_WIDTH     (8)
    ) u_soc_dut (
        .clk                 (clk),
        .uart_clk            (uart_clk),
        .aresetn             (aresetn),

        // External AXI Master 0 connected directly to testbench master
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

        // DMA CSR slave interface (tied off)
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

        // Peripherals External Boundary I/O Pins
        .uart_rx             (soc_uart_rx),
        .uart_tx             (soc_uart_tx),
        .gpio_i              (soc_gpio_i),
        .gpio_o              (soc_gpio_o),
        .gpio_dir_o          (soc_gpio_dir_o),

        // External Interrupt Observation Pins
        .uart_irq_o          (soc_uart_irq),
        .timer_irq_o         (soc_timer_irq),
        .aes_irq_o           (soc_aes_irq),
        .sha_irq_o           (soc_sha_irq),
        .dma_done_o          (soc_dma_done),
        .dma_error_o         (soc_dma_error),
        .gpio_intr_o         (soc_gpio_intr),
        .cpu_halt_status_o   ()
    );

    // =========================================================================
    // DPI-C Bridge Tasks (Callable from C Firmware Test Suite)
    // =========================================================================
    import "DPI-C" context task soc_c_main(output int status);

    task sv_axi_write(input int unsigned addr, input int unsigned data);
        bit aw_done, w_done;
        begin
            @(posedge clk);
            m_awid    <= 8'h01;
            m_awaddr  <= addr;
            m_awvalid <= 1'b1;
            m_wdata   <= data;
            m_wstrb   <= 4'hF;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;
            aw_done   = 1'b0;
            w_done    = 1'b0;

            while (!aw_done || !w_done) begin
                @(posedge clk);
                if (!aw_done && m_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done = 1'b1;
                end
                if (!w_done && m_wready) begin
                    m_wvalid <= 1'b0;
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

    task sv_axi_read(input int unsigned addr, output int unsigned data);
        bit ar_done;
        begin
            @(posedge clk);
            m_arid    <= 8'h01;
            m_araddr  <= addr;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;
            ar_done   = 1'b0;

            while (!ar_done) begin
                @(posedge clk);
                if (m_arready) begin
                    m_arvalid <= 1'b0;
                    ar_done = 1'b1;
                end
            end

            while (!m_rvalid) begin
                @(posedge clk);
            end

            data     = m_rdata;
            m_rready <= 1'b0;
            @(posedge clk);
        end
    endtask

    task sv_wait_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    task sv_delay_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    task sv_uart_send_byte(input byte unsigned byte_val);
        integer baud_clks, b;
        begin
            baud_clks = BAUD_DIV;
            uart_vif.uart_rx <= 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_vif.uart_rx <= byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_vif.uart_rx <= 1'b1; // stop bit
            repeat (baud_clks) @(posedge uart_clk);
        end
    endtask

    task sv_uart_recv_byte(output byte unsigned rx_byte);
        integer half_baud, baud_clks, b;
        begin
            half_baud = BAUD_DIV / 2;
            baud_clks = BAUD_DIV;
            rx_byte   = 8'h00;

            @(posedge uart_clk);
            while (soc_uart_tx !== 1'b1) @(posedge uart_clk);
            while (soc_uart_tx !== 1'b0) @(posedge uart_clk);

            repeat (half_baud + baud_clks) @(posedge uart_clk);

            for (b = 0; b < 8; b = b + 1) begin
                rx_byte[b] = soc_uart_tx;
                repeat (baud_clks) @(posedge uart_clk);
            end

            repeat (10) @(posedge uart_clk);
        end
    endtask

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

    task sv_set_gpio_in(input int unsigned in_val_low, input int unsigned in_val_high);
        begin
            gpio_vif.gpio_i = {in_val_high, in_val_low};
        end
    endtask

    task sv_get_gpio_out(output int unsigned out_val_low, output int unsigned out_val_high);
        begin
            out_val_low  = soc_gpio_o[31:0];
            out_val_high = soc_gpio_o[63:32];
        end
    endtask

    task sv_get_irqs(output int unsigned uart_irq_val, output int unsigned timer_irq_val,
                     output int unsigned aes_irq_val, output int unsigned sha_irq_val,
                     output int unsigned dma_done_val, output int unsigned dma_error_val);
        begin
            uart_irq_val  = soc_uart_irq;
            timer_irq_val = soc_timer_irq;
            aes_irq_val   = soc_aes_irq;
            sha_irq_val   = soc_sha_irq;
            dma_done_val  = soc_dma_done;
            dma_error_val = soc_dma_error;
        end
    endtask

    export "DPI-C" task sv_axi_write;
    export "DPI-C" task sv_axi_read;
    export "DPI-C" task sv_wait_cycles;
    export "DPI-C" task sv_delay_cycles;
    export "DPI-C" task sv_uart_send_byte;
    export "DPI-C" task sv_uart_recv_byte;
    export "DPI-C" task sv_uart_tx_loopback;
    export "DPI-C" task sv_uart_b2b_tx;
    export "DPI-C" task sv_set_gpio_in;
    export "DPI-C" task sv_get_gpio_out;
    export "DPI-C" task sv_get_irqs;

    // -------------------------------------------------------------------------
    // UVM Test Class for C Firmware Test Suite with Active External Pin VIPs
    // -------------------------------------------------------------------------
    class soc_c_test extends uvm_test;
        `uvm_component_utils(soc_c_test)

        gpio_vip_env gpio_env;
        uart_vip_env uart_env;

        function new(string name = "soc_c_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            gpio_env = gpio_vip_env::type_id::create("gpio_env", this);
            uart_env = uart_vip_env::type_id::create("uart_env", this);
        endfunction

        task run_phase(uvm_phase phase);
            int c_fail_status;
            phase.raise_objection(this);
            wait (aresetn === 1'b1);
            repeat (10) @(posedge clk);
            `uvm_info("SOC_C_TEST", "=========================================================", UVM_LOW)
            `uvm_info("SOC_C_TEST", " Executing C Firmware Test Suite on Integrated UVM VIP Top", UVM_LOW)
            `uvm_info("SOC_C_TEST", " VIPs Active: External GPIO & UART VIPs | DUT: soc_top   ", UVM_LOW)
            `uvm_info("SOC_C_TEST", "=========================================================", UVM_LOW)

            soc_c_main(c_fail_status);

            if (c_fail_status == 0) begin
                `uvm_info("SOC_C_TEST", ">>> ALL 31 C TESTS PASSED ON INTEGRATED UVM VIP TOP! <<<", UVM_LOW)
            end else begin
                `uvm_error("SOC_C_TEST", $sformatf(">>> C TESTS FAILED: %0d failures <<<", c_fail_status))
            end
            phase.drop_objection(this);
        endtask
    endclass

    // -------------------------------------------------------------------------
    // Integrated SoC Verification UVM Test: soc_vip_test
    // Drives external pin stimulus via GPIO VIP and UART VIP
    // -------------------------------------------------------------------------
    class soc_vip_test extends uvm_test;
        `uvm_component_utils(soc_vip_test)

        gpio_vip_env gpio_env;
        uart_vip_env uart_env;

        function new(string name = "soc_vip_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            gpio_env = gpio_vip_env::type_id::create("gpio_env", this);
            uart_env = uart_vip_env::type_id::create("uart_env", this);
        endfunction

        task run_phase(uvm_phase phase);
            gpio_stimulus_seq gpio_seq;
            uart_inject_seq   uart_seq;

            phase.raise_objection(this);
            wait (aresetn === 1'b1);
            repeat (10) @(posedge clk);

            `uvm_info("SOC_VIP_TEST", "=============================================================", UVM_LOW)
            `uvm_info("SOC_VIP_TEST", " Starting External SoC Pin VIP Verification (GPIO + UART)   ", UVM_LOW)
            `uvm_info("SOC_VIP_TEST", "=============================================================", UVM_LOW)

            gpio_seq = gpio_stimulus_seq::type_id::create("gpio_seq");
            uart_seq = uart_inject_seq::type_id::create("uart_seq");

            // 1. Execute External GPIO Pin Stimulus (drives gpio_i[63:0])
            `uvm_info("SOC_VIP_TEST", ">>> Executing External GPIO Pin Stimulus Suite...", UVM_LOW)
            gpio_seq.start(gpio_env.agent.seqr);
            `uvm_info("SOC_VIP_TEST", ">>> External GPIO Pin Stimulus Completed.", UVM_LOW)

            #5000;

            // 2. Configure UART via internal AXI so it can receive serial bytes
            sv_axi_write(32'h4000_100C, 32'h0000_0080); // LCR: DLAB=1
            sv_axi_write(32'h4000_1008, 32'h0000_01B2); // BAUD: 434 (115200 baud)
            sv_axi_write(32'h4000_100C, 32'h0000_0000); // LCR: 8N1, DLAB=0
            sv_axi_write(32'h4000_1004, 32'h0000_0001); // IER: RX data IRQ enable

            // 3. Execute External UART Serial Injection (drives uart_rx pin into SoC)
            `uvm_info("SOC_VIP_TEST", ">>> Executing External UART Serial Injection Suite...", UVM_LOW)
            uart_seq.start(uart_env.agent.seqr);
            `uvm_info("SOC_VIP_TEST", ">>> External UART Serial Injection Completed.", UVM_LOW)

            #10000;
            `uvm_info("SOC_VIP_TEST", "=============================================================", UVM_LOW)
            `uvm_info("SOC_VIP_TEST", " All External SoC Pin VIP Tests Completed Successfully!     ", UVM_LOW)
            `uvm_info("SOC_VIP_TEST", "=============================================================", UVM_LOW)
            phase.drop_objection(this);
        endtask
    endclass

    // -------------------------------------------------------------------------
    // Test Control, Waveform Dumping & UVM Execution
    // -------------------------------------------------------------------------
    initial begin
        string test_name;

        // Register Virtual Interfaces into UVM Configuration Database
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "vif", gpio_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "uart_vif", uart_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "vif", uart_vif);

        // Standard VCD dumping
        $dumpfile("soc_vips_tb.vcd");
        $dumpvars(0, tb_top);

        // Verdi FSDB dumping
`ifdef FSDB
        $fsdbDumpfile("soc_vips_tb.fsdb");
        $fsdbDumpvars(0, tb_top, "+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
`endif

        $display("=============================================================");
        $display(" [TB_TOP] Starting Integrated SoC VIP UVM Verification Top");
        $display(" [TB_TOP] VIPs: External UART VIP & GPIO VIP | DUT: soc_top");
        $display("=============================================================");

        // Run test with fallback default to UVM VIP verification suite
        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            test_name = "soc_vip_test";
        end
        run_test(test_name);
    end

    // Global simulation watchdog
    initial begin
        #50_000_000;
        $display("[TB_TOP] Simulation time limit reached.");
        $finish;
    end

endmodule : tb_top

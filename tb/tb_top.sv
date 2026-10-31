// =============================================================================
// File        : tb/tb_top.sv
// Module      : tb_top
// Description : Unified Top-Level UVM Testbench integrating both VIPs:
//               - GPIO VIP (gpio_vip_if, gpio_vip_pkg)
//               - UART VIP (uart_vip_if, uart_vip_pkg)
//               Connected to the RISC-V Cryptographic Telemetry Gateway SoC (soc_top).
//               Supports UVM VIP tests (gpio_vip_test, uart_vip_test) AND
//               DPI-C C firmware test suite (soc_c_test).
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
    // VIP Interface Instances
    // -------------------------------------------------------------------------
    gpio_vip_if gpio_vif();
    uart_vip_if uart_vif();

    // Assign Clock & Reset to GPIO VIP interface
    assign gpio_vif.clk     = clk;
    assign gpio_vif.aclk    = clk;
    assign gpio_vif.aresetn = aresetn;

    // Assign Clocks & Reset to UART VIP interface
    assign uart_vif.clk           = clk;
    assign uart_vif.axi_aclk_i    = clk;
    assign uart_vif.fixed_clk_i   = uart_clk;
    assign uart_vif.axi_aresetn_i = aresetn;

    // -------------------------------------------------------------------------
    // Signals & Multiplexing between VIPs, DPI-C C Tests, and SoC Top
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

    logic        uart_tb_rx_override = 1'b0;
    logic        uart_tb_rx_val = 1'b1;
    assign soc_uart_rx          = uart_tb_rx_override ? uart_tb_rx_val : uart_vif.uart_rx_i;
    assign uart_vif.uart_tx_o   = soc_uart_tx;
    assign uart_vif.read_interrupt_o = soc_uart_irq;

    logic [63:0] gpio_tb_in = 64'h0;
    logic        gpio_tb_in_override = 1'b0;
    assign soc_gpio_i           = gpio_tb_in_override ? gpio_tb_in : gpio_vif.gpio_i;
    assign gpio_vif.gpio_o      = soc_gpio_o;
    assign gpio_vif.gpio_dir_o  = soc_gpio_dir_o;
    assign gpio_vif.gpio_intr_o = soc_gpio_intr;

    // AXI Master Signals (driven by tb_top DPI-C / C test suite)
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

        uart_vif.uart_rx_i       = 1'b1;
        uart_vif.axi_arid_i      = '0;
        uart_vif.axi_araddr_i    = '0;
        uart_vif.axi_arvalid_i   = 1'b0;
        uart_vif.axi_rready_i    = 1'b0;
        uart_vif.axi_awid_i      = '0;
        uart_vif.axi_awaddr_i    = '0;
        uart_vif.axi_awvalid_i   = 1'b0;
        uart_vif.axi_wdata_i     = '0;
        uart_vif.axi_wstrb_i     = '0;
        uart_vif.axi_wvalid_i    = 1'b0;
        uart_vif.axi_bready_i    = 1'b0;

        gpio_vif.gpio_i          = '0;
        gpio_vif.s_axi_awaddr    = '0;
        gpio_vif.s_axi_awprot    = '0;
        gpio_vif.s_axi_awvalid   = 1'b0;
        gpio_vif.s_axi_wdata     = '0;
        gpio_vif.s_axi_wstrb     = '0;
        gpio_vif.s_axi_wvalid    = 1'b0;
        gpio_vif.s_axi_bready    = 1'b0;
        gpio_vif.s_axi_araddr    = '0;
        gpio_vif.s_axi_arprot    = '0;
        gpio_vif.s_axi_arvalid   = 1'b0;
        gpio_vif.s_axi_rready    = 1'b0;
    end

    // Interconnect between AXI Master, UART VIP AXI, and soc_top
    wire axi_sel_uart_wr = (uart_vif.axi_awvalid_i === 1'b1);
    wire axi_sel_uart_rd = (uart_vif.axi_arvalid_i === 1'b1);

    wire [7:0]  dut_awid    = axi_sel_uart_wr ? {4'h0, uart_vif.axi_awid_i} : m_awid;
    wire [31:0] dut_awaddr  = axi_sel_uart_wr ? {24'h4000_10, uart_vif.axi_awaddr_i} : m_awaddr;
    wire        dut_awvalid = axi_sel_uart_wr ? uart_vif.axi_awvalid_i : m_awvalid;
    wire        dut_awready;
    assign uart_vif.axi_awready_o = axi_sel_uart_wr ? dut_awready : 1'b0;
    assign m_awready              = !axi_sel_uart_wr ? dut_awready : 1'b0;

    wire [31:0] dut_wdata   = axi_sel_uart_wr ? uart_vif.axi_wdata_i : m_wdata;
    wire [3:0]  dut_wstrb   = axi_sel_uart_wr ? uart_vif.axi_wstrb_i : m_wstrb;
    wire        dut_wvalid  = axi_sel_uart_wr ? uart_vif.axi_wvalid_i : m_wvalid;
    wire        dut_wready;
    assign uart_vif.axi_wready_o  = axi_sel_uart_wr ? dut_wready : 1'b0;
    assign m_wready               = !axi_sel_uart_wr ? dut_wready : 1'b0;

    wire [7:0]  dut_bid;
    wire [1:0]  dut_bresp;
    wire        dut_bvalid;
    wire        dut_bready  = axi_sel_uart_wr ? uart_vif.axi_bready_i : m_bready;
    assign uart_vif.axi_bid_o   = dut_bid[3:0];
    assign uart_vif.axi_bresp_o = dut_bresp;
    assign uart_vif.axi_bvalid_o= dut_bvalid;
    assign m_bid                = dut_bid;
    assign m_bresp              = dut_bresp;
    assign m_bvalid             = dut_bvalid;

    wire [7:0]  dut_arid    = axi_sel_uart_rd ? {4'h0, uart_vif.axi_arid_i} : m_arid;
    wire [31:0] dut_araddr  = axi_sel_uart_rd ? {24'h4000_10, uart_vif.axi_araddr_i} : m_araddr;
    wire        dut_arvalid = axi_sel_uart_rd ? uart_vif.axi_arvalid_i : m_arvalid;
    wire        dut_arready;
    assign uart_vif.axi_arready_o = axi_sel_uart_rd ? dut_arready : 1'b0;
    assign m_arready              = !axi_sel_uart_rd ? dut_arready : 1'b0;

    wire [7:0]  dut_rid;
    wire [31:0] dut_rdata;
    wire [1:0]  dut_rresp;
    wire        dut_rlast;
    wire        dut_rvalid;
    wire        dut_rready  = axi_sel_uart_rd ? uart_vif.axi_rready_i : m_rready;
    assign uart_vif.axi_rid_o   = dut_rid[3:0];
    assign uart_vif.axi_rdata_o = dut_rdata;
    assign uart_vif.axi_rresp_o = dut_rresp;
    assign uart_vif.axi_rvalid_o= dut_rvalid;
    assign m_rid                = dut_rid;
    assign m_rdata              = dut_rdata;
    assign m_rresp              = dut_rresp;
    assign m_rlast              = dut_rlast;
    assign m_rvalid             = dut_rvalid;

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

        // External AXI Master 0
        .ext_s00_axi_awid    (dut_awid),
        .ext_s00_axi_awaddr  (dut_awaddr),
        .ext_s00_axi_awlen   (8'h00),
        .ext_s00_axi_awsize  (3'b010),
        .ext_s00_axi_awburst (2'b01),
        .ext_s00_axi_awlock  (1'b0),
        .ext_s00_axi_awcache (4'b0010),
        .ext_s00_axi_awprot  (3'b000),
        .ext_s00_axi_awqos   (4'h0),
        .ext_s00_axi_awvalid (dut_awvalid),
        .ext_s00_axi_awready (dut_awready),

        .ext_s00_axi_wdata   (dut_wdata),
        .ext_s00_axi_wstrb   (dut_wstrb),
        .ext_s00_axi_wlast   (1'b1),
        .ext_s00_axi_wvalid  (dut_wvalid),
        .ext_s00_axi_wready  (dut_wready),

        .ext_s00_axi_bid     (dut_bid),
        .ext_s00_axi_bresp   (dut_bresp),
        .ext_s00_axi_bvalid  (dut_bvalid),
        .ext_s00_axi_bready  (dut_bready),

        .ext_s00_axi_arid    (dut_arid),
        .ext_s00_axi_araddr  (dut_araddr),
        .ext_s00_axi_arlen   (8'h00),
        .ext_s00_axi_arsize  (3'b010),
        .ext_s00_axi_arburst (2'b01),
        .ext_s00_axi_arlock  (1'b0),
        .ext_s00_axi_arcache (4'b0010),
        .ext_s00_axi_arprot  (3'b000),
        .ext_s00_axi_arqos   (4'h0),
        .ext_s00_axi_arvalid (dut_arvalid),
        .ext_s00_axi_arready (dut_arready),

        .ext_s00_axi_rid     (dut_rid),
        .ext_s00_axi_rdata   (dut_rdata),
        .ext_s00_axi_rresp   (dut_rresp),
        .ext_s00_axi_rlast   (dut_rlast),
        .ext_s00_axi_rvalid  (dut_rvalid),
        .ext_s00_axi_rready  (dut_rready),

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

        // Peripherals External I/O
        .uart_rx             (soc_uart_rx),
        .uart_tx             (soc_uart_tx),
        .gpio_i              (soc_gpio_i),
        .gpio_o              (soc_gpio_o),
        .gpio_dir_o          (soc_gpio_dir_o),

        // Interrupts
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
    // DPI-C Bridge Tasks (Callable from C Test Suite)
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
                if (m_awvalid && dut_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done = 1'b1;
                end
                if (m_wvalid && dut_wready) begin
                    m_wvalid <= 1'b0;
                    m_wlast  <= 1'b0;
                    w_done = 1'b1;
                end
            end

            while (!dut_bvalid) begin
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
                if (m_arvalid && dut_arready) begin
                    m_arvalid <= 1'b0;
                    ar_done = 1'b1;
                end
            end

            while (!dut_rvalid) begin
                @(posedge clk);
            end
            data = dut_rdata;
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
            uart_tb_rx_override = 1'b1;
            uart_tb_rx_val = 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_tb_rx_val = byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_tb_rx_val = 1'b1; // stop bit
            repeat (baud_clks) @(posedge uart_clk);
            uart_tb_rx_override = 1'b0;
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
            gpio_tb_in = {in_val_high, in_val_low};
            gpio_tb_in_override = 1'b1;
            gpio_vif.gpio_i = gpio_tb_in;
        end
    endtask

    task sv_get_gpio_out(output int unsigned out_val_low, output int unsigned out_val_high);
        begin
            out_val_low  = soc_gpio_o[31:0];
            out_val_high = soc_gpio_o[63:32];
        end
    endtask

    // Interrupt line status helper
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

    // -------------------------------------------------------------------------
    // UVM Test Class for C Firmware Test Suite
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
            `uvm_info("SOC_C_TEST", " VIPs Active: GPIO VIP & UART VIP | DUT: soc_top", UVM_LOW)
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
        $display(" [TB_TOP] VIPs: UART VIP & GPIO VIP | DUT: soc_top");
        $display("=============================================================");

        // Run test with fallback default
        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            test_name = "soc_c_test";
        end
        run_test(test_name);
    end

    // Global simulation watchdog
    initial begin
        #50_000_000;
        $display("[TB_TOP] Simulation time limit reached.");
        $finish;
    end

endmodule

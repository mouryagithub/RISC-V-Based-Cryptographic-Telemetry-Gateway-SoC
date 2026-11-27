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
    import timer_vip_pkg::*;
    import sha_vip_pkg::*;
    import aes_vip_pkg::*;
    import dma_vip_pkg::*;

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
    // VIP Interface Instances (External Pins + Passive Peripheral Probes + Bus)
    // -------------------------------------------------------------------------
    soc_axi_if   bus_vif(.clk(clk), .aresetn(aresetn));
    gpio_vip_if  gpio_vif(.clk(clk), .aresetn(aresetn));
    uart_vip_if  uart_vif(.clk(clk), .aresetn(aresetn));
    timer_vip_if timer_vif(.aclk(clk), .aresetn(aresetn));
    sha_vip_if   sha_vif(.aclk(clk), .aresetn(aresetn));
    aes_vip_if   aes_vif(.aclk(clk), .aresetn(aresetn));
    dma_vip_if   dma_vif(.clk(clk), .aresetn(aresetn));

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
    // UART External Pins + Passive AXI Snoop
    assign soc_uart_rx       = uart_vif.uart_rx;
    assign uart_vif.uart_tx  = soc_uart_tx;
    assign uart_vif.uart_irq = soc_uart_irq;
    assign uart_vif.axi_awaddr  = u_soc_dut.u_uart.axi_awaddr_i;
    assign uart_vif.axi_awvalid = u_soc_dut.u_uart.axi_awvalid_i;
    assign uart_vif.axi_awready = u_soc_dut.u_uart.axi_awready_o;
    assign uart_vif.axi_wdata   = u_soc_dut.u_uart.axi_wdata_i;
    assign uart_vif.axi_wstrb   = u_soc_dut.u_uart.axi_wstrb_i;
    assign uart_vif.axi_wvalid  = u_soc_dut.u_uart.axi_wvalid_i;
    assign uart_vif.axi_wready  = u_soc_dut.u_uart.axi_wready_o;
    assign uart_vif.axi_bresp   = u_soc_dut.u_uart.axi_bresp_o;
    assign uart_vif.axi_bvalid  = u_soc_dut.u_uart.axi_bvalid_o;
    assign uart_vif.axi_bready  = u_soc_dut.u_uart.axi_bready_i;
    assign uart_vif.axi_araddr  = u_soc_dut.u_uart.axi_araddr_i;
    assign uart_vif.axi_arvalid = u_soc_dut.u_uart.axi_arvalid_i;
    assign uart_vif.axi_arready = u_soc_dut.u_uart.axi_arready_o;
    assign uart_vif.axi_rdata   = u_soc_dut.u_uart.axi_rdata_o;
    assign uart_vif.axi_rresp   = u_soc_dut.u_uart.axi_rresp_o;
    assign uart_vif.axi_rvalid  = u_soc_dut.u_uart.axi_rvalid_o;
    assign uart_vif.axi_rready  = u_soc_dut.u_uart.axi_rready_i;

    // GPIO External Pins + Passive AXI Snoop
    assign soc_gpio_i           = gpio_vif.gpio_i;
    assign gpio_vif.gpio_o      = soc_gpio_o;
    assign gpio_vif.gpio_dir_o  = soc_gpio_dir_o;
    assign gpio_vif.gpio_intr_o = soc_gpio_intr;
    assign gpio_vif.s_axi_awaddr  = u_soc_dut.u_gpio.s_axi_awaddr;
    assign gpio_vif.s_axi_awvalid = u_soc_dut.u_gpio.s_axi_awvalid;
    assign gpio_vif.s_axi_awready = u_soc_dut.u_gpio.s_axi_awready;
    assign gpio_vif.s_axi_wdata   = u_soc_dut.u_gpio.s_axi_wdata;
    assign gpio_vif.s_axi_wvalid  = u_soc_dut.u_gpio.s_axi_wvalid;
    assign gpio_vif.s_axi_wready  = u_soc_dut.u_gpio.s_axi_wready;
    assign gpio_vif.s_axi_bresp   = u_soc_dut.u_gpio.s_axi_bresp;
    assign gpio_vif.s_axi_bvalid  = u_soc_dut.u_gpio.s_axi_bvalid;
    assign gpio_vif.s_axi_bready  = u_soc_dut.u_gpio.s_axi_bready;
    assign gpio_vif.s_axi_araddr  = u_soc_dut.u_gpio.s_axi_araddr;
    assign gpio_vif.s_axi_arvalid = u_soc_dut.u_gpio.s_axi_arvalid;
    assign gpio_vif.s_axi_arready = u_soc_dut.u_gpio.s_axi_arready;
    assign gpio_vif.s_axi_rdata   = u_soc_dut.u_gpio.s_axi_rdata;
    assign gpio_vif.s_axi_rresp   = u_soc_dut.u_gpio.s_axi_rresp;
    assign gpio_vif.s_axi_rvalid  = u_soc_dut.u_gpio.s_axi_rvalid;
    assign gpio_vif.s_axi_rready  = u_soc_dut.u_gpio.s_axi_rready;

    // Timer Passive Probe
    assign timer_vif.s_axi_awaddr  = u_soc_dut.u_timer.s_axi_awaddr;
    assign timer_vif.s_axi_awprot  = u_soc_dut.u_timer.s_axi_awprot;
    assign timer_vif.s_axi_awvalid = u_soc_dut.u_timer.s_axi_awvalid;
    assign timer_vif.s_axi_awready = u_soc_dut.u_timer.s_axi_awready;
    assign timer_vif.s_axi_wdata   = u_soc_dut.u_timer.s_axi_wdata;
    assign timer_vif.s_axi_wstrb   = u_soc_dut.u_timer.s_axi_wstrb;
    assign timer_vif.s_axi_wvalid  = u_soc_dut.u_timer.s_axi_wvalid;
    assign timer_vif.s_axi_wready  = u_soc_dut.u_timer.s_axi_wready;
    assign timer_vif.s_axi_bresp   = u_soc_dut.u_timer.s_axi_bresp;
    assign timer_vif.s_axi_bvalid  = u_soc_dut.u_timer.s_axi_bvalid;
    assign timer_vif.s_axi_bready  = u_soc_dut.u_timer.s_axi_bready;
    assign timer_vif.s_axi_araddr  = u_soc_dut.u_timer.s_axi_araddr;
    assign timer_vif.s_axi_arprot  = u_soc_dut.u_timer.s_axi_arprot;
    assign timer_vif.s_axi_arvalid = u_soc_dut.u_timer.s_axi_arvalid;
    assign timer_vif.s_axi_arready = u_soc_dut.u_timer.s_axi_arready;
    assign timer_vif.s_axi_rdata   = u_soc_dut.u_timer.s_axi_rdata;
    assign timer_vif.s_axi_rresp   = u_soc_dut.u_timer.s_axi_rresp;
    assign timer_vif.s_axi_rvalid  = u_soc_dut.u_timer.s_axi_rvalid;
    assign timer_vif.s_axi_rready  = u_soc_dut.u_timer.s_axi_rready;
    assign timer_vif.timer_irq     = soc_timer_irq;

    // SHA-256 Passive Probe
    assign sha_vif.s_axi_awaddr  = u_soc_dut.u_sha.s_axi_awaddr;
    assign sha_vif.s_axi_awprot  = u_soc_dut.u_sha.s_axi_awprot;
    assign sha_vif.s_axi_awvalid = u_soc_dut.u_sha.s_axi_awvalid;
    assign sha_vif.s_axi_awready = u_soc_dut.u_sha.s_axi_awready;
    assign sha_vif.s_axi_wdata   = u_soc_dut.u_sha.s_axi_wdata;
    assign sha_vif.s_axi_wstrb   = u_soc_dut.u_sha.s_axi_wstrb;
    assign sha_vif.s_axi_wvalid  = u_soc_dut.u_sha.s_axi_wvalid;
    assign sha_vif.s_axi_wready  = u_soc_dut.u_sha.s_axi_wready;
    assign sha_vif.s_axi_bresp   = u_soc_dut.u_sha.s_axi_bresp;
    assign sha_vif.s_axi_bvalid  = u_soc_dut.u_sha.s_axi_bvalid;
    assign sha_vif.s_axi_bready  = u_soc_dut.u_sha.s_axi_bready;
    assign sha_vif.s_axi_araddr  = u_soc_dut.u_sha.s_axi_araddr;
    assign sha_vif.s_axi_arprot  = u_soc_dut.u_sha.s_axi_arprot;
    assign sha_vif.s_axi_arvalid = u_soc_dut.u_sha.s_axi_arvalid;
    assign sha_vif.s_axi_arready = u_soc_dut.u_sha.s_axi_arready;
    assign sha_vif.s_axi_rdata   = u_soc_dut.u_sha.s_axi_rdata;
    assign sha_vif.s_axi_rresp   = u_soc_dut.u_sha.s_axi_rresp;
    assign sha_vif.s_axi_rvalid  = u_soc_dut.u_sha.s_axi_rvalid;
    assign sha_vif.s_axi_rready  = u_soc_dut.u_sha.s_axi_rready;
    assign sha_vif.sha_irq       = soc_sha_irq;

    // AES-256 Passive Probe
    assign aes_vif.s_axi_awaddr  = u_soc_dut.u_aes.s_axi_awaddr;
    assign aes_vif.s_axi_awprot  = u_soc_dut.u_aes.s_axi_awprot;
    assign aes_vif.s_axi_awvalid = u_soc_dut.u_aes.s_axi_awvalid;
    assign aes_vif.s_axi_awready = u_soc_dut.u_aes.s_axi_awready;
    assign aes_vif.s_axi_wdata   = u_soc_dut.u_aes.s_axi_wdata;
    assign aes_vif.s_axi_wstrb   = u_soc_dut.u_aes.s_axi_wstrb;
    assign aes_vif.s_axi_wvalid  = u_soc_dut.u_aes.s_axi_wvalid;
    assign aes_vif.s_axi_wready  = u_soc_dut.u_aes.s_axi_wready;
    assign aes_vif.s_axi_bresp   = u_soc_dut.u_aes.s_axi_bresp;
    assign aes_vif.s_axi_bvalid  = u_soc_dut.u_aes.s_axi_bvalid;
    assign aes_vif.s_axi_bready  = u_soc_dut.u_aes.s_axi_bready;
    assign aes_vif.s_axi_araddr  = u_soc_dut.u_aes.s_axi_araddr;
    assign aes_vif.s_axi_arprot  = u_soc_dut.u_aes.s_axi_arprot;
    assign aes_vif.s_axi_arvalid = u_soc_dut.u_aes.s_axi_arvalid;
    assign aes_vif.s_axi_arready = u_soc_dut.u_aes.s_axi_arready;
    assign aes_vif.s_axi_rdata   = u_soc_dut.u_aes.s_axi_rdata;
    assign aes_vif.s_axi_rresp   = u_soc_dut.u_aes.s_axi_rresp;
    assign aes_vif.s_axi_rvalid  = u_soc_dut.u_aes.s_axi_rvalid;
    assign aes_vif.s_axi_rready  = u_soc_dut.u_aes.s_axi_rready;
    assign aes_vif.irq           = soc_aes_irq;

    // DMA Passive Probe
    assign dma_vif.rst           = ~aresetn;
    assign dma_vif.dma_done_o    = soc_dma_done;
    assign dma_vif.dma_error_o   = soc_dma_error;
    assign dma_vif.dma_s_awaddr  = u_soc_dut.u_dma_controller.dma_s_awaddr;
    assign dma_vif.dma_s_awprot  = u_soc_dut.u_dma_controller.dma_s_awprot;
    assign dma_vif.dma_s_awvalid = u_soc_dut.u_dma_controller.dma_s_awvalid;
    assign dma_vif.dma_s_awready = u_soc_dut.u_dma_controller.dma_s_awready;
    assign dma_vif.dma_s_wdata   = u_soc_dut.u_dma_controller.dma_s_wdata;
    assign dma_vif.dma_s_wstrb   = u_soc_dut.u_dma_controller.dma_s_wstrb;
    assign dma_vif.dma_s_wvalid  = u_soc_dut.u_dma_controller.dma_s_wvalid;
    assign dma_vif.dma_s_wready  = u_soc_dut.u_dma_controller.dma_s_wready;
    assign dma_vif.dma_s_bresp   = u_soc_dut.u_dma_controller.dma_s_bresp;
    assign dma_vif.dma_s_bvalid  = u_soc_dut.u_dma_controller.dma_s_bvalid;
    assign dma_vif.dma_s_bready  = u_soc_dut.u_dma_controller.dma_s_bready;
    assign dma_vif.dma_s_araddr  = u_soc_dut.u_dma_controller.dma_s_araddr;
    assign dma_vif.dma_s_arprot  = u_soc_dut.u_dma_controller.dma_s_arprot;
    assign dma_vif.dma_s_arvalid = u_soc_dut.u_dma_controller.dma_s_arvalid;
    assign dma_vif.dma_s_arready = u_soc_dut.u_dma_controller.dma_s_arready;
    assign dma_vif.dma_s_rdata   = u_soc_dut.u_dma_controller.dma_s_rdata;
    assign dma_vif.dma_s_rresp   = u_soc_dut.u_dma_controller.dma_s_rresp;
    assign dma_vif.dma_s_rvalid  = u_soc_dut.u_dma_controller.dma_s_rvalid;
    assign dma_vif.dma_s_rready  = u_soc_dut.u_dma_controller.dma_s_rready;
    assign dma_vif.dma_m_awid    = u_soc_dut.u_dma_controller.dma_m_awid;
    assign dma_vif.dma_m_awaddr  = u_soc_dut.u_dma_controller.dma_m_awaddr;
    assign dma_vif.dma_m_awlen   = u_soc_dut.u_dma_controller.dma_m_awlen;
    assign dma_vif.dma_m_awsize  = u_soc_dut.u_dma_controller.dma_m_awsize;
    assign dma_vif.dma_m_awburst = u_soc_dut.u_dma_controller.dma_m_awburst;
    assign dma_vif.dma_m_awlock  = u_soc_dut.u_dma_controller.dma_m_awlock;
    assign dma_vif.dma_m_awcache = u_soc_dut.u_dma_controller.dma_m_awcache;
    assign dma_vif.dma_m_awprot  = u_soc_dut.u_dma_controller.dma_m_awprot;
    assign dma_vif.dma_m_awqos   = u_soc_dut.u_dma_controller.dma_m_awqos;
    assign dma_vif.dma_m_awregion= u_soc_dut.u_dma_controller.dma_m_awregion;
    assign dma_vif.dma_m_awvalid = u_soc_dut.u_dma_controller.dma_m_awvalid;
    assign dma_vif.dma_m_awready = u_soc_dut.u_dma_controller.dma_m_awready;
    assign dma_vif.dma_m_wdata   = u_soc_dut.u_dma_controller.dma_m_wdata;
    assign dma_vif.dma_m_wstrb   = u_soc_dut.u_dma_controller.dma_m_wstrb;
    assign dma_vif.dma_m_wlast   = u_soc_dut.u_dma_controller.dma_m_wlast;
    assign dma_vif.dma_m_wvalid  = u_soc_dut.u_dma_controller.dma_m_wvalid;
    assign dma_vif.dma_m_wready  = u_soc_dut.u_dma_controller.dma_m_wready;
    assign dma_vif.dma_m_bid     = u_soc_dut.u_dma_controller.dma_m_bid;
    assign dma_vif.dma_m_bresp   = u_soc_dut.u_dma_controller.dma_m_bresp;
    assign dma_vif.dma_m_bvalid  = u_soc_dut.u_dma_controller.dma_m_bvalid;
    assign dma_vif.dma_m_bready  = u_soc_dut.u_dma_controller.dma_m_bready;
    assign dma_vif.dma_m_arid    = u_soc_dut.u_dma_controller.dma_m_arid;
    assign dma_vif.dma_m_araddr  = u_soc_dut.u_dma_controller.dma_m_araddr;
    assign dma_vif.dma_m_arlen   = u_soc_dut.u_dma_controller.dma_m_arlen;
    assign dma_vif.dma_m_arsize  = u_soc_dut.u_dma_controller.dma_m_arsize;
    assign dma_vif.dma_m_arburst = u_soc_dut.u_dma_controller.dma_m_arburst;
    assign dma_vif.dma_m_arlock  = u_soc_dut.u_dma_controller.dma_m_arlock;
    assign dma_vif.dma_m_arcache = u_soc_dut.u_dma_controller.dma_m_arcache;
    assign dma_vif.dma_m_arprot  = u_soc_dut.u_dma_controller.dma_m_arprot;
    assign dma_vif.dma_m_arqos   = u_soc_dut.u_dma_controller.dma_m_arqos;
    assign dma_vif.dma_m_arregion= u_soc_dut.u_dma_controller.dma_m_arregion;
    assign dma_vif.dma_m_arvalid = u_soc_dut.u_dma_controller.dma_m_arvalid;
    assign dma_vif.dma_m_arready = u_soc_dut.u_dma_controller.dma_m_arready;
    assign dma_vif.dma_m_rid     = u_soc_dut.u_dma_controller.dma_m_rid;
    assign dma_vif.dma_m_rdata   = u_soc_dut.u_dma_controller.dma_m_rdata;
    assign dma_vif.dma_m_rresp   = u_soc_dut.u_dma_controller.dma_m_rresp;
    assign dma_vif.dma_m_rlast   = u_soc_dut.u_dma_controller.dma_m_rlast;
    assign dma_vif.dma_m_rvalid  = u_soc_dut.u_dma_controller.dma_m_rvalid;
    assign dma_vif.dma_m_rready  = u_soc_dut.u_dma_controller.dma_m_rready;

    // Shared Bus Interface Interrupt Observations
    assign bus_vif.uart_irq  = soc_uart_irq;
    assign bus_vif.timer_irq = soc_timer_irq;
    assign bus_vif.aes_irq   = soc_aes_irq;
    assign bus_vif.sha_irq   = soc_sha_irq;
    assign bus_vif.dma_done  = soc_dma_done;
    assign bus_vif.dma_error = soc_dma_error;
    assign bus_vif.gpio_intr = soc_gpio_intr;

    // -------------------------------------------------------------------------
    // SoC AXI4 Master 0 Port (Directly driven by CPU / Testbench Master)
    // -------------------------------------------------------------------------
    // -------------------------------------------------------------------------
    // DUT: Integrated SoC Top-Level (soc_top) connected to bus_vif BFM
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

        // External AXI Master 0 connected to bus_vif
        .ext_s00_axi_awid    (bus_vif.m_awid),
        .ext_s00_axi_awaddr  (bus_vif.m_awaddr),
        .ext_s00_axi_awlen   (bus_vif.m_awlen),
        .ext_s00_axi_awsize  (bus_vif.m_awsize),
        .ext_s00_axi_awburst (bus_vif.m_awburst),
        .ext_s00_axi_awlock  (bus_vif.m_awlock),
        .ext_s00_axi_awcache (bus_vif.m_awcache),
        .ext_s00_axi_awprot  (bus_vif.m_awprot),
        .ext_s00_axi_awqos   (bus_vif.m_awqos),
        .ext_s00_axi_awvalid (bus_vif.m_awvalid),
        .ext_s00_axi_awready (bus_vif.m_awready),

        .ext_s00_axi_wdata   (bus_vif.m_wdata),
        .ext_s00_axi_wstrb   (bus_vif.m_wstrb),
        .ext_s00_axi_wlast   (bus_vif.m_wlast),
        .ext_s00_axi_wvalid  (bus_vif.m_wvalid),
        .ext_s00_axi_wready  (bus_vif.m_wready),

        .ext_s00_axi_bid     (bus_vif.m_bid),
        .ext_s00_axi_bresp   (bus_vif.m_bresp),
        .ext_s00_axi_bvalid  (bus_vif.m_bvalid),
        .ext_s00_axi_bready  (bus_vif.m_bready),

        .ext_s00_axi_arid    (bus_vif.m_arid),
        .ext_s00_axi_araddr  (bus_vif.m_araddr),
        .ext_s00_axi_arlen   (bus_vif.m_arlen),
        .ext_s00_axi_arsize  (bus_vif.m_arsize),
        .ext_s00_axi_arburst (bus_vif.m_arburst),
        .ext_s00_axi_arlock  (bus_vif.m_arlock),
        .ext_s00_axi_arcache (bus_vif.m_arcache),
        .ext_s00_axi_arprot  (bus_vif.m_arprot),
        .ext_s00_axi_arqos   (bus_vif.m_arqos),
        .ext_s00_axi_arvalid (bus_vif.m_arvalid),
        .ext_s00_axi_arready (bus_vif.m_arready),

        .ext_s00_axi_rid     (bus_vif.m_rid),
        .ext_s00_axi_rdata   (bus_vif.m_rdata),
        .ext_s00_axi_rresp   (bus_vif.m_rresp),
        .ext_s00_axi_rlast   (bus_vif.m_rlast),
        .ext_s00_axi_rvalid  (bus_vif.m_rvalid),
        .ext_s00_axi_rready  (bus_vif.m_rready),

        // DMA CSR slave interface (0x4000_5000 window)
        .dma_csr_awaddr      (bus_vif.dma_awaddr),
        .dma_csr_awprot      (bus_vif.dma_awprot),
        .dma_csr_awvalid     (bus_vif.dma_awvalid),
        .dma_csr_awready     (bus_vif.dma_awready),
        .dma_csr_wdata       (bus_vif.dma_wdata),
        .dma_csr_wstrb       (bus_vif.dma_wstrb),
        .dma_csr_wvalid      (bus_vif.dma_wvalid),
        .dma_csr_wready      (bus_vif.dma_wready),
        .dma_csr_bresp       (bus_vif.dma_bresp),
        .dma_csr_bvalid      (bus_vif.dma_bvalid),
        .dma_csr_bready      (bus_vif.dma_bready),
        .dma_csr_araddr      (bus_vif.dma_araddr),
        .dma_csr_arprot      (bus_vif.dma_arprot),
        .dma_csr_arvalid     (bus_vif.dma_arvalid),
        .dma_csr_arready     (bus_vif.dma_arready),
        .dma_csr_rdata       (bus_vif.dma_rdata),
        .dma_csr_rresp       (bus_vif.dma_rresp),
        .dma_csr_rvalid      (bus_vif.dma_rvalid),
        .dma_csr_rready      (bus_vif.dma_rready),

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

    task sv_axi_write_strb(input int unsigned addr, input int unsigned data,
                           input int unsigned wstrb, output int unsigned resp);
        bus_vif.axi_write_strb(addr, data, wstrb, resp);
    endtask

    task sv_axi_write_resp(input int unsigned addr, input int unsigned data, output int unsigned resp);
        bus_vif.axi_write_resp(addr, data, resp);
    endtask

    task sv_axi_write(input int unsigned addr, input int unsigned data);
        bus_vif.axi_write(addr, data);
    endtask

    task sv_axi_read_resp(input int unsigned addr, output int unsigned data, output int unsigned resp);
        bus_vif.axi_read_resp(addr, data, resp);
    endtask

    task sv_axi_read(input int unsigned addr, output int unsigned data);
        bus_vif.axi_read(addr, data);
    endtask

    task sv_axi_concurrent_rw(input int unsigned wr_addr, input int unsigned wr_data,
                              input int unsigned rd_addr, output int unsigned rd_data,
                              output int unsigned bresp, output int unsigned rresp);
        bus_vif.axi_concurrent_rw(wr_addr, wr_data, rd_addr, rd_data, bresp, rresp);
    endtask

    task sv_wait_cycles(input int cycles);
        bus_vif.wait_cycles(cycles);
    endtask

    task sv_delay_cycles(input int cycles);
        bus_vif.wait_cycles(cycles);
    endtask

    task sv_axi_burst_wr4(input int unsigned addr, input int unsigned burst,
                          input int unsigned w0, input int unsigned w1,
                          input int unsigned w2, input int unsigned w3,
                          output int unsigned bresp);
        bus_vif.axi_burst_wr4(addr, burst, w0, w1, w2, w3, bresp);
    endtask

    task sv_axi_burst_rd4(input int unsigned addr, input int unsigned burst,
                          output int unsigned w0, output int unsigned w1,
                          output int unsigned w2, output int unsigned w3,
                          output int unsigned rresp);
        bus_vif.axi_burst_rd4(addr, burst, w0, w1, w2, w3, rresp);
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

    task sv_uart_send_err(input byte unsigned byte_val,
                          input byte unsigned parity_en,
                          input byte unsigned parity_odd,
                          input byte unsigned corrupt_parity,
                          input byte unsigned corrupt_stop);
        integer baud_clks, b;
        bit parity_bit;
        begin
            baud_clks = BAUD_DIV;
            uart_vif.uart_rx <= 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_vif.uart_rx <= byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            if (parity_en != 8'h00) begin
                parity_bit = ^byte_val;
                if (parity_odd != 8'h00) parity_bit = ~parity_bit;
                if (corrupt_parity != 8'h00) parity_bit = ~parity_bit;
                uart_vif.uart_rx <= parity_bit;
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_vif.uart_rx <= (corrupt_stop != 8'h00) ? 1'b0 : 1'b1;
            repeat (baud_clks) @(posedge uart_clk);
            uart_vif.uart_rx <= 1'b1; // return to idle
            repeat (10) @(posedge uart_clk);
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

    task sv_uart_send_cfg(input byte unsigned byte_val,
                          input int unsigned  baud_div,
                          input byte unsigned parity_en,
                          input byte unsigned parity_odd,
                          input byte unsigned stop_2bit,
                          input byte unsigned err_mask);
        int baud_clks, b;
        bit parity_bit;
        begin
            baud_clks = (baud_div > 0) ? int'(baud_div) : BAUD_DIV;
            uart_vif.uart_rx <= 1'b0;
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_vif.uart_rx <= byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            if (parity_en != 8'h00) begin
                parity_bit = ^byte_val;
                if (parity_odd != 8'h00) parity_bit = ~parity_bit;
                if (err_mask[0]) parity_bit = ~parity_bit;
                uart_vif.uart_rx <= parity_bit;
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_vif.uart_rx <= err_mask[1] ? 1'b0 : 1'b1;
            repeat (baud_clks) @(posedge uart_clk);
            if (stop_2bit != 8'h00) begin
                uart_vif.uart_rx <= err_mask[2] ? 1'b0 : 1'b1;
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_vif.uart_rx <= 1'b1;
            repeat (10) @(posedge uart_clk);
        end
    endtask

    task sv_uart_tx_cfg(input byte unsigned  tx_val,
                        input int unsigned   baud_div,
                        input byte unsigned  parity_en,
                        input byte unsigned  parity_odd,
                        input byte unsigned  stop_2bit,
                        output byte unsigned rx_cap,
                        output int unsigned  frame_ok);
        int bit_clks, half_bit, b;
        bit start_s, par_s, exp_par, stop1_s, stop2_s;
        begin
            bit_clks = ((baud_div > 0) ? int'(baud_div) : BAUD_DIV) + 1;
            half_bit = bit_clks / 2;
            rx_cap   = 8'h00;
            frame_ok = 32'd0;
            fork
                begin
                    sv_axi_write(32'h4000_1000, {24'h0, tx_val});
                end
                begin
                    @(posedge uart_clk);
                    while (soc_uart_tx !== 1'b1) @(posedge uart_clk);
                    while (soc_uart_tx !== 1'b0) @(posedge uart_clk);
                    repeat (half_bit) @(posedge uart_clk);
                    start_s = soc_uart_tx;
                    for (b = 0; b < 8; b = b + 1) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        rx_cap[b] = soc_uart_tx;
                    end
                    par_s   = 1'b0;
                    exp_par = 1'b0;
                    if (parity_en != 8'h00) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        par_s   = soc_uart_tx;
                        exp_par = (parity_odd != 8'h00) ? ~(^rx_cap) : (^rx_cap);
                    end
                    repeat (bit_clks) @(posedge uart_clk);
                    stop1_s = soc_uart_tx;
                    stop2_s = 1'b1;
                    if (stop_2bit != 8'h00) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        stop2_s = soc_uart_tx;
                    end
                    repeat (10) @(posedge uart_clk);
                    frame_ok = ((start_s === 1'b0) &&
                                ((parity_en == 8'h00) || (par_s === exp_par)) &&
                                (stop1_s === 1'b1) && (stop2_s === 1'b1)) ? 32'd1 : 32'd0;
                end
            join
        end
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

    task sv_get_gpio_dir(output int unsigned dir_val_low, output int unsigned dir_val_high);
        begin
            dir_val_low  = soc_gpio_dir_o[31:0];
            dir_val_high = soc_gpio_dir_o[63:32];
        end
    endtask

    task sv_get_gpio_intr(output int unsigned bank0_intr, output int unsigned bank1_intr);
        begin
            bank0_intr = {31'h0, soc_gpio_intr[0]};
            bank1_intr = {31'h0, soc_gpio_intr[1]};
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

    reg [127:0] aes_done_dout_cap;
    reg         aes_done_cap_valid;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            aes_done_dout_cap  <= 128'h0;
            aes_done_cap_valid <= 1'b0;
        end else begin
            if (u_soc_dut.u_aes.state == 4'd0 &&
                u_soc_dut.u_aes.ctrl_start) begin
                aes_done_cap_valid <= 1'b0;
            end
            if (u_soc_dut.u_aes.core_done_r) begin
                aes_done_dout_cap  <= u_soc_dut.u_aes.dout_data;
                aes_done_cap_valid <= 1'b1;
            end
        end
    end

    task sv_get_aes_done_dout(output int unsigned w3, output int unsigned w2,
                              output int unsigned w1, output int unsigned w0,
                              output int unsigned valid);
        begin
            w3    = aes_done_dout_cap[127:96];
            w2    = aes_done_dout_cap[95:64];
            w1    = aes_done_dout_cap[63:32];
            w0    = aes_done_dout_cap[31:0];
            valid = {31'h0, aes_done_cap_valid};
        end
    endtask

    task sv_get_sim_flags(output int unsigned is_xsim);
        begin
`ifdef XILINX_SIMULATOR
            is_xsim = 32'd1;
`elsif XSIM_SIM
            is_xsim = 32'd1;
`else
            is_xsim = 32'd0;
`endif
        end
    endtask

    export "DPI-C" task sv_axi_write;
    export "DPI-C" task sv_axi_read;
    export "DPI-C" task sv_axi_write_resp;
    export "DPI-C" task sv_axi_write_strb;
    export "DPI-C" task sv_axi_read_resp;
    export "DPI-C" task sv_axi_concurrent_rw;
    export "DPI-C" task sv_wait_cycles;
    export "DPI-C" task sv_delay_cycles;
    export "DPI-C" task sv_uart_send_byte;
    export "DPI-C" task sv_uart_send_err;
    export "DPI-C" task sv_uart_recv_byte;
    export "DPI-C" task sv_uart_tx_loopback;
    export "DPI-C" task sv_uart_b2b_tx;
    export "DPI-C" task sv_set_gpio_in;
    export "DPI-C" task sv_get_gpio_out;
    export "DPI-C" task sv_get_gpio_dir;
    export "DPI-C" task sv_get_gpio_intr;
    export "DPI-C" task sv_get_irqs;
    export "DPI-C" task sv_get_aes_done_dout;
    export "DPI-C" task sv_get_sim_flags;
    export "DPI-C" task sv_axi_burst_wr4;
    export "DPI-C" task sv_axi_burst_rd4;
    export "DPI-C" task sv_uart_send_cfg;
    export "DPI-C" task sv_uart_tx_cfg;

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
                `uvm_info("SOC_C_TEST", ">>> ALL C FIRMWARE TESTS PASSED ON INTEGRATED UVM VIP TOP! <<<", UVM_LOW)
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

            // 1. Enable Bank 0 rising-edge & Bank 1 falling-edge IRQs before external GPIO pin VIP stimulus
            sv_axi_write(32'h4000_3380, 32'h0000_0001); // GPIO RISE_EN0 bit 0
            sv_axi_write(32'h4000_3404, 32'h0000_0002); // GPIO FALL_EN1 bit 1
            `uvm_info("SOC_VIP_TEST", ">>> Executing External GPIO Pin Stimulus Suite...", UVM_LOW)
            gpio_seq.start(gpio_env.agent.seqr);
            `uvm_info("SOC_VIP_TEST", ">>> External GPIO Pin Stimulus Completed.", UVM_LOW)

            #200;
            begin
                int unsigned st0, st1;
                sv_axi_read(32'h4000_3580, st0);
                sv_axi_read(32'h4000_3584, st1);
                `uvm_info("SOC_VIP_TEST",
                    $sformatf("GPIO IRQ Status Observed via UVM Stimulus: STATUS0=0x%08X STATUS1=0x%08X gpio_intr=%02b",
                              st0, st1, soc_gpio_intr), UVM_LOW)
                sv_axi_write(32'h4000_3580, 32'hFFFF_FFFF);
                sv_axi_write(32'h4000_3584, 32'hFFFF_FFFF);
                sv_axi_write(32'h4000_3380, 32'h0000_0000);
                sv_axi_write(32'h4000_3404, 32'h0000_0000);
            end

            #5000;

            // 2. Configure UART via internal AXI so it can receive serial bytes (including error injection)
            sv_axi_write(32'h4000_100C, 32'h0000_0080); // LCR: DLAB=1
            sv_axi_write(32'h4000_1008, 32'h0000_01B2); // BAUD: 434 (115200 baud)
            sv_axi_write(32'h4000_100C, 32'h0000_0000); // LCR: 8N1, DLAB=0
            sv_axi_write(32'h4000_1004, 32'h0000_0001); // IER: RX data IRQ enable

            // 3. Execute External UART Serial Injection (drives uart_rx pin into SoC)
            `uvm_info("SOC_VIP_TEST", ">>> Executing External UART Serial Injection Suite...", UVM_LOW)
            uart_seq.start(uart_env.agent.seqr);
            `uvm_info("SOC_VIP_TEST", ">>> External UART Serial Injection Completed.", UVM_LOW)

            begin
                int unsigned lsr_val, rbr_val;
                sv_axi_read(32'h4000_1014, lsr_val);
                `uvm_info("SOC_VIP_TEST",
                    $sformatf("UART LSR after valid+error frames: 0x%08X (DR=%0b OE=%0b PE=%0b FE=%0b THRE=%0b TEMT=%0b)",
                              lsr_val, lsr_val[0], lsr_val[1], lsr_val[2], lsr_val[3], lsr_val[5], lsr_val[6]), UVM_LOW)
                for (int d = 0; d < 16 && ((lsr_val & 32'h1) != 0); d++) begin
                    sv_axi_read(32'h4000_1000, rbr_val);
                    sv_axi_read(32'h4000_1014, lsr_val);
                end
            end

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
        uvm_config_db#(virtual soc_axi_if)::set(null, "*", "bus_vif", bus_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "vif", gpio_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "uart_vif", uart_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "vif", uart_vif);
        uvm_config_db#(virtual timer_vip_if)::set(null, "*", "timer_vif", timer_vif);
        uvm_config_db#(virtual sha_vip_if)::set(null, "*", "sha_vif", sha_vif);
        uvm_config_db#(virtual aes_vip_if)::set(null, "*", "aes_vif", aes_vif);
        uvm_config_db#(virtual dma_vip_if)::set(null, "*", "dma_vif", dma_vif);

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

`include "soc_cov_inst.svh"
    `INST_SOC_COV(u_soc_dut, 1'b0, 1'b0, 1'b0)

endmodule : tb_top

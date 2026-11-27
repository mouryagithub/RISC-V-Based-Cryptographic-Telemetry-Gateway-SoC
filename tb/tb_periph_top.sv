// =============================================================================
// File        : tb/tb_periph_top.sv
// Module      : tb_periph_top
// Description : Clean Peripheral UVM-1.2 Verification Top for the 6 SoC
//               Peripherals (UART, Timer, GPIO, SHA-256, AES-256, AXI DMA).
//               Connects soc_top (USE_INTERNAL_CPU=0) to soc_axi_if and all 6
//               VIP interfaces with no legacy DPI-C/CPU scaffolding.
// =============================================================================

`timescale 1ns/1ps

module tb_periph_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import gpio_vip_pkg::*;
    import uart_vip_pkg::*;
    import timer_vip_pkg::*;
    import sha_vip_pkg::*;
    import aes_vip_pkg::*;
    import dma_vip_pkg::*;

    localparam int CLK_PERIOD = 20; // 50 MHz system & UART clock

    logic clk;
    logic aresetn;

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    initial begin
        aresetn = 1'b0;
        repeat (15) @(posedge clk);
        aresetn = 1'b1;
    end

    // Shared SoC AXI4 Master + DMA CSR BFM & 6 Peripheral VIP Interfaces
    soc_axi_if   bus_vif(.clk(clk), .aresetn(aresetn));
    gpio_vip_if  gpio_vif(.clk(clk), .aresetn(aresetn));
    uart_vip_if  uart_vif(.clk(clk), .aresetn(aresetn));
    timer_vip_if timer_vif(.aclk(clk), .aresetn(aresetn));
    sha_vip_if   sha_vif(.aclk(clk), .aresetn(aresetn));
    aes_vip_if   aes_vif(.aclk(clk), .aresetn(aresetn));
    dma_vip_if   dma_vif(.clk(clk), .aresetn(aresetn));

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

    // UART External Pins + Passive AXI Snoop
    assign soc_uart_rx          = uart_vif.uart_rx;
    assign uart_vif.uart_tx     = soc_uart_tx;
    assign uart_vif.uart_irq    = soc_uart_irq;
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
    assign soc_gpio_i             = gpio_vif.gpio_i;
    assign gpio_vif.gpio_o        = soc_gpio_o;
    assign gpio_vif.gpio_dir_o    = soc_gpio_dir_o;
    assign gpio_vif.gpio_intr_o   = soc_gpio_intr;
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
    assign dma_vif.rst            = ~aresetn;
    assign dma_vif.dma_done_o     = soc_dma_done;
    assign dma_vif.dma_error_o    = soc_dma_error;
    assign dma_vif.dma_s_awaddr   = u_soc_dut.u_dma_controller.dma_s_awaddr;
    assign dma_vif.dma_s_awprot   = u_soc_dut.u_dma_controller.dma_s_awprot;
    assign dma_vif.dma_s_awvalid  = u_soc_dut.u_dma_controller.dma_s_awvalid;
    assign dma_vif.dma_s_awready  = u_soc_dut.u_dma_controller.dma_s_awready;
    assign dma_vif.dma_s_wdata    = u_soc_dut.u_dma_controller.dma_s_wdata;
    assign dma_vif.dma_s_wstrb    = u_soc_dut.u_dma_controller.dma_s_wstrb;
    assign dma_vif.dma_s_wvalid   = u_soc_dut.u_dma_controller.dma_s_wvalid;
    assign dma_vif.dma_s_wready   = u_soc_dut.u_dma_controller.dma_s_wready;
    assign dma_vif.dma_s_bresp    = u_soc_dut.u_dma_controller.dma_s_bresp;
    assign dma_vif.dma_s_bvalid   = u_soc_dut.u_dma_controller.dma_s_bvalid;
    assign dma_vif.dma_s_bready   = u_soc_dut.u_dma_controller.dma_s_bready;
    assign dma_vif.dma_s_araddr   = u_soc_dut.u_dma_controller.dma_s_araddr;
    assign dma_vif.dma_s_arprot   = u_soc_dut.u_dma_controller.dma_s_arprot;
    assign dma_vif.dma_s_arvalid  = u_soc_dut.u_dma_controller.dma_s_arvalid;
    assign dma_vif.dma_s_arready  = u_soc_dut.u_dma_controller.dma_s_arready;
    assign dma_vif.dma_s_rdata    = u_soc_dut.u_dma_controller.dma_s_rdata;
    assign dma_vif.dma_s_rresp    = u_soc_dut.u_dma_controller.dma_s_rresp;
    assign dma_vif.dma_s_rvalid   = u_soc_dut.u_dma_controller.dma_s_rvalid;
    assign dma_vif.dma_s_rready   = u_soc_dut.u_dma_controller.dma_s_rready;
    assign dma_vif.dma_m_awid     = u_soc_dut.u_dma_controller.dma_m_awid;
    assign dma_vif.dma_m_awaddr   = u_soc_dut.u_dma_controller.dma_m_awaddr;
    assign dma_vif.dma_m_awlen    = u_soc_dut.u_dma_controller.dma_m_awlen;
    assign dma_vif.dma_m_awsize   = u_soc_dut.u_dma_controller.dma_m_awsize;
    assign dma_vif.dma_m_awburst  = u_soc_dut.u_dma_controller.dma_m_awburst;
    assign dma_vif.dma_m_awlock   = u_soc_dut.u_dma_controller.dma_m_awlock;
    assign dma_vif.dma_m_awcache  = u_soc_dut.u_dma_controller.dma_m_awcache;
    assign dma_vif.dma_m_awprot   = u_soc_dut.u_dma_controller.dma_m_awprot;
    assign dma_vif.dma_m_awqos    = u_soc_dut.u_dma_controller.dma_m_awqos;
    assign dma_vif.dma_m_awregion = u_soc_dut.u_dma_controller.dma_m_awregion;
    assign dma_vif.dma_m_awvalid  = u_soc_dut.u_dma_controller.dma_m_awvalid;
    assign dma_vif.dma_m_awready  = u_soc_dut.u_dma_controller.dma_m_awready;
    assign dma_vif.dma_m_wdata    = u_soc_dut.u_dma_controller.dma_m_wdata;
    assign dma_vif.dma_m_wstrb    = u_soc_dut.u_dma_controller.dma_m_wstrb;
    assign dma_vif.dma_m_wlast    = u_soc_dut.u_dma_controller.dma_m_wlast;
    assign dma_vif.dma_m_wvalid   = u_soc_dut.u_dma_controller.dma_m_wvalid;
    assign dma_vif.dma_m_wready   = u_soc_dut.u_dma_controller.dma_m_wready;
    assign dma_vif.dma_m_bid      = u_soc_dut.u_dma_controller.dma_m_bid;
    assign dma_vif.dma_m_bresp    = u_soc_dut.u_dma_controller.dma_m_bresp;
    assign dma_vif.dma_m_bvalid   = u_soc_dut.u_dma_controller.dma_m_bvalid;
    assign dma_vif.dma_m_bready   = u_soc_dut.u_dma_controller.dma_m_bready;
    assign dma_vif.dma_m_arid     = u_soc_dut.u_dma_controller.dma_m_arid;
    assign dma_vif.dma_m_araddr   = u_soc_dut.u_dma_controller.dma_m_araddr;
    assign dma_vif.dma_m_arlen    = u_soc_dut.u_dma_controller.dma_m_arlen;
    assign dma_vif.dma_m_arsize   = u_soc_dut.u_dma_controller.dma_m_arsize;
    assign dma_vif.dma_m_arburst  = u_soc_dut.u_dma_controller.dma_m_arburst;
    assign dma_vif.dma_m_arlock   = u_soc_dut.u_dma_controller.dma_m_arlock;
    assign dma_vif.dma_m_arcache  = u_soc_dut.u_dma_controller.dma_m_arcache;
    assign dma_vif.dma_m_arprot   = u_soc_dut.u_dma_controller.dma_m_arprot;
    assign dma_vif.dma_m_arqos    = u_soc_dut.u_dma_controller.dma_m_arqos;
    assign dma_vif.dma_m_arregion = u_soc_dut.u_dma_controller.dma_m_arregion;
    assign dma_vif.dma_m_arvalid  = u_soc_dut.u_dma_controller.dma_m_arvalid;
    assign dma_vif.dma_m_arready  = u_soc_dut.u_dma_controller.dma_m_arready;
    assign dma_vif.dma_m_rid      = u_soc_dut.u_dma_controller.dma_m_rid;
    assign dma_vif.dma_m_rdata    = u_soc_dut.u_dma_controller.dma_m_rdata;
    assign dma_vif.dma_m_rresp    = u_soc_dut.u_dma_controller.dma_m_rresp;
    assign dma_vif.dma_m_rlast    = u_soc_dut.u_dma_controller.dma_m_rlast;
    assign dma_vif.dma_m_rvalid   = u_soc_dut.u_dma_controller.dma_m_rvalid;
    assign dma_vif.dma_m_rready   = u_soc_dut.u_dma_controller.dma_m_rready;

    assign bus_vif.uart_irq  = soc_uart_irq;
    assign bus_vif.timer_irq = soc_timer_irq;
    assign bus_vif.aes_irq   = soc_aes_irq;
    assign bus_vif.sha_irq   = soc_sha_irq;
    assign bus_vif.dma_done  = soc_dma_done;
    assign bus_vif.dma_error = soc_dma_error;
    assign bus_vif.gpio_intr = soc_gpio_intr;

    soc_top #(
        .USE_INTERNAL_CPU (0),
        .AXI_DATA_WIDTH   (32),
        .AXI_ADDR_WIDTH   (32),
        .AXI_ID_WIDTH     (8)
    ) u_soc_dut (
        .clk                 (clk),
        .uart_clk            (clk),
        .aresetn             (aresetn),
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
        .uart_rx             (soc_uart_rx),
        .uart_tx             (soc_uart_tx),
        .gpio_i              (soc_gpio_i),
        .gpio_o              (soc_gpio_o),
        .gpio_dir_o          (soc_gpio_dir_o),
        .uart_irq_o          (soc_uart_irq),
        .timer_irq_o         (soc_timer_irq),
        .aes_irq_o           (soc_aes_irq),
        .sha_irq_o           (soc_sha_irq),
        .dma_done_o          (soc_dma_done),
        .dma_error_o         (soc_dma_error),
        .gpio_intr_o         (soc_gpio_intr),
        .cpu_halt_status_o   ()
    );

    initial begin
        string test_name;
        uvm_config_db#(virtual soc_axi_if)::set(null, "*", "bus_vif", bus_vif);
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "gpio_vif", gpio_vif);
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "uart_vif", uart_vif);
        uvm_config_db#(virtual timer_vip_if)::set(null, "*", "timer_vif", timer_vif);
        uvm_config_db#(virtual sha_vip_if)::set(null, "*", "sha_vif", sha_vif);
        uvm_config_db#(virtual aes_vip_if)::set(null, "*", "aes_vif", aes_vif);
        uvm_config_db#(virtual dma_vip_if)::set(null, "*", "dma_vif", dma_vif);

        if (!$value$plusargs("UVM_TESTNAME=%s", test_name)) begin
            test_name = "uart_vip_test";
        end
        run_test(test_name);
    end

`include "soc_cov_inst.svh"
    `INST_SOC_COV(u_soc_dut, 1'b0, 1'b0, 1'b0)

endmodule : tb_periph_top

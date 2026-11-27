// =============================================================================
// File        : dma_vip_if.sv
// Description : UVM Interface for AXI DMA Controller (dma_axi_top)
// =============================================================================
`timescale 1ns/1ps

interface dma_vip_if (
    input logic clk,
    input logic aresetn
);
    logic        rst;
    logic        dma_done_o;
    logic        dma_error_o;

    // Slave CSR AXI4-Lite port (0x4000_5000)
    logic [31:0] dma_s_awaddr;
    logic [2:0]  dma_s_awprot;
    logic        dma_s_awvalid;
    logic        dma_s_awready;
    logic [31:0] dma_s_wdata;
    logic [3:0]  dma_s_wstrb;
    logic        dma_s_wvalid;
    logic        dma_s_wready;
    logic [1:0]  dma_s_bresp;
    logic        dma_s_bvalid;
    logic        dma_s_bready;
    logic [31:0] dma_s_araddr;
    logic [2:0]  dma_s_arprot;
    logic        dma_s_arvalid;
    logic        dma_s_arready;
    logic [31:0] dma_s_rdata;
    logic [1:0]  dma_s_rresp;
    logic        dma_s_rvalid;
    logic        dma_s_rready;

    // Master AXI4 port (to Interconnect s01)
    logic [7:0]  dma_m_awid;
    logic [31:0] dma_m_awaddr;
    logic [7:0]  dma_m_awlen;
    logic [2:0]  dma_m_awsize;
    logic [1:0]  dma_m_awburst;
    logic        dma_m_awlock;
    logic [3:0]  dma_m_awcache;
    logic [2:0]  dma_m_awprot;
    logic [3:0]  dma_m_awqos;
    logic [3:0]  dma_m_awregion;
    logic        dma_m_awvalid;
    logic        dma_m_awready;
    logic [31:0] dma_m_wdata;
    logic [3:0]  dma_m_wstrb;
    logic        dma_m_wlast;
    logic        dma_m_wvalid;
    logic        dma_m_wready;
    logic [7:0]  dma_m_bid;
    logic [1:0]  dma_m_bresp;
    logic        dma_m_bvalid;
    logic        dma_m_bready;
    logic [7:0]  dma_m_arid;
    logic [31:0] dma_m_araddr;
    logic [7:0]  dma_m_arlen;
    logic [2:0]  dma_m_arsize;
    logic [1:0]  dma_m_arburst;
    logic        dma_m_arlock;
    logic [3:0]  dma_m_arcache;
    logic [2:0]  dma_m_arprot;
    logic [3:0]  dma_m_arqos;
    logic [3:0]  dma_m_arregion;
    logic        dma_m_arvalid;
    logic        dma_m_arready;
    logic [7:0]  dma_m_rid;
    logic [31:0] dma_m_rdata;
    logic [1:0]  dma_m_rresp;
    logic        dma_m_rlast;
    logic        dma_m_rvalid;
    logic        dma_m_rready;
endinterface : dma_vip_if

// =============================================================================
// File        : aes_vip_if.sv
// Description : UVM Interface for AES-256 Accelerator (aes_core_top)
// =============================================================================
`timescale 1ns/1ps

interface aes_vip_if (
    input logic aclk,
    input logic aresetn
);
    logic [7:0]  s_axi_awaddr;
    logic [2:0]  s_axi_awprot;
    logic        s_axi_awvalid;
    logic        s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic [3:0]  s_axi_wstrb;
    logic        s_axi_wvalid;
    logic        s_axi_wready;
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;
    logic [7:0]  s_axi_araddr;
    logic [2:0]  s_axi_arprot;
    logic        s_axi_arvalid;
    logic        s_axi_arready;
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;
    logic        irq;
endinterface : aes_vip_if

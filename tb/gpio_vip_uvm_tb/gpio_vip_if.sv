// =============================================================================
// File        : gpio_vip_if.sv
// Description : External Interface + Passive AXI Snoop for 64-Pin GPIO VIP
// =============================================================================

`timescale 1ns/1ps

interface gpio_vip_if (
    input logic clk,
    input logic aresetn
);
    // External SoC GPIO Pins
    logic [63:0] gpio_i;        // External inputs into SoC
    logic [63:0] gpio_o;        // Outputs driven by SoC
    logic [63:0] gpio_dir_o;    // Output enables (direction) from SoC
    logic [1:0]  gpio_intr_o;   // Bank 0 and Bank 1 interrupts from SoC

    // Passive AXI4-Lite Snoop Signals (connected to u_soc_dut.u_gpio in tb_top)
    logic [11:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;
    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;
    logic [11:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;

    clocking drv_cb @(posedge clk);
        default input #1step output #100ps;
        output gpio_i;
        input  gpio_o;
        input  gpio_dir_o;
        input  gpio_intr_o;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #100ps;
        input  gpio_i;
        input  gpio_o;
        input  gpio_dir_o;
        input  gpio_intr_o;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input aresetn, output gpio_i);
    modport mon_mp (clocking mon_cb, input clk, input aresetn, input gpio_i, input gpio_o, input gpio_dir_o, input gpio_intr_o);

endinterface : gpio_vip_if

// =============================================================================
// File        : uart_vip_if.sv
// Description : External Interface + Passive AXI Snoop for UART VIP
// =============================================================================

`timescale 1ns/1ps

interface uart_vip_if (
    input logic clk,
    input logic aresetn
);
    // External SoC UART Pins
    logic uart_rx = 1'b1;      // Serial data into SoC
    logic uart_tx;             // Serial data from SoC
    logic uart_irq;            // UART Interrupt from SoC

    // Passive AXI4-Lite Snoop Signals (connected to u_soc_dut.u_uart in tb_top)
    logic [7:0]  axi_awaddr;
    logic        axi_awvalid;
    logic        axi_awready;
    logic [31:0] axi_wdata;
    logic [3:0]  axi_wstrb;
    logic        axi_wvalid;
    logic        axi_wready;
    logic [1:0]  axi_bresp;
    logic        axi_bvalid;
    logic        axi_bready;
    logic [7:0]  axi_araddr;
    logic        axi_arvalid;
    logic        axi_arready;
    logic [31:0] axi_rdata;
    logic [1:0]  axi_rresp;
    logic        axi_rvalid;
    logic        axi_rready;

    clocking drv_cb @(posedge clk);
        default input #1step output #100ps;
        output uart_rx;
        input  uart_tx;
        input  uart_irq;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step output #100ps;
        input  uart_rx;
        input  uart_tx;
        input  uart_irq;
    endclocking

    modport drv_mp (clocking drv_cb, input clk, input aresetn, output uart_rx);
    modport mon_mp (clocking mon_cb, input clk, input aresetn, input uart_rx, input uart_tx, input uart_irq);

endinterface : uart_vip_if

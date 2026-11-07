// =============================================================================
// File        : uart_vip_if.sv
// Description : External Interface for UART VIP
//               Interfaces strictly with external SoC boundary pins:
//                 - uart_rx  (driven by VIP into SoC)
//                 - uart_tx  (sampled by VIP from SoC)
//                 - uart_irq (interrupt observed from SoC)
// =============================================================================

`timescale 1ns/1ps

interface uart_vip_if (
    input logic clk,
    input logic aresetn
);
    // -------------------------------------------------------------------------
    // External SoC UART Pins
    // -------------------------------------------------------------------------
    logic uart_rx;      // Serial data into SoC
    logic uart_tx;      // Serial data from SoC
    logic uart_irq;     // UART Interrupt from SoC

    // -------------------------------------------------------------------------
    // Driver Clocking Block (drives uart_rx into SoC)
    // -------------------------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1step output #100ps;
        output uart_rx;
        input  uart_tx;
        input  uart_irq;
    endclocking

    // -------------------------------------------------------------------------
    // Monitor Clocking Block (passively samples uart_tx and uart_rx)
    // -------------------------------------------------------------------------
    clocking mon_cb @(posedge clk);
        default input #1step output #100ps;
        input  uart_rx;
        input  uart_tx;
        input  uart_irq;
    endclocking

    // Modports
    modport drv_mp (clocking drv_cb, input clk, input aresetn, output uart_rx);
    modport mon_mp (clocking mon_cb, input clk, input aresetn, input uart_rx, input uart_tx, input uart_irq);

endinterface : uart_vip_if

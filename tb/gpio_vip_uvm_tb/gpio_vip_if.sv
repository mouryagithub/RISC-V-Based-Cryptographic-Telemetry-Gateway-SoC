// =============================================================================
// File        : gpio_vip_if.sv
// Description : External Interface for 64-Pin GPIO VIP
//               Interfaces strictly with external SoC boundary pins:
//                 - gpio_i[63:0]      (driven by VIP into SoC)
//                 - gpio_o[63:0]      (sampled by VIP from SoC)
//                 - gpio_dir_o[63:0]  (sampled by VIP from SoC)
//                 - gpio_intr_o[1:0]  (sampled by VIP from SoC)
// =============================================================================

`timescale 1ns/1ps

interface gpio_vip_if (
    input logic clk,
    input logic aresetn
);
    // -------------------------------------------------------------------------
    // External SoC GPIO Pins
    // -------------------------------------------------------------------------
    logic [63:0] gpio_i;        // External inputs into SoC
    logic [63:0] gpio_o;        // Outputs driven by SoC
    logic [63:0] gpio_dir_o;    // Output enables (direction) from SoC
    logic [1:0]  gpio_intr_o;   // Bank 0 and Bank 1 interrupts from SoC

    // -------------------------------------------------------------------------
    // Driver Clocking Block (drives gpio_i into SoC)
    // -------------------------------------------------------------------------
    clocking drv_cb @(posedge clk);
        default input #1step output #100ps;
        output gpio_i;
        input  gpio_o;
        input  gpio_dir_o;
        input  gpio_intr_o;
    endclocking

    // -------------------------------------------------------------------------
    // Monitor Clocking Block (passively samples all external pins)
    // -------------------------------------------------------------------------
    clocking mon_cb @(posedge clk);
        default input #1step output #100ps;
        input  gpio_i;
        input  gpio_o;
        input  gpio_dir_o;
        input  gpio_intr_o;
    endclocking

    // Modports
    modport drv_mp (clocking drv_cb, input clk, input aresetn, output gpio_i);
    modport mon_mp (clocking mon_cb, input clk, input aresetn, input gpio_i, input gpio_o, input gpio_dir_o, input gpio_intr_o);

endinterface : gpio_vip_if

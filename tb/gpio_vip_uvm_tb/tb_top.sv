// =============================================================================
// File        : tb_top.sv (GPIO VIP Testbench Top)
// Module      : tb_top
// Description : UVM Top-level testbench for GPIO VIP environment.
//               Instantiates axi_gpio_top DUT, drives clocks & reset,
//               binds gpio_vip_if, registers vif in uvm_config_db,
//               dumps VCD/FSDB waveforms, and executes UVM test.
// =============================================================================

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import gpio_vip_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters & Clock Configuration
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD = 20; // 50 MHz primary clock (20 ns period)

    logic aclk;
    logic aresetn;

    // Clock generation (50 MHz)
    initial begin
        aclk = 1'b0;
        forever #(CLK_PERIOD / 2) aclk = ~aclk;
    end

    // Reset generation (Active-LOW reset held for 10 cycles)
    initial begin
        aresetn = 1'b0;
        repeat (10) @(posedge aclk);
        aresetn = 1'b1;
    end

    // -------------------------------------------------------------------------
    // VIP Virtual Interface Instance
    // -------------------------------------------------------------------------
    gpio_vip_if vif();

    // Connect clock and reset
    assign vif.clk     = aclk;
    assign vif.aclk    = aclk;
    assign vif.aresetn = aresetn;

    // -------------------------------------------------------------------------
    // DUT: axi_gpio_top (64-Pin GPIO Controller with AXI4-Lite Interface)
    // -------------------------------------------------------------------------
    axi_gpio_top #(
        .AXI_ADDR_WIDTH (12),
        .AXI_DATA_WIDTH (32)
    ) u_gpio_dut (
        // Clock & Reset
        .aclk          (vif.aclk),
        .aresetn       (vif.aresetn),

        // AXI4-Lite Write Address Channel
        .s_axi_awaddr  (vif.s_axi_awaddr),
        .s_axi_awprot  (vif.s_axi_awprot),
        .s_axi_awvalid (vif.s_axi_awvalid),
        .s_axi_awready (vif.s_axi_awready),

        // AXI4-Lite Write Data Channel
        .s_axi_wdata   (vif.s_axi_wdata),
        .s_axi_wstrb   (vif.s_axi_wstrb),
        .s_axi_wvalid  (vif.s_axi_wvalid),
        .s_axi_wready  (vif.s_axi_wready),

        // AXI4-Lite Write Response Channel
        .s_axi_bresp   (vif.s_axi_bresp),
        .s_axi_bvalid  (vif.s_axi_bvalid),
        .s_axi_bready  (vif.s_axi_bready),

        // AXI4-Lite Read Address Channel
        .s_axi_araddr  (vif.s_axi_araddr),
        .s_axi_arprot  (vif.s_axi_arprot),
        .s_axi_arvalid (vif.s_axi_arvalid),
        .s_axi_arready (vif.s_axi_arready),

        // AXI4-Lite Read Data Channel
        .s_axi_rdata   (vif.s_axi_rdata),
        .s_axi_rresp   (vif.s_axi_rresp),
        .s_axi_rvalid  (vif.s_axi_rvalid),
        .s_axi_rready  (vif.s_axi_rready),

        // External 64-Pin GPIO Lines
        .gpio_i        (vif.gpio_i),
        .gpio_o        (vif.gpio_o),
        .gpio_dir_o    (vif.gpio_dir_o),

        // Interrupt Outputs
        .gpio_intr_o   (vif.gpio_intr_o)
    );

    // -------------------------------------------------------------------------
    // Test Control, Waveform Dumping & UVM Execution
    // -------------------------------------------------------------------------
    initial begin
        // Set virtual interface handle in UVM configuration database
        uvm_config_db#(virtual gpio_vip_if)::set(null, "*", "vif", vif);

        // Standard VCD dumping
        $dumpfile("gpio_vip_tb.vcd");
        $dumpvars(0, tb_top);

        // Verdi FSDB dumping
`ifdef FSDB
        $fsdbDumpfile("gpio_vip_tb.fsdb");
        $fsdbDumpvars(0, tb_top, "+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
`endif

        $display("=============================================================");
        $display(" [TB_TOP] Starting GPIO VIP UVM Verification Testbench");
        $display(" [TB_TOP] DUT: axi_gpio_top | Interface: gpio_vip_if");
        $display("=============================================================");

        // Run UVM test
        run_test("gpio_vip_test");
    end

    // Simulation watchdog
    initial begin
        #10_000_000;
        $display("[TB_TOP] Simulation completed.");
        $finish;
    end

endmodule

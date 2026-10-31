// =============================================================================
// File        : tb_top.sv (UART VIP Testbench Top)
// Module      : tb_top
// Description : UVM Top-level testbench for UART VIP environment.
//               Instantiates axi_uart_top DUT, generates dual clock domains
//               (50 MHz AXI bus clock + 50 MHz fixed baud clock) and reset,
//               binds uart_vip_if, registers vif in uvm_config_db,
//               dumps VCD/FSDB waveforms, and executes UVM test.
// =============================================================================

`timescale 1ns/1ps

module tb_top;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    import uart_vip_pkg::*;

    // -------------------------------------------------------------------------
    // Parameters & Clock Configuration
    // -------------------------------------------------------------------------
    localparam AXI_CLK_PERIOD   = 20; // 50 MHz AXI bus clock (20 ns)
    localparam FIXED_CLK_PERIOD = 20; // 50 MHz UART baud reference clock

    logic axi_aclk;
    logic fixed_clk;
    logic axi_aresetn;

    // AXI Bus Clock (50 MHz)
    initial begin
        axi_aclk = 1'b0;
        forever #(AXI_CLK_PERIOD / 2) axi_aclk = ~axi_aclk;
    end

    // Fixed Baud Clock (50 MHz)
    initial begin
        fixed_clk = 1'b0;
        forever #(FIXED_CLK_PERIOD / 2) fixed_clk = ~fixed_clk;
    end

    // Reset Generation (Active-LOW reset held for 10 cycles)
    initial begin
        axi_aresetn = 1'b0;
        repeat (10) @(posedge axi_aclk);
        axi_aresetn = 1'b1;
    end

    // -------------------------------------------------------------------------
    // VIP Virtual Interface Instance
    // -------------------------------------------------------------------------
    uart_vip_if vif();

    // Connect clocks and reset
    assign vif.clk          = axi_aclk;
    assign vif.axi_aclk_i   = axi_aclk;
    assign vif.fixed_clk_i  = fixed_clk;
    assign vif.axi_aresetn_i= axi_aresetn;

    // -------------------------------------------------------------------------
    // DUT: axi_uart_top (16550 Compatible AXI4-Lite UART Controller)
    // -------------------------------------------------------------------------
    axi_uart_top u_uart_dut (
        // Clocks & Reset
        .fixed_clk_i      (vif.fixed_clk_i),
        .axi_aclk_i       (vif.axi_aclk_i),
        .axi_aresetn_i    (vif.axi_aresetn_i),

        // AXI4-Lite Read Address Channel
        .axi_arid_i       (vif.axi_arid_i),
        .axi_araddr_i     (vif.axi_araddr_i),
        .axi_arvalid_i    (vif.axi_arvalid_i),
        .axi_arready_o    (vif.axi_arready_o),

        // AXI4-Lite Read Data Channel
        .axi_rid_o        (vif.axi_rid_o),
        .axi_rdata_o      (vif.axi_rdata_o),
        .axi_rresp_o      (vif.axi_rresp_o),
        .axi_rvalid_o     (vif.axi_rvalid_o),
        .axi_rready_i     (vif.axi_rready_i),

        // AXI4-Lite Write Address Channel
        .axi_awid_i       (vif.axi_awid_i),
        .axi_awaddr_i     (vif.axi_awaddr_i),
        .axi_awvalid_i    (vif.axi_awvalid_i),
        .axi_awready_o    (vif.axi_awready_o),

        // AXI4-Lite Write Data Channel
        .axi_wdata_i      (vif.axi_wdata_i),
        .axi_wstrb_i      (vif.axi_wstrb_i),
        .axi_wvalid_i     (vif.axi_wvalid_i),
        .axi_wready_o     (vif.axi_wready_o),

        // AXI4-Lite Write Response Channel
        .axi_bid_o        (vif.axi_bid_o),
        .axi_bresp_o      (vif.axi_bresp_o),
        .axi_bvalid_o     (vif.axi_bvalid_o),
        .axi_bready_i     (vif.axi_bready_i),

        // Serial Interfaces & Interrupt
        .uart_rx_i        (vif.uart_rx_i),
        .uart_tx_o        (vif.uart_tx_o),
        .read_interrupt_o (vif.read_interrupt_o)
    );

    // -------------------------------------------------------------------------
    // Test Control, Waveform Dumping & UVM Execution
    // -------------------------------------------------------------------------
    initial begin
        // Set virtual interface handle in UVM configuration database
        uvm_config_db#(virtual uart_vip_if)::set(null, "*", "vif", vif);

        // Standard VCD dumping
        $dumpfile("uart_vip_tb.vcd");
        $dumpvars(0, tb_top);

        // Verdi FSDB dumping
`ifdef FSDB
        $fsdbDumpfile("uart_vip_tb.fsdb");
        $fsdbDumpvars(0, tb_top, "+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
`endif

        $display("=============================================================");
        $display(" [TB_TOP] Starting UART VIP UVM Verification Testbench");
        $display(" [TB_TOP] DUT: axi_uart_top | Interface: uart_vip_if");
        $display("=============================================================");

        // Run UVM test
        run_test("uart_vip_test");
    end

    // Simulation watchdog
    initial begin
        #10_000_000;
        $display("[TB_TOP] Simulation completed.");
        $finish;
    end

endmodule

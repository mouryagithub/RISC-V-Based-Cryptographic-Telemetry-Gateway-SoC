// =============================================================================
// File        : veer_core_top.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Self-contained VeeR-EL2 CPU core subsystem top-level.
//               Instantiates:
//                 1. el2_veer_wrapper (RV32IMC Dual-Issue Core + PIC + Timers)
//                 2. el2_mem_if interface
//                 3. DCCM SRAM array (4 banks x 4096 x 39-bit)
//                 4. ICCM SRAM array (4 banks x 4096 x 39-bit)
//                 5. ICache Data SRAM array (2 banks x 512 x 142-bit)
//                 6. ICache Tag SRAM array (1 array x 128 x 52-bit)
//                 7. Boot Instruction Memory (axi_slv on IFU AXI bus, optional)
//
//               Exposes standard SoC buses:
//                 - 64-bit LSU AXI4 Master (connected to SoC Interconnect S00)
//                 - 64-bit IFU AXI4 Master
//                 - 31-line PIC External Interrupt vector (extintsrc_req)
//                 - Standard clock, reset, debug & status ports
// =============================================================================

`default_nettype none

`include "common_defines.vh"

module veer_core_top
  import el2_pkg::*;
#(
    parameter bit BOOT_IMEM_ENABLE = 1,
    `include "el2_param.vh"
)(
    input  logic                      clk,
    input  logic                      rst_l,
    input  logic                      dbg_rst_l,
    input  logic [31:1]               rst_vec,
    input  logic                      nmi_int,
    input  logic [31:1]               nmi_vec,
    input  logic [31:1]               jtag_id,

    // -------------------------------------------------------------------------
    // LSU AXI4 Master Interface (connected to SoC Interconnect S00)
    // -------------------------------------------------------------------------
    output logic                      lsu_axi_awvalid,
    input  logic                      lsu_axi_awready,
    output logic [pt.LSU_BUS_TAG-1:0] lsu_axi_awid,
    output logic [31:0]               lsu_axi_awaddr,
    output logic [3:0]                lsu_axi_awregion,
    output logic [7:0]                lsu_axi_awlen,
    output logic [2:0]                lsu_axi_awsize,
    output logic [1:0]                lsu_axi_awburst,
    output logic                      lsu_axi_awlock,
    output logic [3:0]                lsu_axi_awcache,
    output logic [2:0]                lsu_axi_awprot,
    output logic [3:0]                lsu_axi_awqos,

    output logic                      lsu_axi_wvalid,
    input  logic                      lsu_axi_wready,
    output logic [63:0]               lsu_axi_wdata,
    output logic [7:0]                lsu_axi_wstrb,
    output logic                      lsu_axi_wlast,

    input  logic                      lsu_axi_bvalid,
    output logic                      lsu_axi_bready,
    input  logic [1:0]                lsu_axi_bresp,
    input  logic [pt.LSU_BUS_TAG-1:0] lsu_axi_bid,

    output logic                      lsu_axi_arvalid,
    input  logic                      lsu_axi_arready,
    output logic [pt.LSU_BUS_TAG-1:0] lsu_axi_arid,
    output logic [31:0]               lsu_axi_araddr,
    output logic [3:0]                lsu_axi_arregion,
    output logic [7:0]                lsu_axi_arlen,
    output logic [2:0]                lsu_axi_arsize,
    output logic [1:0]                lsu_axi_arburst,
    output logic                      lsu_axi_arlock,
    output logic [3:0]                lsu_axi_arcache,
    output logic [2:0]                lsu_axi_arprot,
    output logic [3:0]                lsu_axi_arqos,

    input  logic                      lsu_axi_rvalid,
    output logic                      lsu_axi_rready,
    input  logic [pt.LSU_BUS_TAG-1:0] lsu_axi_rid,
    input  logic [63:0]               lsu_axi_rdata,
    input  logic [1:0]                lsu_axi_rresp,
    input  logic                      lsu_axi_rlast,

    // -------------------------------------------------------------------------
    // IFU AXI4 Master Interface (Instruction Fetch from external ROM/RAM)
    // -------------------------------------------------------------------------
    output logic                      ifu_axi_awvalid,
    input  logic                      ifu_axi_awready,
    output logic [pt.IFU_BUS_TAG-1:0] ifu_axi_awid,
    output logic [31:0]               ifu_axi_awaddr,
    output logic [3:0]                ifu_axi_awregion,
    output logic [7:0]                ifu_axi_awlen,
    output logic [2:0]                ifu_axi_awsize,
    output logic [1:0]                ifu_axi_awburst,
    output logic                      ifu_axi_awlock,
    output logic [3:0]                ifu_axi_awcache,
    output logic [2:0]                ifu_axi_awprot,
    output logic [3:0]                ifu_axi_awqos,

    output logic                      ifu_axi_wvalid,
    input  logic                      ifu_axi_wready,
    output logic [63:0]               ifu_axi_wdata,
    output logic [7:0]                ifu_axi_wstrb,
    output logic                      ifu_axi_wlast,

    input  logic                      ifu_axi_bvalid,
    output logic                      ifu_axi_bready,
    input  logic [1:0]                ifu_axi_bresp,
    input  logic [pt.IFU_BUS_TAG-1:0] ifu_axi_bid,

    output logic                      ifu_axi_arvalid,
    input  logic                      ifu_axi_arready,
    output logic [pt.IFU_BUS_TAG-1:0] ifu_axi_arid,
    output logic [31:0]               ifu_axi_araddr,
    output logic [3:0]                ifu_axi_arregion,
    output logic [7:0]                ifu_axi_arlen,
    output logic [2:0]                ifu_axi_arsize,
    output logic [1:0]                ifu_axi_arburst,
    output logic                      ifu_axi_arlock,
    output logic [3:0]                ifu_axi_arcache,
    output logic [2:0]                ifu_axi_arprot,
    output logic [3:0]                ifu_axi_arqos,

    input  logic                      ifu_axi_rvalid,
    output logic                      ifu_axi_rready,
    input  logic [pt.IFU_BUS_TAG-1:0] ifu_axi_rid,
    input  logic [63:0]               ifu_axi_rdata,
    input  logic [1:0]                ifu_axi_rresp,
    input  logic                      ifu_axi_rlast,

    // -------------------------------------------------------------------------
    // Interrupt Lines to VeeR PIC Gateway
    // -------------------------------------------------------------------------
    input  logic                      timer_int,
    input  logic                      soft_int,
    input  logic [pt.PIC_TOTAL_INT:1] extintsrc_req,

    // -------------------------------------------------------------------------
    // Core Status / Debug Interface
    // -------------------------------------------------------------------------
    output logic                      o_cpu_halt_status,
    output logic                      o_cpu_halt_ack,
    output logic                      o_cpu_run_ack,
    output logic                      o_debug_mode_status,
    input  logic                      i_cpu_halt_req,
    input  logic                      i_cpu_run_req,

    // JTAG TAP Controller
    input  logic                      jtag_tck,
    input  logic                      jtag_tms,
    input  logic                      jtag_tdi,
    input  logic                      jtag_trst_n,
    output logic                      jtag_tdo,
    output logic                      jtag_tdoEn
);

    // =========================================================================
    // Internal Memory Export Interface Instance
    // =========================================================================
    el2_mem_if mem_export();

    // =========================================================================
    // DCCM SRAM Bank Instantiation (4 banks x 4096 words x 39 bits)
    // =========================================================================
    for (genvar i = 0; i < pt.DCCM_NUM_BANKS; i++) begin : gen_dccm_mem
        ram_4096x39 dccm_bank (
            .CLK      (mem_export.clk),
            .ME       (mem_export.dccm_clken[i]),
            .WE       (mem_export.dccm_wren_bank[i]),
            .ADR      (mem_export.dccm_addr_bank[i]),
            .D        ({mem_export.dccm_wr_ecc_bank[i], mem_export.dccm_wr_data_bank[i]}),
            .Q        ({mem_export.dccm_bank_ecc[i], mem_export.dccm_bank_dout[i]}),
            .ROP      (),
            .TEST1    (1'b0),
            .RME      (1'b0),
            .RM       (4'b0000),
            .LS       (1'b0),
            .DS       (1'b0),
            .SD       (1'b0),
            .TEST_RNM (1'b0),
            .BC1      (1'b0),
            .BC2      (1'b0)
        );
    end

    // =========================================================================
    // ICCM SRAM Bank Instantiation (4 banks x 4096 words x 39 bits)
    // =========================================================================
    for (genvar i = 0; i < pt.ICCM_NUM_BANKS; i++) begin : gen_iccm_mem
        ram_4096x39 iccm_bank (
            .CLK      (mem_export.clk),
            .ME       (mem_export.iccm_clken[i]),
            .WE       (mem_export.iccm_wren_bank[i]),
            .ADR      (mem_export.iccm_addr_bank[i]),
            .D        ({mem_export.iccm_bank_wr_ecc[i], mem_export.iccm_bank_wr_data[i]}),
            .Q        ({mem_export.iccm_bank_ecc[i], mem_export.iccm_bank_dout[i]}),
            .ROP      (),
            .TEST1    (1'b0),
            .RME      (1'b0),
            .RM       (4'b0000),
            .LS       (1'b0),
            .DS       (1'b0),
            .SD       (1'b0),
            .TEST_RNM (1'b0),
            .BC1      (1'b0),
            .BC2      (1'b0)
        );
    end

    // =========================================================================
    // ICache Data & Tag SRAM Arrays (Packed configuration)
    // =========================================================================
    assign mem_export.ic_tag_data_raw_pre = '0;
    assign mem_export.wb_dout_pre_up      = '0;

    // 2 Sub-banks, 512 depth x 142 width (64b data + 7b ECC x 2 ways)
    for (genvar k = 0; k < pt.ICACHE_BANKS_WAY; k++) begin : gen_icache_data
        ram_be_512x142 ic_bank_sb_way_data (
            .CLK      (mem_export.clk),
            .ME       (|mem_export.ic_bank_way_clken_final[k]),
            .WE       (|mem_export.ic_b_sb_wren[k]),
            .WEM      (mem_export.ic_b_sb_bit_en_vec[k]),
            .D        ({pt.ICACHE_NUM_WAYS{mem_export.ic_sb_wr_data[k][70:0]}}),
            .ADR      (mem_export.ic_rw_addr_bank_q[k][pt.ICACHE_INDEX_HI:pt.ICACHE_DATA_INDEX_LO]),
            .Q        (mem_export.wb_packeddout_pre[k]),
            .ROP      (),
            .TEST1    (1'b0),
            .RME      (1'b0),
            .RM       (4'b0000),
            .LS       (1'b0),
            .DS       (1'b0),
            .SD       (1'b0),
            .TEST_RNM (1'b0),
            .BC1      (1'b0),
            .BC2      (1'b0)
        );
    end

    // Tag Array: 128 depth x 52 width (26b tag x 2 ways)
    ram_be_128x52 ic_way_tag (
        .CLK      (mem_export.clk),
        .ME       (|mem_export.ic_tag_clken_final),
        .WE       (|mem_export.ic_tag_wren_q[pt.ICACHE_NUM_WAYS-1:0]),
        .WEM      (mem_export.ic_tag_wren_biten_vec[51:0]),
        .D        ({pt.ICACHE_NUM_WAYS{mem_export.ic_tag_wr_data[25:0]}}),
        .ADR      (mem_export.ic_rw_addr_q[pt.ICACHE_INDEX_HI:pt.ICACHE_TAG_INDEX_LO]),
        .Q        (mem_export.ic_tag_data_raw_packed_pre[51:0]),
        .ROP      (),
        .TEST1    (1'b0),
        .RME      (1'b0),
        .RM       (4'b0000),
        .LS       (1'b0),
        .DS       (1'b0),
        .SD       (1'b0),
        .TEST_RNM (1'b0),
        .BC1      (1'b0),
        .BC2      (1'b0)
    );

    // =========================================================================
    // Core IFU AXI Internal Signals
    // =========================================================================
    logic                      core_ifu_arvalid;
    logic                      core_ifu_arready;
    logic [pt.IFU_BUS_TAG-1:0] core_ifu_arid;
    logic [              31:0] core_ifu_araddr;
    logic [               3:0] core_ifu_arregion;
    logic [               7:0] core_ifu_arlen;
    logic [               2:0] core_ifu_arsize;
    logic [               1:0] core_ifu_arburst;
    logic                      core_ifu_arlock;
    logic [               3:0] core_ifu_arcache;
    logic [               2:0] core_ifu_arprot;
    logic [               3:0] core_ifu_arqos;

    logic                      core_ifu_rvalid;
    logic                      core_ifu_rready;
    logic [pt.IFU_BUS_TAG-1:0] core_ifu_rid;
    logic [              63:0] core_ifu_rdata;
    logic [               1:0] core_ifu_rresp;
    logic                      core_ifu_rlast;

    generate
        if (BOOT_IMEM_ENABLE) begin : gen_boot_imem
            axi_slv #(.TAGW(pt.IFU_BUS_TAG)) imem (
                .aclk    (clk),
                .rst_l   (rst_l),
                .arvalid (core_ifu_arvalid),
                .arready (core_ifu_arready),
                .araddr  (core_ifu_araddr),
                .arid    (core_ifu_arid),
                .arlen   (core_ifu_arlen),
                .arburst (core_ifu_arburst),
                .arsize  (core_ifu_arsize),

                .rvalid  (core_ifu_rvalid),
                .rready  (core_ifu_rready),
                .rdata   (core_ifu_rdata),
                .rresp   (core_ifu_rresp),
                .rid     (core_ifu_rid),
                .rlast   (core_ifu_rlast),

                .awvalid (1'b0),
                .awready (),
                .awaddr  ('0),
                .awid    ('0),
                .awlen   ('0),
                .awburst ('0),
                .awsize  ('0),

                .wdata   ('0),
                .wstrb   ('0),
                .wvalid  (1'b0),
                .wready  (),

                .bvalid  (),
                .bready  (1'b0),
                .bresp   (),
                .bid     ()
            );

            // Output monitoring signals
            assign ifu_axi_awvalid  = 1'b0;
            assign ifu_axi_awid     = '0;
            assign ifu_axi_awaddr   = '0;
            assign ifu_axi_awregion = '0;
            assign ifu_axi_awlen    = '0;
            assign ifu_axi_awsize   = '0;
            assign ifu_axi_awburst  = '0;
            assign ifu_axi_awlock   = 1'b0;
            assign ifu_axi_awcache  = '0;
            assign ifu_axi_awprot   = '0;
            assign ifu_axi_awqos    = '0;
            assign ifu_axi_wvalid   = 1'b0;
            assign ifu_axi_wdata    = '0;
            assign ifu_axi_wstrb    = '0;
            assign ifu_axi_wlast    = 1'b0;
            assign ifu_axi_bready   = 1'b0;

            assign ifu_axi_arvalid  = core_ifu_arvalid;
            assign ifu_axi_arid     = core_ifu_arid;
            assign ifu_axi_araddr   = core_ifu_araddr;
            assign ifu_axi_arregion = core_ifu_arregion;
            assign ifu_axi_arlen    = core_ifu_arlen;
            assign ifu_axi_arsize   = core_ifu_arsize;
            assign ifu_axi_arburst  = core_ifu_arburst;
            assign ifu_axi_arlock   = core_ifu_arlock;
            assign ifu_axi_arcache  = core_ifu_arcache;
            assign ifu_axi_arprot   = core_ifu_arprot;
            assign ifu_axi_arqos    = core_ifu_arqos;
            assign ifu_axi_rready   = core_ifu_rready;
        end else begin : gen_ext_ifu
            assign ifu_axi_awvalid  = 1'b0;
            assign ifu_axi_awid     = '0;
            assign ifu_axi_awaddr   = '0;
            assign ifu_axi_awregion = '0;
            assign ifu_axi_awlen    = '0;
            assign ifu_axi_awsize   = '0;
            assign ifu_axi_awburst  = '0;
            assign ifu_axi_awlock   = 1'b0;
            assign ifu_axi_awcache  = '0;
            assign ifu_axi_awprot   = '0;
            assign ifu_axi_awqos    = '0;
            assign ifu_axi_wvalid   = 1'b0;
            assign ifu_axi_wdata    = '0;
            assign ifu_axi_wstrb    = '0;
            assign ifu_axi_wlast    = 1'b0;
            assign ifu_axi_bready   = 1'b0;

            assign ifu_axi_arvalid  = core_ifu_arvalid;
            assign ifu_axi_arid     = core_ifu_arid;
            assign ifu_axi_araddr   = core_ifu_araddr;
            assign ifu_axi_arregion = core_ifu_arregion;
            assign ifu_axi_arlen    = core_ifu_arlen;
            assign ifu_axi_arsize   = core_ifu_arsize;
            assign ifu_axi_arburst  = core_ifu_arburst;
            assign ifu_axi_arlock   = core_ifu_arlock;
            assign ifu_axi_arcache  = core_ifu_arcache;
            assign ifu_axi_arprot   = core_ifu_arprot;
            assign ifu_axi_arqos    = core_ifu_arqos;
            assign ifu_axi_rready   = core_ifu_rready;

            assign core_ifu_arready = ifu_axi_arready;
            assign core_ifu_rvalid  = ifu_axi_rvalid;
            assign core_ifu_rdata   = ifu_axi_rdata;
            assign core_ifu_rresp   = ifu_axi_rresp;
            assign core_ifu_rid     = ifu_axi_rid;
            assign core_ifu_rlast   = ifu_axi_rlast;
        end
    endgenerate

    // =========================================================================
    // Core Instance: el2_veer_wrapper
    // =========================================================================
    el2_veer_wrapper #(.pt(pt)) rvtop (
        .clk                     (clk),
        .rst_l                   (rst_l),
        .dbg_rst_l               (dbg_rst_l),
        .rst_vec                 (rst_vec),
        .nmi_int                 (nmi_int),
        .nmi_vec                 (nmi_vec),
        .jtag_id                 (jtag_id),

        .trace_rv_i_insn_ip      (),
        .trace_rv_i_address_ip   (),
        .trace_rv_i_valid_ip     (),
        .trace_rv_i_exception_ip (),
        .trace_rv_i_ecause_ip    (),
        .trace_rv_i_interrupt_ip (),
        .trace_rv_i_tval_ip      (),

        // LSU AXI4 Master
        .lsu_axi_awvalid         (lsu_axi_awvalid),
        .lsu_axi_awready         (lsu_axi_awready),
        .lsu_axi_awid            (lsu_axi_awid),
        .lsu_axi_awaddr          (lsu_axi_awaddr),
        .lsu_axi_awregion        (lsu_axi_awregion),
        .lsu_axi_awlen           (lsu_axi_awlen),
        .lsu_axi_awsize          (lsu_axi_awsize),
        .lsu_axi_awburst         (lsu_axi_awburst),
        .lsu_axi_awlock          (lsu_axi_awlock),
        .lsu_axi_awcache         (lsu_axi_awcache),
        .lsu_axi_awprot          (lsu_axi_awprot),
        .lsu_axi_awqos           (lsu_axi_awqos),
        .lsu_axi_wvalid          (lsu_axi_wvalid),
        .lsu_axi_wready          (lsu_axi_wready),
        .lsu_axi_wdata           (lsu_axi_wdata),
        .lsu_axi_wstrb           (lsu_axi_wstrb),
        .lsu_axi_wlast           (lsu_axi_wlast),
        .lsu_axi_bvalid          (lsu_axi_bvalid),
        .lsu_axi_bready          (lsu_axi_bready),
        .lsu_axi_bresp           (lsu_axi_bresp),
        .lsu_axi_bid             (lsu_axi_bid),
        .lsu_axi_arvalid         (lsu_axi_arvalid),
        .lsu_axi_arready         (lsu_axi_arready),
        .lsu_axi_arid            (lsu_axi_arid),
        .lsu_axi_araddr          (lsu_axi_araddr),
        .lsu_axi_arregion        (lsu_axi_arregion),
        .lsu_axi_arlen           (lsu_axi_arlen),
        .lsu_axi_arsize          (lsu_axi_arsize),
        .lsu_axi_arburst         (lsu_axi_arburst),
        .lsu_axi_arlock          (lsu_axi_arlock),
        .lsu_axi_arcache         (lsu_axi_arcache),
        .lsu_axi_arprot          (lsu_axi_arprot),
        .lsu_axi_arqos           (lsu_axi_arqos),
        .lsu_axi_rvalid          (lsu_axi_rvalid),
        .lsu_axi_rready          (lsu_axi_rready),
        .lsu_axi_rid             (lsu_axi_rid),
        .lsu_axi_rdata           (lsu_axi_rdata),
        .lsu_axi_rresp           (lsu_axi_rresp),
        .lsu_axi_rlast           (lsu_axi_rlast),

        // IFU AXI4 Master
        .ifu_axi_awvalid         (),
        .ifu_axi_awready         (1'b0),
        .ifu_axi_awid            (),
        .ifu_axi_awaddr          (),
        .ifu_axi_awregion        (),
        .ifu_axi_awlen           (),
        .ifu_axi_awsize          (),
        .ifu_axi_awburst         (),
        .ifu_axi_awlock          (),
        .ifu_axi_awcache         (),
        .ifu_axi_awprot          (),
        .ifu_axi_awqos           (),
        .ifu_axi_wvalid          (),
        .ifu_axi_wready          (1'b0),
        .ifu_axi_wdata           (),
        .ifu_axi_wstrb           (),
        .ifu_axi_wlast           (),
        .ifu_axi_bvalid          (1'b0),
        .ifu_axi_bready          (),
        .ifu_axi_bresp           (2'b00),
        .ifu_axi_bid             ('0),
        .ifu_axi_arvalid         (core_ifu_arvalid),
        .ifu_axi_arready         (core_ifu_arready),
        .ifu_axi_arid            (core_ifu_arid),
        .ifu_axi_araddr          (core_ifu_araddr),
        .ifu_axi_arregion        (core_ifu_arregion),
        .ifu_axi_arlen           (core_ifu_arlen),
        .ifu_axi_arsize          (core_ifu_arsize),
        .ifu_axi_arburst         (core_ifu_arburst),
        .ifu_axi_arlock          (core_ifu_arlock),
        .ifu_axi_arcache         (core_ifu_arcache),
        .ifu_axi_arprot          (core_ifu_arprot),
        .ifu_axi_arqos           (core_ifu_arqos),
        .ifu_axi_rvalid          (core_ifu_rvalid),
        .ifu_axi_rready          (core_ifu_rready),
        .ifu_axi_rid             (core_ifu_rid),
        .ifu_axi_rdata           (core_ifu_rdata),
        .ifu_axi_rresp           (core_ifu_rresp),
        .ifu_axi_rlast           (core_ifu_rlast),

        // SB AXI (Sideband system bus - tied off)
        .sb_axi_awvalid          (),
        .sb_axi_awready          (1'b0),
        .sb_axi_awid             (),
        .sb_axi_awaddr           (),
        .sb_axi_awregion         (),
        .sb_axi_awlen            (),
        .sb_axi_awsize           (),
        .sb_axi_awburst          (),
        .sb_axi_awlock           (),
        .sb_axi_awcache          (),
        .sb_axi_awprot           (),
        .sb_axi_awqos            (),
        .sb_axi_wvalid           (),
        .sb_axi_wready           (1'b0),
        .sb_axi_wdata            (),
        .sb_axi_wstrb            (),
        .sb_axi_wlast            (),
        .sb_axi_bvalid           (1'b0),
        .sb_axi_bready           (),
        .sb_axi_bresp            (2'b00),
        .sb_axi_bid              ('0),
        .sb_axi_arvalid          (),
        .sb_axi_arready          (1'b0),
        .sb_axi_arid             (),
        .sb_axi_araddr           (),
        .sb_axi_arregion         (),
        .sb_axi_arlen            (),
        .sb_axi_arsize           (),
        .sb_axi_arburst          (),
        .sb_axi_arlock           (),
        .sb_axi_arcache          (),
        .sb_axi_arprot           (),
        .sb_axi_arqos            (),
        .sb_axi_rvalid           (1'b0),
        .sb_axi_rready           (),
        .sb_axi_rid              ('0),
        .sb_axi_rdata            ('0),
        .sb_axi_rresp            (2'b00),
        .sb_axi_rlast            (1'b0),

        // DMA AXI Slave (External DMA directly into Core memory - tied off)
        .dma_axi_awvalid         (1'b0),
        .dma_axi_awready         (),
        .dma_axi_awid            ('0),
        .dma_axi_awaddr          ('0),
        .dma_axi_awsize          (3'b010),
        .dma_axi_awprot          (3'b000),
        .dma_axi_awlen           (8'h0),
        .dma_axi_awburst         (2'b01),
        .dma_axi_wvalid          (1'b0),
        .dma_axi_wready          (),
        .dma_axi_wdata           (64'h0),
        .dma_axi_wstrb           (8'h0),
        .dma_axi_wlast           (1'b0),
        .dma_axi_bvalid          (),
        .dma_axi_bready          (1'b0),
        .dma_axi_bresp           (),
        .dma_axi_bid             (),
        .dma_axi_arvalid         (1'b0),
        .dma_axi_arready         (),
        .dma_axi_arid            ('0),
        .dma_axi_araddr          ('0),
        .dma_axi_arsize          (3'b010),
        .dma_axi_arprot          (3'b000),
        .dma_axi_arlen           (8'h0),
        .dma_axi_arburst         (2'b01),
        .dma_axi_rvalid          (),
        .dma_axi_rready          (1'b0),
        .dma_axi_rid             (),
        .dma_axi_rdata           (),
        .dma_axi_rresp           (),
        .dma_axi_rlast           (),

        // Clock enables (1:1 with primary core clock)
        .lsu_bus_clk_en          (1'b1),
        .ifu_bus_clk_en          (1'b1),
        .dbg_bus_clk_en          (1'b1),
        .dma_bus_clk_en          (1'b1),

        // ECC error status outputs
        .iccm_ecc_single_error   (),
        .iccm_ecc_double_error   (),
        .dccm_ecc_single_error   (),
        .dccm_ecc_double_error   (),
        .dccm_write_readback_error(),

        // Memory interfaces (connected to local SRAM arrays)
        .el2_icache_export       (mem_export.veer_icache_src),
        .el2_mem_export          (mem_export.veer_sram_src),

        // Interrupt inputs
        .timer_int               (timer_int),
        .soft_int                (soft_int),
        .extintsrc_req           (extintsrc_req),

        // Performance counters
        .dec_tlu_perfcnt0        (),
        .dec_tlu_perfcnt1        (),
        .dec_tlu_perfcnt2        (),
        .dec_tlu_perfcnt3        (),

        // JTAG TAP
        .jtag_tck                (jtag_tck),
        .jtag_tms                (jtag_tms),
        .jtag_tdi                (jtag_tdi),
        .jtag_trst_n             (jtag_trst_n),
        .jtag_tdo                (jtag_tdo),
        .jtag_tdoEn              (jtag_tdoEn),

        .core_id                 (28'h0),

        // MPC debug halt/run
        .mpc_debug_halt_req      (1'b0),
        .mpc_debug_run_req       (1'b0),
        .mpc_reset_run_req       (1'b1),
        .mpc_debug_halt_ack      (),
        .mpc_debug_run_ack       (),
        .debug_brkpt_status      (),

        .i_cpu_halt_req          (i_cpu_halt_req),
        .o_cpu_halt_ack          (o_cpu_halt_ack),
        .o_cpu_halt_status       (o_cpu_halt_status),
        .o_debug_mode_status     (o_debug_mode_status),
        .i_cpu_run_req           (i_cpu_run_req),
        .o_cpu_run_ack           (o_cpu_run_ack),

        // Test modes
        .scan_mode               (1'b0),
        .mbist_mode              (1'b0),

        // DMI
        .dmi_core_enable         (1'b0),
        .dmi_uncore_enable       (1'b0),
        .dmi_uncore_en           (),
        .dmi_uncore_wr_en        (),
        .dmi_uncore_addr         (),
        .dmi_uncore_wdata        (),
        .dmi_uncore_rdata        (32'h0),
        .dmi_active              ()
    );

endmodule

`default_nettype wire

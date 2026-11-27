// =============================================================================
// File        : tb/soc_axi_if.sv
// Description : Shared SoC AXI4 Master (s00) & DMA AXI4-Lite CSR Virtual
//               Interface for UVM Peripheral VIPs. Drives unified bus
//               transactions into soc_top and mirrors peripheral interrupt/IO
//               observations for all UVM drivers, monitors, and tests.
// =============================================================================

`timescale 1ns/1ps

interface soc_axi_if (
    input logic clk,
    input logic aresetn
);
    // -------------------------------------------------------------------------
    // AXI4 Master 0 Signals (to soc_top.ext_s00_axi_*)
    // -------------------------------------------------------------------------
    logic [7:0]   m_awid;
    logic [31:0]  m_awaddr;
    logic [7:0]   m_awlen;
    logic [2:0]   m_awsize;
    logic [1:0]   m_awburst;
    logic         m_awlock;
    logic [3:0]   m_awcache;
    logic [2:0]   m_awprot;
    logic [3:0]   m_awqos;
    logic         m_awvalid;
    wire          m_awready;

    logic [31:0]  m_wdata;
    logic [3:0]   m_wstrb;
    logic         m_wlast;
    logic         m_wvalid;
    wire          m_wready;

    wire  [7:0]   m_bid;
    wire  [1:0]   m_bresp;
    wire          m_bvalid;
    logic         m_bready;

    logic [7:0]   m_arid;
    logic [31:0]  m_araddr;
    logic [7:0]   m_arlen;
    logic [2:0]   m_arsize;
    logic [1:0]   m_arburst;
    logic         m_arlock;
    logic [3:0]   m_arcache;
    logic [2:0]   m_arprot;
    logic [3:0]   m_arqos;
    logic         m_arvalid;
    wire          m_arready;

    wire  [7:0]   m_rid;
    wire  [31:0]  m_rdata;
    wire  [1:0]   m_rresp;
    wire          m_rlast;
    wire          m_rvalid;
    logic         m_rready;

    // -------------------------------------------------------------------------
    // DMA CSR AXI4-Lite Master Signals (to soc_top.dma_csr_*, 0x4000_5000)
    // -------------------------------------------------------------------------
    logic [31:0]  dma_awaddr;
    logic [2:0]   dma_awprot;
    logic         dma_awvalid;
    wire          dma_awready;
    logic [31:0]  dma_wdata;
    logic [3:0]   dma_wstrb;
    logic         dma_wvalid;
    wire          dma_wready;
    wire  [1:0]   dma_bresp;
    wire          dma_bvalid;
    logic         dma_bready;
    logic [31:0]  dma_araddr;
    logic [2:0]   dma_arprot;
    logic         dma_arvalid;
    wire          dma_arready;
    wire  [31:0]  dma_rdata;
    wire  [1:0]   dma_rresp;
    wire          dma_rvalid;
    logic         dma_rready;

    // -------------------------------------------------------------------------
    // Observed SoC Interrupts & Boundary Outputs
    // -------------------------------------------------------------------------
    logic         uart_irq;
    logic         timer_irq;
    logic         aes_irq;
    logic         sha_irq;
    logic         dma_done;
    logic         dma_error;
    logic [1:0]   gpio_intr;

    semaphore bus_lock;

    initial begin
        bus_lock    = new(1);
        m_awid      = 8'h00;
        m_awaddr    = 32'h0;
        m_awlen     = 8'h00;
        m_awsize    = 3'b010;
        m_awburst   = 2'b01;
        m_awlock    = 1'b0;
        m_awcache   = 4'b0010;
        m_awprot    = 3'b000;
        m_awqos     = 4'h0;
        m_awvalid   = 1'b0;
        m_wdata     = 32'h0;
        m_wstrb     = 4'hF;
        m_wlast     = 1'b1;
        m_wvalid    = 1'b0;
        m_bready    = 1'b0;
        m_arid      = 8'h00;
        m_araddr    = 32'h0;
        m_arlen     = 8'h00;
        m_arsize    = 3'b010;
        m_arburst   = 2'b01;
        m_arlock    = 1'b0;
        m_arcache   = 4'b0010;
        m_arprot    = 3'b000;
        m_arqos     = 4'h0;
        m_arvalid   = 1'b0;
        m_rready    = 1'b0;

        dma_awaddr  = 32'h0;
        dma_awprot  = 3'b000;
        dma_awvalid = 1'b0;
        dma_wdata   = 32'h0;
        dma_wstrb   = 4'h0;
        dma_wvalid  = 1'b0;
        dma_bready  = 1'b0;
        dma_araddr  = 32'h0;
        dma_arprot  = 3'b000;
        dma_arvalid = 1'b0;
        dma_rready  = 1'b0;
    end

    task wait_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    // split_mode: 0 = AW+W same cycle, 1 = AW first (1 clk ahead of W), 2 = W first (1 clk ahead of AW)
    task axi_write_ext(input int unsigned addr,
                       input int unsigned data,
                       input int unsigned wstrb,
                       input int          split_mode,
                       input int          bready_delay,
                       output int unsigned resp);
        bit aw_done, w_done;
        begin
            bus_lock.get(1);
            if ((addr & 32'hFFFF_F000) == 32'h4000_5000) begin
                @(posedge clk);
                dma_awaddr  <= {20'h0, addr[11:0]};
                dma_awprot  <= 3'b000;
                dma_wdata   <= data;
                dma_wstrb   <= wstrb[3:0];
                dma_bready  <= (bready_delay == 0) ? 1'b1 : 1'b0;
                aw_done      = 1'b0;
                w_done       = 1'b0;

                if (split_mode == 1) begin
                    dma_awvalid <= 1'b1;
                    dma_wvalid  <= 1'b0;
                    @(posedge clk);
                    if (dma_awready) begin
                        dma_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    dma_wvalid  <= 1'b1;
                end else if (split_mode == 2) begin
                    dma_awvalid <= 1'b0;
                    dma_wvalid  <= 1'b1;
                    @(posedge clk);
                    if (dma_wready) begin
                        dma_wvalid <= 1'b0;
                        w_done = 1'b1;
                    end
                    dma_awvalid <= 1'b1;
                end else begin
                    dma_awvalid <= 1'b1;
                    dma_wvalid  <= 1'b1;
                end

                while (!aw_done || !w_done) begin
                    @(posedge clk);
                    if (!aw_done && dma_awready) begin
                        dma_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    if (!w_done && dma_wready) begin
                        dma_wvalid <= 1'b0;
                        w_done = 1'b1;
                    end
                end

                while (!dma_bvalid) begin
                    @(posedge clk);
                end
                if (bready_delay > 0) begin
                    repeat (bready_delay) @(posedge clk);
                    dma_bready <= 1'b1;
                    @(posedge clk);
                end

                resp = {30'h0, dma_bresp};
                dma_bready <= 1'b0;
                @(posedge clk);
            end else begin
                @(posedge clk);
                m_awid     <= 8'h01;
                m_awaddr   <= addr;
                m_awlen    <= 8'h00;
                m_awsize   <= 3'b010;
                m_awburst  <= 2'b01;
                m_wdata    <= data;
                m_wstrb    <= wstrb[3:0];
                m_wlast    <= 1'b1;
                m_bready   <= (bready_delay == 0) ? 1'b1 : 1'b0;
                aw_done     = 1'b0;
                w_done      = 1'b0;

                if (split_mode == 1) begin
                    m_awvalid <= 1'b1;
                    m_wvalid  <= 1'b0;
                    @(posedge clk);
                    if (m_awready) begin
                        m_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    m_wvalid  <= 1'b1;
                end else if (split_mode == 2) begin
                    m_awvalid <= 1'b0;
                    m_wvalid  <= 1'b1;
                    @(posedge clk);
                    if (m_wready) begin
                        m_wvalid <= 1'b0;
                        w_done = 1'b1;
                    end
                    m_awvalid <= 1'b1;
                end else begin
                    m_awvalid <= 1'b1;
                    m_wvalid  <= 1'b1;
                end

                while (!aw_done || !w_done) begin
                    @(posedge clk);
                    if (!aw_done && m_awready) begin
                        m_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    if (!w_done && m_wready) begin
                        m_wvalid <= 1'b0;
                        w_done = 1'b1;
                    end
                end

                while (!m_bvalid) begin
                    @(posedge clk);
                end
                if (bready_delay > 0) begin
                    repeat (bready_delay) @(posedge clk);
                    m_bready <= 1'b1;
                    @(posedge clk);
                end

                resp = {30'h0, m_bresp};
                m_bready <= 1'b0;
                @(posedge clk);
            end
            bus_lock.put(1);
        end
    endtask

    task axi_write_strb(input int unsigned addr, input int unsigned data,
                        input int unsigned wstrb, output int unsigned resp);
        axi_write_ext(addr, data, wstrb, 0, 0, resp);
    endtask

    task axi_write_resp(input int unsigned addr, input int unsigned data, output int unsigned resp);
        axi_write_ext(addr, data, 32'hF, 0, 0, resp);
    endtask

    task axi_write(input int unsigned addr, input int unsigned data);
        int unsigned dummy_resp;
        axi_write_ext(addr, data, 32'hF, 0, 0, dummy_resp);
    endtask

    task axi_read_ext(input int unsigned addr,
                      input int          rready_delay,
                      output int unsigned data,
                      output int unsigned resp);
        bit ar_done;
        begin
            bus_lock.get(1);
            if ((addr & 32'hFFFF_F000) == 32'h4000_5000) begin
                @(posedge clk);
                dma_araddr  <= {20'h0, addr[11:0]};
                dma_arprot  <= 3'b000;
                dma_arvalid <= 1'b1;
                dma_rready  <= (rready_delay == 0) ? 1'b1 : 1'b0;
                ar_done      = 1'b0;

                while (!ar_done) begin
                    @(posedge clk);
                    if (dma_arready) begin
                        dma_arvalid <= 1'b0;
                        ar_done = 1'b1;
                    end
                end

                while (!dma_rvalid) begin
                    @(posedge clk);
                end
                if (rready_delay > 0) begin
                    repeat (rready_delay) @(posedge clk);
                    dma_rready <= 1'b1;
                    @(posedge clk);
                end

                data = dma_rdata;
                resp = {30'h0, dma_rresp};
                dma_rready <= 1'b0;
                @(posedge clk);
            end else begin
                @(posedge clk);
                m_arid    <= 8'h01;
                m_araddr  <= addr;
                m_arlen   <= 8'h00;
                m_arsize  <= 3'b010;
                m_arburst <= 2'b01;
                m_arvalid <= 1'b1;
                m_rready  <= (rready_delay == 0) ? 1'b1 : 1'b0;
                ar_done    = 1'b0;

                while (!ar_done) begin
                    @(posedge clk);
                    if (m_arready) begin
                        m_arvalid <= 1'b0;
                        ar_done = 1'b1;
                    end
                end

                while (!m_rvalid) begin
                    @(posedge clk);
                end
                if (rready_delay > 0) begin
                    repeat (rready_delay) @(posedge clk);
                    m_rready <= 1'b1;
                    @(posedge clk);
                end

                data = m_rdata;
                resp = {30'h0, m_rresp};
                m_rready <= 1'b0;
                @(posedge clk);
            end
            bus_lock.put(1);
        end
    endtask

    task axi_read_resp(input int unsigned addr, output int unsigned data, output int unsigned resp);
        axi_read_ext(addr, 0, data, resp);
    endtask

    task axi_read(input int unsigned addr, output int unsigned data);
        int unsigned dummy_resp;
        axi_read_ext(addr, 0, data, dummy_resp);
    endtask

    task axi_concurrent_rw(input int unsigned wr_addr, input int unsigned wr_data,
                           input int unsigned rd_addr, output int unsigned rd_data,
                           output int unsigned bresp, output int unsigned rresp);
        bit aw_done, w_done, b_done, ar_done, r_done;
        begin
            bus_lock.get(1);
            @(posedge clk);
            m_awid    <= 8'h02;
            m_awaddr  <= wr_addr;
            m_awvalid <= 1'b1;
            m_wdata   <= wr_data;
            m_wstrb   <= 4'hF;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;

            m_arid    <= 8'h03;
            m_araddr  <= rd_addr;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;

            aw_done = 1'b0; w_done = 1'b0; b_done = 1'b0;
            ar_done = 1'b0; r_done = 1'b0;

            while (!b_done || !r_done) begin
                @(posedge clk);
                if (!aw_done && m_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done = 1'b1;
                end
                if (!w_done && m_wready) begin
                    m_wvalid <= 1'b0;
                    w_done = 1'b1;
                end
                if (!b_done && m_bvalid) begin
                    bresp = {30'h0, m_bresp};
                    m_bready <= 1'b0;
                    b_done = 1'b1;
                end
                if (!ar_done && m_arready) begin
                    m_arvalid <= 1'b0;
                    ar_done = 1'b1;
                end
                if (!r_done && m_rvalid) begin
                    rd_data = m_rdata;
                    rresp   = {30'h0, m_rresp};
                    m_rready <= 1'b0;
                    r_done = 1'b1;
                end
            end
            @(posedge clk);
            bus_lock.put(1);
        end
    endtask

    task axi_burst_wr4(input int unsigned addr, input int unsigned burst,
                       input int unsigned w0, input int unsigned w1,
                       input int unsigned w2, input int unsigned w3,
                       output int unsigned bresp);
        int beat;
        bit aw_done;
        logic [31:0] warr [0:3];
        begin
            bus_lock.get(1);
            warr[0] = w0; warr[1] = w1; warr[2] = w2; warr[3] = w3;
            @(posedge clk);
            m_awid    <= 8'h01;
            m_awaddr  <= addr;
            m_awlen   <= 8'd3;
            m_awsize  <= 3'b010;
            m_awburst <= burst[1:0];
            m_awvalid <= 1'b1;
            m_wdata   <= warr[0];
            m_wstrb   <= 4'hF;
            m_wlast   <= 1'b0;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;
            aw_done    = 1'b0;
            beat       = 0;

            while (!aw_done || (beat < 4)) begin
                @(posedge clk);
                if (!aw_done && m_awready) begin
                    m_awvalid <= 1'b0;
                    aw_done = 1'b1;
                end
                if (m_wvalid && m_wready) begin
                    beat = beat + 1;
                    if (beat < 4) begin
                        m_wdata <= warr[beat];
                        m_wlast <= (beat == 3);
                    end else begin
                        m_wvalid <= 1'b0;
                        m_wlast  <= 1'b1;
                    end
                end
            end

            while (!m_bvalid) @(posedge clk);
            bresp = {30'h0, m_bresp};
            m_bready  <= 1'b0;
            m_awlen   <= 8'h00;
            m_awburst <= 2'b01;
            m_wlast   <= 1'b1;
            m_wstrb   <= 4'hF;
            @(posedge clk);
            bus_lock.put(1);
        end
    endtask

    task axi_burst_rd4(input int unsigned addr, input int unsigned burst,
                       output int unsigned w0, output int unsigned w1,
                       output int unsigned w2, output int unsigned w3,
                       output int unsigned rresp);
        int beat;
        bit ar_done;
        logic [1:0] rresp_acc;
        logic [31:0] rarr [0:3];
        begin
            bus_lock.get(1);
            rarr[0] = 32'h0; rarr[1] = 32'h0; rarr[2] = 32'h0; rarr[3] = 32'h0;
            @(posedge clk);
            m_arid    <= 8'h01;
            m_araddr  <= addr;
            m_arlen   <= 8'd3;
            m_arsize  <= 3'b010;
            m_arburst <= burst[1:0];
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;
            ar_done    = 1'b0;
            beat       = 0;
            rresp_acc  = 2'b00;

            while (!ar_done || (beat < 4)) begin
                @(posedge clk);
                if (!ar_done && m_arready) begin
                    m_arvalid <= 1'b0;
                    ar_done = 1'b1;
                end
                if (m_rvalid && m_rready) begin
                    if (beat < 4) rarr[beat] = m_rdata;
                    if (m_rresp != 2'b00) rresp_acc = m_rresp;
                    beat = beat + 1;
                    if (beat >= 4) begin
                        m_rready <= 1'b0;
                    end
                end
            end

            w0 = rarr[0]; w1 = rarr[1]; w2 = rarr[2]; w3 = rarr[3];
            rresp = {30'h0, rresp_acc};
            m_arlen   <= 8'h00;
            m_arburst <= 2'b01;
            @(posedge clk);
            bus_lock.put(1);
        end
    endtask

endinterface : soc_axi_if

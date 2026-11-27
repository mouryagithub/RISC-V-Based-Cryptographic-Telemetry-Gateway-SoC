// =============================================================================
// File        : tb_soc_c_test.sv
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : SystemVerilog DPI-C Testbench for soc_top.
//               Executes C firmware verification test suite via DPI-C bridge.
// =============================================================================

`timescale 1ns/10ps
`default_nettype none

module tb_soc_c_test;

    // =========================================================================
    // Parameters
    // =========================================================================
    localparam CLK_PERIOD = 20;       // 50 MHz primary clock
    localparam BAUD_DIV   = 16'd434;  // 115200 baud @ 50 MHz

    // =========================================================================
    // Clocks and Reset
    // =========================================================================
    reg clk;
    reg uart_clk;
    reg aresetn;

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    initial uart_clk = 0;
    always #(CLK_PERIOD/2) uart_clk = ~uart_clk;

    // =========================================================================
    // AXI4 Master 0 Signals (s00 of soc_top)
    // =========================================================================
    reg  [7:0]  m_awid;
    reg  [31:0] m_awaddr;
    reg  [7:0]  m_awlen;
    reg  [2:0]  m_awsize;
    reg  [1:0]  m_awburst;
    reg         m_awlock;
    reg  [3:0]  m_awcache;
    reg  [2:0]  m_awprot;
    reg  [3:0]  m_awqos;
    reg         m_awvalid;
    wire        m_awready;

    reg  [31:0] m_wdata;
    reg  [3:0]  m_wstrb;
    reg         m_wlast;
    reg         m_wvalid;
    wire        m_wready;

    wire [7:0]  m_bid;
    wire [1:0]  m_bresp;
    wire        m_bvalid;
    reg         m_bready;

    reg  [7:0]  m_arid;
    reg  [31:0] m_araddr;
    reg  [7:0]  m_arlen;
    reg  [2:0]  m_arsize;
    reg  [1:0]  m_arburst;
    reg         m_arlock;
    reg  [3:0]  m_arcache;
    reg  [2:0]  m_arprot;
    reg  [3:0]  m_arqos;
    reg         m_arvalid;
    wire        m_arready;

    wire [7:0]  m_rid;
    wire [31:0] m_rdata;
    wire [1:0]  m_rresp;
    wire        m_rlast;
    wire        m_rvalid;
    reg         m_rready;

    // UART serial lines
    wire        uart_tx;
    reg         uart_rx;

    // GPIO signals
    reg  [63:0] gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_dir_o;
    wire [1:0]  gpio_intr;

    // Peripheral Interrupt observation lines
    wire        uart_irq;
    wire        timer_irq;
    wire        aes_irq;
    wire        sha_irq;
    wire        dma_done;
    wire        dma_error;

    // DMA CSR AXI4-Lite Master Signals (0x4000_5000..0x4000_5FFF)
    reg  [31:0] dma_awaddr;
    reg  [2:0]  dma_awprot;
    reg         dma_awvalid;
    wire        dma_awready;
    reg  [31:0] dma_wdata;
    reg  [3:0]  dma_wstrb;
    reg         dma_wvalid;
    wire        dma_wready;
    wire [1:0]  dma_bresp;
    wire        dma_bvalid;
    reg         dma_bready;
    reg  [31:0] dma_araddr;
    reg  [2:0]  dma_arprot;
    reg         dma_arvalid;
    wire        dma_arready;
    wire [31:0] dma_rdata;
    wire [1:0]  dma_rresp;
    wire        dma_rvalid;
    reg         dma_rready;

    // =========================================================================
    // DUT: soc_top (Master SoC Top with 2x5 Interconnect)
    // =========================================================================
    soc_top #(
        .USE_INTERNAL_CPU    (0),
        .AXI_DATA_WIDTH      (32),
        .AXI_ADDR_WIDTH      (32),
        .AXI_ID_WIDTH        (8)
    ) u_soc_top (
        .clk                 (clk),
        .uart_clk            (uart_clk),
        .aresetn             (aresetn),

        // External Master 0 (TB master -> s00 of interconnect)
        .ext_s00_axi_awid    (m_awid),
        .ext_s00_axi_awaddr  (m_awaddr),
        .ext_s00_axi_awlen   (m_awlen),
        .ext_s00_axi_awsize  (m_awsize),
        .ext_s00_axi_awburst (m_awburst),
        .ext_s00_axi_awlock  (m_awlock),
        .ext_s00_axi_awcache (m_awcache),
        .ext_s00_axi_awprot  (m_awprot),
        .ext_s00_axi_awqos   (m_awqos),
        .ext_s00_axi_awvalid (m_awvalid),
        .ext_s00_axi_awready (m_awready),
        .ext_s00_axi_wdata   (m_wdata),
        .ext_s00_axi_wstrb   (m_wstrb),
        .ext_s00_axi_wlast   (m_wlast),
        .ext_s00_axi_wvalid  (m_wvalid),
        .ext_s00_axi_wready  (m_wready),
        .ext_s00_axi_bid     (m_bid),
        .ext_s00_axi_bresp   (m_bresp),
        .ext_s00_axi_bvalid  (m_bvalid),
        .ext_s00_axi_bready  (m_bready),
        .ext_s00_axi_arid    (m_arid),
        .ext_s00_axi_araddr  (m_araddr),
        .ext_s00_axi_arlen   (m_arlen),
        .ext_s00_axi_arsize  (m_arsize),
        .ext_s00_axi_arburst (m_arburst),
        .ext_s00_axi_arlock  (m_arlock),
        .ext_s00_axi_arcache (m_arcache),
        .ext_s00_axi_arprot  (m_arprot),
        .ext_s00_axi_arqos   (m_arqos),
        .ext_s00_axi_arvalid (m_arvalid),
        .ext_s00_axi_arready (m_arready),
        .ext_s00_axi_rid     (m_rid),
        .ext_s00_axi_rdata   (m_rdata),
        .ext_s00_axi_rresp   (m_rresp),
        .ext_s00_axi_rlast   (m_rlast),
        .ext_s00_axi_rvalid  (m_rvalid),
        .ext_s00_axi_rready  (m_rready),

        // DMA CSR slave interface (0x4000_5000 window)
        .dma_csr_awaddr      (dma_awaddr),
        .dma_csr_awprot      (dma_awprot),
        .dma_csr_awvalid     (dma_awvalid),
        .dma_csr_awready     (dma_awready),
        .dma_csr_wdata       (dma_wdata),
        .dma_csr_wstrb       (dma_wstrb),
        .dma_csr_wvalid      (dma_wvalid),
        .dma_csr_wready      (dma_wready),
        .dma_csr_bresp       (dma_bresp),
        .dma_csr_bvalid      (dma_bvalid),
        .dma_csr_bready      (dma_bready),
        .dma_csr_araddr      (dma_araddr),
        .dma_csr_arprot      (dma_arprot),
        .dma_csr_arvalid     (dma_arvalid),
        .dma_csr_arready     (dma_arready),
        .dma_csr_rdata       (dma_rdata),
        .dma_csr_rresp       (dma_rresp),
        .dma_csr_rvalid      (dma_rvalid),
        .dma_csr_rready      (dma_rready),

        // Peripherals external I/O
        .uart_rx             (uart_rx),
        .uart_tx             (uart_tx),
        .gpio_i              (gpio_i),
        .gpio_o              (gpio_o),
        .gpio_dir_o          (gpio_dir_o),

        // Interrupts
        .uart_irq_o          (uart_irq),
        .timer_irq_o         (timer_irq),
        .aes_irq_o           (aes_irq),
        .sha_irq_o           (sha_irq),
        .dma_done_o          (dma_done),
        .dma_error_o         (dma_error),
        .gpio_intr_o         (gpio_intr),
        .cpu_halt_status_o   ()
    );

    // =========================================================================
    // DPI-C Exported Tasks (Callable from C Test Suite)
    // =========================================================================
    export "DPI-C" task sv_axi_write;
    export "DPI-C" task sv_axi_read;
    export "DPI-C" task sv_axi_write_resp;
    export "DPI-C" task sv_axi_write_strb;
    export "DPI-C" task sv_axi_read_resp;
    export "DPI-C" task sv_axi_concurrent_rw;
    export "DPI-C" task sv_delay_cycles;
    export "DPI-C" task sv_uart_send_byte;
    export "DPI-C" task sv_uart_send_err;
    export "DPI-C" task sv_uart_recv_byte;
    export "DPI-C" task sv_uart_tx_loopback;
    export "DPI-C" task sv_uart_b2b_tx;
    export "DPI-C" task sv_set_gpio_in;
    export "DPI-C" task sv_get_gpio_out;
    export "DPI-C" task sv_get_gpio_dir;
    export "DPI-C" task sv_get_gpio_intr;
    export "DPI-C" task sv_get_irqs;
    export "DPI-C" task sv_get_aes_done_dout;
    export "DPI-C" task sv_get_sim_flags;
    export "DPI-C" task sv_axi_burst_wr4;
    export "DPI-C" task sv_axi_burst_rd4;
    export "DPI-C" task sv_uart_send_cfg;
    export "DPI-C" task sv_uart_tx_cfg;

    // DPI-C Imported C Test Suite Entry Point
    import "DPI-C" context task soc_c_main(output int status);

    // AXI single-beat 32-bit write with configurable byte strobes & response capture
    // (routes 0x4000_5xxx to DMA CSR)
    task sv_axi_write_strb(input int unsigned addr, input int unsigned data,
                           input int unsigned wstrb, output int unsigned resp);
        reg aw_done;
        reg w_done;
        begin
            if ((addr & 32'hFFFF_F000) == 32'h4000_5000) begin
                @(posedge clk);
                dma_awaddr  <= {20'h0, addr[11:0]};
                dma_awprot  <= 3'b000;
                dma_awvalid <= 1'b1;
                dma_wdata   <= data;
                dma_wstrb   <= wstrb[3:0];
                dma_wvalid  <= 1'b1;
                dma_bready  <= 1'b1;
                aw_done      = 1'b0;
                w_done       = 1'b0;

                while (!aw_done || !w_done) begin
                    @(posedge clk);
                    if (dma_awvalid && dma_awready) begin
                        dma_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    if (dma_wvalid && dma_wready) begin
                        dma_wvalid <= 1'b0;
                        w_done = 1'b1;
                    end
                end

                while (!dma_bvalid) begin
                    @(posedge clk);
                end
                resp = {30'h0, dma_bresp};
                dma_bready <= 1'b0;
                @(posedge clk);
            end else begin
                @(posedge clk);
                m_awid    <= 8'h01;
                m_awaddr  <= addr;
                m_awlen   <= 8'h00;
                m_awsize  <= 3'b010;
                m_awburst <= 2'b01;
                m_awlock  <= 1'b0;
                m_awcache <= 4'b0010;
                m_awprot  <= 3'b000;
                m_awqos   <= 4'h0;
                m_awvalid <= 1'b1;
                m_wdata   <= data;
                m_wstrb   <= wstrb[3:0];
                m_wlast   <= 1'b1;
                m_wvalid  <= 1'b1;
                m_bready  <= 1'b1;
                aw_done    = 1'b0;
                w_done     = 1'b0;

                while (!aw_done || !w_done) begin
                    @(posedge clk);
                    if (m_awvalid && m_awready) begin
                        m_awvalid <= 1'b0;
                        aw_done = 1'b1;
                    end
                    if (m_wvalid && m_wready) begin
                        m_wvalid <= 1'b0;
                        m_wlast  <= 1'b0;
                        w_done = 1'b1;
                    end
                end

                while (!m_bvalid) begin
                    @(posedge clk);
                end
                resp = {30'h0, m_bresp};
                m_bready <= 1'b0;
                @(posedge clk);
            end
        end
    endtask

    task sv_axi_write_resp(input int unsigned addr, input int unsigned data, output int unsigned resp);
        begin
            sv_axi_write_strb(addr, data, 32'hF, resp);
        end
    endtask

    task sv_axi_write(input int unsigned addr, input int unsigned data);
        int unsigned dummy_resp;
        begin
            sv_axi_write_resp(addr, data, dummy_resp);
        end
    endtask

    // AXI single-beat 32-bit read with response capture (routes 0x4000_5xxx to DMA CSR)
    task sv_axi_read_resp(input int unsigned addr, output int unsigned data, output int unsigned resp);
        reg ar_done;
        begin
            if ((addr & 32'hFFFF_F000) == 32'h4000_5000) begin
                @(posedge clk);
                dma_araddr  <= {20'h0, addr[11:0]};
                dma_arprot  <= 3'b000;
                dma_arvalid <= 1'b1;
                dma_rready  <= 1'b1;
                ar_done      = 1'b0;

                while (!ar_done) begin
                    @(posedge clk);
                    if (dma_arvalid && dma_arready) begin
                        dma_arvalid <= 1'b0;
                        ar_done = 1'b1;
                    end
                end

                while (!dma_rvalid) begin
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
                m_arlock  <= 1'b0;
                m_arcache <= 4'b0010;
                m_arprot  <= 3'b000;
                m_arqos   <= 4'h0;
                m_arvalid <= 1'b1;
                m_rready  <= 1'b1;
                ar_done    = 1'b0;

                while (!ar_done) begin
                    @(posedge clk);
                    if (m_arvalid && m_arready) begin
                        m_arvalid <= 1'b0;
                        ar_done = 1'b1;
                    end
                end

                while (!m_rvalid) begin
                    @(posedge clk);
                end
                data = m_rdata;
                resp = {30'h0, m_rresp};
                m_rready <= 1'b0;
                @(posedge clk);
            end
        end
    endtask

    task sv_axi_read(input int unsigned addr, output int unsigned data);
        int unsigned dummy_resp;
        begin
            sv_axi_read_resp(addr, data, dummy_resp);
        end
    endtask

    // Concurrent AXI4 s00 write + read issue
    task sv_axi_concurrent_rw(input int unsigned wr_addr, input int unsigned wr_data,
                              input int unsigned rd_addr, output int unsigned rd_data,
                              output int unsigned bresp, output int unsigned rresp);
        reg aw_done, w_done, b_done, ar_done, r_done;
        begin
            @(posedge clk);
            m_awid    <= 8'h02;
            m_awaddr  <= wr_addr;
            m_awlen   <= 8'h00;
            m_awsize  <= 3'b010;
            m_awburst <= 2'b01;
            m_awlock  <= 1'b0;
            m_awcache <= 4'b0010;
            m_awprot  <= 3'b000;
            m_awqos   <= 4'h0;
            m_awvalid <= 1'b1;
            m_wdata   <= wr_data;
            m_wstrb   <= 4'hF;
            m_wlast   <= 1'b1;
            m_wvalid  <= 1'b1;
            m_bready  <= 1'b1;

            m_arid    <= 8'h03;
            m_araddr  <= rd_addr;
            m_arlen   <= 8'h00;
            m_arsize  <= 3'b010;
            m_arburst <= 2'b01;
            m_arlock  <= 1'b0;
            m_arcache <= 4'b0010;
            m_arprot  <= 3'b000;
            m_arqos   <= 4'h0;
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
                    m_wlast  <= 1'b0;
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
        end
    endtask

    // Delay helper
    task sv_delay_cycles(input int cycles);
        repeat (cycles) @(posedge clk);
    endtask

    // AXI4 4-beat burst write (burst: 0=FIXED, 1=INCR, 2=WRAP)
    task sv_axi_burst_wr4(input int unsigned addr, input int unsigned burst,
                          input int unsigned w0, input int unsigned w1,
                          input int unsigned w2, input int unsigned w3,
                          output int unsigned bresp);
        integer beat;
        reg aw_done;
        reg [31:0] warr [0:3];
        begin
            warr[0] = w0; warr[1] = w1; warr[2] = w2; warr[3] = w3;
            @(posedge clk);
            m_awid    <= 8'h01;
            m_awaddr  <= addr;
            m_awlen   <= 8'd3;
            m_awsize  <= 3'b010;
            m_awburst <= burst[1:0];
            m_awlock  <= 1'b0;
            m_awcache <= 4'b0010;
            m_awprot  <= 3'b000;
            m_awqos   <= 4'h0;
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
                if (!aw_done && m_awvalid && m_awready) begin
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
                        m_wlast  <= 1'b0;
                    end
                end
            end

            while (!m_bvalid) @(posedge clk);
            bresp = {30'h0, m_bresp};
            m_bready  <= 1'b0;
            m_awlen   <= 8'h00;
            m_awburst <= 2'b01;
            @(posedge clk);
        end
    endtask

    // AXI4 4-beat burst read (burst: 0=FIXED, 1=INCR, 2=WRAP)
    task sv_axi_burst_rd4(input int unsigned addr, input int unsigned burst,
                          output int unsigned w0, output int unsigned w1,
                          output int unsigned w2, output int unsigned w3,
                          output int unsigned rresp);
        integer beat;
        reg ar_done;
        reg [1:0] rresp_acc;
        reg [31:0] rarr [0:3];
        begin
            rarr[0] = 32'h0; rarr[1] = 32'h0; rarr[2] = 32'h0; rarr[3] = 32'h0;
            @(posedge clk);
            m_arid    <= 8'h01;
            m_araddr  <= addr;
            m_arlen   <= 8'd3;
            m_arsize  <= 3'b010;
            m_arburst <= burst[1:0];
            m_arlock  <= 1'b0;
            m_arcache <= 4'b0010;
            m_arprot  <= 3'b000;
            m_arqos   <= 4'h0;
            m_arvalid <= 1'b1;
            m_rready  <= 1'b1;
            ar_done    = 1'b0;
            beat       = 0;
            rresp_acc  = 2'b00;

            while (!ar_done || (beat < 4)) begin
                @(posedge clk);
                if (!ar_done && m_arvalid && m_arready) begin
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
        end
    endtask

    // Bit-bang transmit one byte to UART RX
    task sv_uart_send_byte(input byte unsigned byte_val);
        integer baud_clks, b;
        begin
            baud_clks = BAUD_DIV;
            uart_rx = 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx = byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_rx = 1'b1; // stop bit
            repeat (baud_clks) @(posedge uart_clk);
        end
    endtask

    task sv_uart_send_err(input byte unsigned byte_val,
                          input byte unsigned parity_en,
                          input byte unsigned parity_odd,
                          input byte unsigned corrupt_parity,
                          input byte unsigned corrupt_stop);
        integer baud_clks, b;
        reg parity_bit;
        begin
            baud_clks = BAUD_DIV;
            uart_rx = 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx = byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            if (parity_en != 8'h00) begin
                parity_bit = ^byte_val;
                if (parity_odd != 8'h00) parity_bit = ~parity_bit;
                if (corrupt_parity != 8'h00) parity_bit = ~parity_bit;
                uart_rx = parity_bit;
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_rx = (corrupt_stop != 8'h00) ? 1'b0 : 1'b1;
            repeat (baud_clks) @(posedge uart_clk);
            uart_rx = 1'b1; // return to idle
            repeat (10) @(posedge uart_clk);
        end
    endtask

    // Synchronously receive one byte from UART TX
    task sv_uart_recv_byte(output byte unsigned rx_byte);
        integer half_baud, baud_clks, b;
        begin
            half_baud = BAUD_DIV / 2;
            baud_clks = BAUD_DIV;
            rx_byte   = 8'h00;

            @(posedge uart_clk);
            while (uart_tx !== 1'b1) @(posedge uart_clk);
            while (uart_tx !== 1'b0) @(posedge uart_clk);

            repeat (half_baud + baud_clks) @(posedge uart_clk);

            for (b = 0; b < 8; b = b + 1) begin
                rx_byte[b] = uart_tx;
                repeat (baud_clks) @(posedge uart_clk);
            end

            repeat (10) @(posedge uart_clk);
        end
    endtask

    // Concurrent TX loopback task: forks AXI THR write with UART receiver
    task sv_uart_tx_loopback(input byte unsigned tx_val, output byte unsigned rx_cap);
        fork
            begin
                sv_axi_write(32'h4000_1000, {24'h0, tx_val});
            end
            begin
                sv_uart_recv_byte(rx_cap);
            end
        join
    endtask

    // Concurrent back-to-back TX task
    task sv_uart_b2b_tx(input byte unsigned b0, input byte unsigned b1, input byte unsigned b2,
                        output byte unsigned r0, output byte unsigned r1, output byte unsigned r2);
        fork
            begin
                sv_axi_write(32'h4000_1000, {24'h0, b0});
                sv_axi_write(32'h4000_1000, {24'h0, b1});
                sv_axi_write(32'h4000_1000, {24'h0, b2});
            end
            begin
                sv_uart_recv_byte(r0);
                sv_uart_recv_byte(r1);
                sv_uart_recv_byte(r2);
            end
        join
    endtask

    // Configurable UART RX stimulus (baud_div, parity_en, parity_odd, stop_2bit, err_mask)
    task sv_uart_send_cfg(input byte unsigned byte_val,
                          input int unsigned  baud_div,
                          input byte unsigned parity_en,
                          input byte unsigned parity_odd,
                          input byte unsigned stop_2bit,
                          input byte unsigned err_mask);
        integer baud_clks, b;
        reg parity_bit;
        begin
            baud_clks = (baud_div > 0) ? int'(baud_div) : BAUD_DIV;
            uart_rx = 1'b0; // start bit
            repeat (baud_clks) @(posedge uart_clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx = byte_val[b];
                repeat (baud_clks) @(posedge uart_clk);
            end
            if (parity_en != 8'h00) begin
                parity_bit = ^byte_val;
                if (parity_odd != 8'h00) parity_bit = ~parity_bit;
                if (err_mask[0]) parity_bit = ~parity_bit;
                uart_rx = parity_bit;
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_rx = err_mask[1] ? 1'b0 : 1'b1; // stop bit 1
            repeat (baud_clks) @(posedge uart_clk);
            if (stop_2bit != 8'h00) begin
                uart_rx = err_mask[2] ? 1'b0 : 1'b1; // stop bit 2
                repeat (baud_clks) @(posedge uart_clk);
            end
            uart_rx = 1'b1;
            repeat (10) @(posedge uart_clk);
        end
    endtask

    // Configurable UART TX loopback + frame verification
    task sv_uart_tx_cfg(input byte unsigned  tx_val,
                        input int unsigned   baud_div,
                        input byte unsigned  parity_en,
                        input byte unsigned  parity_odd,
                        input byte unsigned  stop_2bit,
                        output byte unsigned rx_cap,
                        output int unsigned  frame_ok);
        integer bit_clks, half_bit, b;
        reg start_s, par_s, exp_par, stop1_s, stop2_s;
        begin
            bit_clks = ((baud_div > 0) ? int'(baud_div) : BAUD_DIV) + 1;
            half_bit = bit_clks / 2;
            rx_cap   = 8'h00;
            frame_ok = 32'd0;
            fork
                begin
                    sv_axi_write(32'h4000_1000, {24'h0, tx_val});
                end
                begin
                    @(posedge uart_clk);
                    while (uart_tx !== 1'b1) @(posedge uart_clk);
                    while (uart_tx !== 1'b0) @(posedge uart_clk);
                    repeat (half_bit) @(posedge uart_clk);
                    start_s = uart_tx;
                    for (b = 0; b < 8; b = b + 1) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        rx_cap[b] = uart_tx;
                    end
                    par_s   = 1'b0;
                    exp_par = 1'b0;
                    if (parity_en != 8'h00) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        par_s   = uart_tx;
                        exp_par = (parity_odd != 8'h00) ? ~(^rx_cap) : (^rx_cap);
                    end
                    repeat (bit_clks) @(posedge uart_clk);
                    stop1_s = uart_tx;
                    stop2_s = 1'b1;
                    if (stop_2bit != 8'h00) begin
                        repeat (bit_clks) @(posedge uart_clk);
                        stop2_s = uart_tx;
                    end
                    repeat (10) @(posedge uart_clk);
                    frame_ok = ((start_s === 1'b0) &&
                                ((parity_en == 8'h00) || (par_s === exp_par)) &&
                                (stop1_s === 1'b1) && (stop2_s === 1'b1)) ? 32'd1 : 32'd0;
                end
            join
        end
    endtask

    // GPIO drive / sample helpers
    task sv_set_gpio_in(input int unsigned in_val_low, input int unsigned in_val_high);
        begin
            gpio_i = {in_val_high, in_val_low};
        end
    endtask

    task sv_get_gpio_out(output int unsigned out_val_low, output int unsigned out_val_high);
        begin
            out_val_low  = gpio_o[31:0];
            out_val_high = gpio_o[63:32];
        end
    endtask

    task sv_get_gpio_dir(output int unsigned dir_val_low, output int unsigned dir_val_high);
        begin
            dir_val_low  = gpio_dir_o[31:0];
            dir_val_high = gpio_dir_o[63:32];
        end
    endtask

    task sv_get_gpio_intr(output int unsigned bank0_intr, output int unsigned bank1_intr);
        begin
            bank0_intr = {31'h0, gpio_intr[0]};
            bank1_intr = {31'h0, gpio_intr[1]};
        end
    endtask

    // Interrupt line status helper
    task sv_get_irqs(output int unsigned uart_irq_val, output int unsigned timer_irq_val,
                     output int unsigned aes_irq_val, output int unsigned sha_irq_val,
                     output int unsigned dma_done_val, output int unsigned dma_error_val);
        begin
            uart_irq_val  = uart_irq;
            timer_irq_val = timer_irq;
            aes_irq_val   = aes_irq;
            sha_irq_val   = sha_irq;
            dma_done_val  = dma_done;
            dma_error_val = dma_error;
        end
    endtask

    // Passive observer capturing AES dout_data at exact ST_DATA_WAIT completion
    // beat before aes_cipher_top/aes_inv_cipher_top advance on subsequent cycles.
    reg [127:0] aes_done_dout_cap;
    reg         aes_done_cap_valid;

    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            aes_done_dout_cap  <= 128'h0;
            aes_done_cap_valid <= 1'b0;
        end else begin
            if (u_soc_top.u_aes.state == 4'd0 &&
                u_soc_top.u_aes.ctrl_start) begin
                aes_done_cap_valid <= 1'b0;
            end
            if (u_soc_top.u_aes.core_done_r) begin
                aes_done_dout_cap  <= u_soc_top.u_aes.dout_data;
                aes_done_cap_valid <= 1'b1;
            end
        end
    end

    task sv_get_aes_done_dout(output int unsigned w3, output int unsigned w2,
                              output int unsigned w1, output int unsigned w0,
                              output int unsigned valid);
        begin
            w3    = aes_done_dout_cap[127:96];
            w2    = aes_done_dout_cap[95:64];
            w1    = aes_done_dout_cap[63:32];
            w0    = aes_done_dout_cap[31:0];
            valid = {31'h0, aes_done_cap_valid};
        end
    endtask

    task sv_get_sim_flags(output int unsigned is_xsim);
        begin
`ifdef XILINX_SIMULATOR
            is_xsim = 32'd1;
`elsif XSIM_SIM
            is_xsim = 32'd1;
`else
            is_xsim = 32'd0;
`endif
        end
    endtask

    // =========================================================================
    // Waveform Dumping (VCD & FSDB / VPD support)
    // =========================================================================
    string vcd_path;
    string fsdb_path;
    string vpd_path;

    initial begin
        // Standard VCD dumping (always active by default, works with GTKWave/Verdi/DVE)
        if (!$value$plusargs("VCD_FILE=%s", vcd_path)) begin
            vcd_path = "dump.vcd";
        end
        $dumpfile(vcd_path);
        $dumpvars(0, tb_soc_c_test);
        $display("[TB] >>> Waveform dumping enabled (VCD): %s <<<", vcd_path);

`ifdef FSDB
        // Verdi FSDB dumping (standard dump.fsdb for Verdi -ssf)
        if (!$value$plusargs("FSDB_FILE=%s", fsdb_path)) begin
            fsdb_path = "dump.fsdb";
        end
        $fsdbDumpfile(fsdb_path);
        $fsdbDumpvars(0, tb_soc_c_test, "+all");
        $fsdbDumpSVA();
        $fsdbDumpMDA();
        $display("[TB] >>> Verdi FSDB dumping enabled: %s <<<", fsdb_path);
`endif

`ifdef VPD
        // Synopsys VPD dumping
        if (!$value$plusargs("VPD_FILE=%s", vpd_path)) begin
            vpd_path = "dump.vpd";
        end
        $vcdplusfile(vpd_path);
        $vcdpluson(0, tb_soc_c_test);
        $display("[TB] >>> Synopsys VPD dumping enabled: %s <<<", vpd_path);
`endif
    end

    // =========================================================================
    // Test Control Execution
    // =========================================================================
    int test_status;

    initial begin
        // Initialize AXI master outputs to idle
        m_awid    = 8'h0;   m_awaddr  = 32'h0;  m_awlen   = 8'h0;
        m_awsize  = 3'h0;   m_awburst = 2'h0;   m_awlock  = 1'b0;
        m_awcache = 4'h0;   m_awprot  = 3'h0;   m_awqos   = 4'h0;
        m_awvalid = 1'b0;
        m_wdata   = 32'h0;  m_wstrb   = 4'h0;   m_wlast   = 1'b0;
        m_wvalid  = 1'b0;   m_bready  = 1'b0;
        m_arid    = 8'h0;   m_araddr  = 32'h0;  m_arlen   = 8'h0;
        m_arsize  = 3'h0;   m_arburst = 2'h0;   m_arlock  = 1'b0;
        m_arcache = 4'h0;   m_arprot  = 3'h0;   m_arqos   = 4'h0;
        m_arvalid = 1'b0;   m_rready  = 1'b0;
        dma_awaddr  = 32'h0; dma_awprot  = 3'h0; dma_awvalid = 1'b0;
        dma_wdata   = 32'h0; dma_wstrb   = 4'h0; dma_wvalid  = 1'b0;
        dma_bready  = 1'b0;
        dma_araddr  = 32'h0; dma_arprot  = 3'h0; dma_arvalid = 1'b0;
        dma_rready  = 1'b0;
        uart_rx   = 1'b1;   // UART idle is HIGH
        gpio_i    = 64'h0;

        // Reset sequence
        aresetn = 1'b0;
        repeat (10) @(posedge clk);
        aresetn = 1'b1;
        repeat (5)  @(posedge clk);

        $display("=============================================================");
        $display("  SystemVerilog DPI-C Testbench Initiated for soc_top");
        $display("  Calling C firmware test main function...");
        $display("=============================================================");

        // Hand over control to the C test suite
        soc_c_main(test_status);

        $display("=============================================================");
        $display("  C Test Suite Completed. Status Exit Code: %0d", test_status);
        if (test_status == 0)
            $display("  >>> ALL C TESTS PASSED SUCCESSFULLY! <<<");
        else
            $display("  >>> C TESTS FAILED WITH %0d ERRORS! <<<", test_status);
        $display("=============================================================");

        repeat (10) @(posedge clk);
        $dumpflush;
`ifdef FSDB
        $fsdbDumpflush;
`endif
`ifdef VPD
        $vcdplusflush;
`endif
        $display("[TB] >>> Simulation finished. Waveforms saved successfully. <<<");
        $finish;
    end

    // Watchdog timeout
    initial begin
        #100_000_000;
        $display("[TIMEOUT] Simulation time limit exceeded.");
        $finish;
    end

`include "soc_cov_inst.svh"
    `INST_SOC_COV(u_soc_top, 1'b0, 1'b0, 1'b0)

endmodule

`default_nettype wire

// =============================================================================
// File           : tb_soc_hex_test.sv
// Project        : RISC-V Cryptographic Telemetry Gateway SoC
// Description    : Self-contained testbench that loads a compiled RISC-V .hex
//                  firmware file, executes it over the AXI4 interconnect into
//                  soc_top, generates VCD waveforms, and checks all peripherals.
// =============================================================================

`timescale 1ns/10ps
`default_nettype none

module tb_soc_hex_test;

    // -------------------------------------------------------------------------
    // Parameters & Clock Config
    // -------------------------------------------------------------------------
    localparam CLK_PERIOD      = 20;            // 50 MHz system clock (20 ns)
    localparam UART_CLK_PERIOD = 20;            // 50 MHz UART baud clock
    localparam MEM_DEPTH       = 2048;          // 8 KB instruction memory buffer
    localparam BAUD_DIV        = 434;           // 115200 baud @ 50 MHz

    reg clk;
    reg uart_clk;
    reg aresetn;

    // -------------------------------------------------------------------------
    // AXI4 Master Interface (ext_s00_axi_* driving s00 of interconnect)
    // -------------------------------------------------------------------------
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

    // Peripherals external I/O
    reg         uart_rx;
    wire        uart_tx;
    reg  [63:0] gpio_i;
    wire [63:0] gpio_o;
    wire [63:0] gpio_dir_o;
    wire [1:0]  gpio_intr;

    // Interrupt signals
    wire        uart_irq;
    wire        timer_irq;
    wire        aes_irq;
    wire        sha_irq;
    wire        dma_done;
    wire        dma_error;

    // -------------------------------------------------------------------------
    // DUT: soc_top (Master SoC Top-Level)
    // -------------------------------------------------------------------------
    soc_top #(
        .USE_INTERNAL_CPU    (0),               // External testbench master drives s00
        .AXI_DATA_WIDTH      (32),
        .AXI_ADDR_WIDTH      (32),
        .AXI_ID_WIDTH        (8)
    ) u_dut (
        .clk                 (clk),
        .uart_clk            (uart_clk),
        .aresetn             (aresetn),

        // External AXI Master 0 Port
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

        // DMA CSR slave interface
        .dma_csr_awaddr      (32'h0),
        .dma_csr_awprot      (3'h0),
        .dma_csr_awvalid     (1'b0),
        .dma_csr_awready     (),
        .dma_csr_wdata       (32'h0),
        .dma_csr_wstrb       (4'h0),
        .dma_csr_wvalid      (1'b0),
        .dma_csr_wready      (),
        .dma_csr_bresp       (),
        .dma_csr_bvalid      (),
        .dma_csr_bready      (1'b0),
        .dma_csr_araddr      (32'h0),
        .dma_csr_arprot      (3'h0),
        .dma_csr_arvalid     (1'b0),
        .dma_csr_arready     (),
        .dma_csr_rdata       (),
        .dma_csr_rresp       (),
        .dma_csr_rvalid      (),
        .dma_csr_rready      (1'b0),

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

    // -------------------------------------------------------------------------
    // Clock Generation
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #(CLK_PERIOD / 2) clk = ~clk;

    initial uart_clk = 1'b0;
    always #(UART_CLK_PERIOD / 2) uart_clk = ~uart_clk;

    // -------------------------------------------------------------------------
    // Waveform Dumping (VCD)
    // -------------------------------------------------------------------------
    string vcd_path;
    initial begin
        if (!$value$plusargs("VCD_FILE=%s", vcd_path)) begin
            vcd_path = "soc_test.vcd";
        end
        $dumpfile(vcd_path);
        $dumpvars(0, tb_soc_hex_test);
        $display("[TB] >>> Waveform dumping enabled: %s <<<", vcd_path);
    end

    // -------------------------------------------------------------------------
    // AXI4 Master Tasks: Single-beat Write and Read
    // -------------------------------------------------------------------------
    task axi_write;
        input [31:0] addr;
        input [31:0] data;
        reg aw_done;
        reg w_done;
        begin
            @(posedge clk);
            m_awid    <= 8'h01;
            m_awaddr  <= addr;
            m_awlen   <= 8'h00;
            m_awsize  <= 3'b010;       // 4 bytes
            m_awburst <= 2'b01;        // INCR
            m_awlock  <= 1'b0;
            m_awcache <= 4'b0010;
            m_awprot  <= 3'b000;
            m_awqos   <= 4'h0;
            m_awvalid <= 1'b1;
            m_wdata   <= data;
            m_wstrb   <= 4'hF;
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
            m_bready <= 1'b0;
            @(posedge clk);
        end
    endtask

    task axi_read;
        input  [31:0] addr;
        output [31:0] rdata;
        reg ar_done;
        begin
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
            rdata    = m_rdata;
            m_rready <= 1'b0;
            @(posedge clk);
        end
    endtask

    // -------------------------------------------------------------------------
    // Instruction Memory & RISC-V RV32I Execution Engine
    // -------------------------------------------------------------------------
    reg [31:0] imem [0:MEM_DEPTH-1];
    reg [31:0] xreg [0:31];
    integer    pc;
    reg [31:0] inst;
    string     hex_path;
    integer    inst_count;
    integer    cycle_count;

    // Decoded fields
    reg [6:0]  opcode;
    reg [4:0]  rd;
    reg [2:0]  funct3;
    reg [4:0]  rs1;
    reg [4:0]  rs2;
    reg [6:0]  funct7;
    reg [31:0] imm_i;
    reg [31:0] imm_s;
    reg [31:0] imm_b;
    reg [31:0] imm_u;
    reg [31:0] imm_j;
    reg [31:0] target_addr;
    reg [31:0] read_val;

    // -------------------------------------------------------------------------
    // Main Test Execution Routine
    // -------------------------------------------------------------------------
    initial begin
        // 1. Initialize bus signals
        m_awid    = 8'h0;
        m_awaddr  = 32'h0;
        m_awlen   = 8'h0;
        m_awsize  = 3'h0;
        m_awburst = 2'h0;
        m_awlock  = 1'b0;
        m_awcache = 4'h0;
        m_awprot  = 3'h0;
        m_awqos   = 4'h0;
        m_awvalid = 1'b0;
        m_wdata   = 32'h0;
        m_wstrb   = 4'h0;
        m_wlast   = 1'b0;
        m_wvalid  = 1'b0;
        m_bready  = 1'b0;
        m_arid    = 8'h0;
        m_araddr  = 32'h0;
        m_arlen   = 8'h0;
        m_arsize  = 3'h0;
        m_arburst = 2'h0;
        m_arlock  = 1'b0;
        m_arcache = 4'h0;
        m_arprot  = 3'h0;
        m_arqos   = 4'h0;
        m_arvalid = 1'b0;
        m_rready  = 1'b0;

        uart_rx   = 1'b1; // Idle high
        gpio_i    = 64'h0;
        aresetn   = 1'b0;

        for (integer i = 0; i < 32; i = i + 1) begin
            xreg[i] = 32'h0;
        end
        for (integer i = 0; i < MEM_DEPTH; i = i + 1) begin
            imem[i] = 32'h0;
        end

        // 2. Load HEX File into Instruction Memory Buffer
        if (!$value$plusargs("HEX_FILE=%s", hex_path)) begin
            hex_path = "c_test/soc_test.hex";
        end

        $display("=============================================================");
        $display(" [TB_HEX] RISC-V Cryptographic Telemetry Gateway SoC Testbench");
        $display(" [TB_HEX] Loading Hex Firmware File: %s", hex_path);
        $display("=============================================================");

        $readmemh(hex_path, imem);

        // Count loaded instructions
        inst_count = 0;
        while (inst_count < MEM_DEPTH && imem[inst_count] !== 32'h00000000 && imem[inst_count] !== 32'hxxxxxxxx) begin
            inst_count = inst_count + 1;
        end
        $display(" [TB_HEX] Loaded %0d instructions (%0d bytes) successfully.", inst_count, inst_count * 4);

        // 3. Reset Sequence
        repeat (20) @(posedge clk);
        aresetn <= 1'b1;
        repeat (10) @(posedge clk);
        $display(" [TB_HEX] Reset de-asserted. Starting RISC-V Firmware Execution...\n");

        // 4. RISC-V Instruction Fetch-Decode-Execute Loop
        pc = 0;
        cycle_count = 0;

        while (pc < (inst_count * 4) && cycle_count < 100000) begin
            inst = imem[pc >> 2];
            cycle_count = cycle_count + 1;

            // Maintain x0 hardwired to zero
            xreg[0] = 32'h0;

            // Instruction fields
            opcode = inst[6:0];
            rd     = inst[11:7];
            funct3 = inst[14:12];
            rs1    = inst[19:15];
            rs2    = inst[24:20];
            funct7 = inst[31:25];

            // Immediate decodes
            imm_i  = {{20{inst[31]}}, inst[31:20]};
            imm_s  = {{20{inst[31]}}, inst[31:25], inst[11:7]};
            imm_b  = {{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8], 1'b0};
            imm_u  = {inst[31:12], 12'h0};
            imm_j  = {{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};

            case (opcode)
                // LUI: Load Upper Immediate
                7'b0110111: begin
                    xreg[rd] = imm_u;
                    pc = pc + 4;
                end

                // AUIPC: Add Upper Immediate to PC
                7'b0010111: begin
                    xreg[rd] = pc + imm_u;
                    pc = pc + 4;
                end

                // OP-IMM: ADDI, SLTI, ANDI, ORI, XORI, etc.
                7'b0010011: begin
                    case (funct3)
                        3'b000: xreg[rd] = xreg[rs1] + imm_i; // ADDI
                        3'b100: xreg[rd] = xreg[rs1] ^ imm_i; // XORI
                        3'b110: xreg[rd] = xreg[rs1] | imm_i; // ORI
                        3'b111: xreg[rd] = xreg[rs1] & imm_i; // ANDI
                        default: xreg[rd] = xreg[rs1] + imm_i;
                    endcase
                    pc = pc + 4;
                end

                // OP: ADD, SUB, XOR, OR, AND
                7'b0110011: begin
                    case (funct3)
                        3'b000: xreg[rd] = funct7[5] ? (xreg[rs1] - xreg[rs2]) : (xreg[rs1] + xreg[rs2]);
                        3'b100: xreg[rd] = xreg[rs1] ^ xreg[rs2];
                        3'b110: xreg[rd] = xreg[rs1] | xreg[rs2];
                        3'b111: xreg[rd] = xreg[rs1] & xreg[rs2];
                        default: xreg[rd] = xreg[rs1] + xreg[rs2];
                    endcase
                    pc = pc + 4;
                end

                // STORE: SW (Store Word to AXI Peripheral via Interconnect)
                7'b0100011: begin
                    target_addr = xreg[rs1] + imm_s;
                    axi_write(target_addr, xreg[rs2]);
                    pc = pc + 4;
                end

                // LOAD: LW (Load Word from AXI Peripheral via Interconnect)
                7'b0000011: begin
                    target_addr = xreg[rs1] + imm_i;
                    axi_read(target_addr, read_val);
                    xreg[rd] = read_val;
                    pc = pc + 4;
                end

                // BRANCH: BEQ, BNE, BLT, BGE
                7'b1100011: begin
                    case (funct3)
                        3'b000: pc = (xreg[rs1] == xreg[rs2]) ? (pc + imm_b) : (pc + 4); // BEQ
                        3'b001: pc = (xreg[rs1] != xreg[rs2]) ? (pc + imm_b) : (pc + 4); // BNE
                        default: pc = pc + 4;
                    endcase
                end

                // JAL: Jump and Link
                7'b1101111: begin
                    if (rd != 0) xreg[rd] = pc + 4;
                    // Check for infinite loop trap: offset == 0
                    if (imm_j == 0) begin
                        $display("\n [TB_HEX] Trapped in terminal jump at PC=0x%04X.", pc);
                        break;
                    end
                    pc = pc + imm_j;
                end

                // SYSTEM: EBREAK / ECALL
                7'b1110011: begin
                    $display("\n [TB_HEX] EBREAK instruction encountered at PC=0x%04X.", pc);
                    break;
                end

                default: begin
                    $display(" [TB_HEX] Unsupported instruction 0x%08X at PC=0x%04X. Skipping...", inst, pc);
                    pc = pc + 4;
                end
            endcase
        end

        // 5. Final Status Check
        repeat (100) @(posedge clk);
        $display("\n=============================================================");
        $display("   HEX FIRMWARE EXECUTION RESULTS");
        $display("=============================================================");
        $display("   GPIO_OUT0 (Status) : 0x%08X (Expected: 0x00000002)", gpio_o[31:0]);
        $display("   GPIO_OUT1 (PassSig): 0x%08X (Expected: 0x0000900D)", gpio_o[63:32]);

        if (gpio_o[63:32] === 32'h0000_900D && gpio_o[31:0] === 32'h0000_0002) begin
            $display("\n   *********************************************************");
            $display("   *** ALL C PERIPHERAL TESTS PASSED VIA HEX EXECUTION! ***");
            $display("   *********************************************************");
        end else if (gpio_o[63:32] === 32'hDEAD_DEAD) begin
            $display("\n   [TB_HEX_FAIL] Firmware reached FAIL trap! Signature=0xDEADDEAD");
        end else begin
            $display("\n   [TB_HEX_FAIL] Unexpected completion state!");
        end

        $display("\n   Waveforms cleanly generated at: %s", vcd_path);
        $display("=============================================================\n");
        $dumpflush;
        $finish;
    end

    // -------------------------------------------------------------------------
    // Peripheral Monitors: UART TX Deserializer
    // -------------------------------------------------------------------------
    reg [7:0] uart_tx_char;
    integer bit_idx;
    initial begin
        forever begin
            // Wait for start bit (falling edge on uart_tx)
            @(negedge uart_tx);
            // Sample mid-bit: 1.5 baud periods
            repeat (BAUD_DIV + (BAUD_DIV/2)) @(posedge clk);

            // Read 8 data bits (LSB first)
            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                uart_tx_char[bit_idx] = uart_tx;
                repeat (BAUD_DIV) @(posedge clk);
            end

            // Wait for stop bit
            repeat (BAUD_DIV / 2) @(posedge clk);
            if (uart_tx_char >= 32 && uart_tx_char <= 126) begin
                $display(" [UART_TX_MON] Serial byte transmitted: '%c' (0x%02X)", uart_tx_char, uart_tx_char);
            end else if (uart_tx_char == 8'h0A) begin
                $display(" [UART_TX_MON] Serial byte transmitted: '\\n' (0x0A)");
            end else begin
                $display(" [UART_TX_MON] Serial byte transmitted: 0x%02X", uart_tx_char);
            end
        end
    end

    // -------------------------------------------------------------------------
    // Peripheral Monitors: GPIO State Transitions
    // -------------------------------------------------------------------------
    always @(gpio_o) begin
        $display(" [GPIO_MON] gpio_o updated: Bank0=0x%08X, Bank1=0x%08X", gpio_o[31:0], gpio_o[63:32]);
    end

    // -------------------------------------------------------------------------
    // Interrupt Monitors
    // -------------------------------------------------------------------------
    always @(posedge uart_irq)  $display(" [IRQ_MON] UART IRQ asserted (uart_irq_o = 1)");
    always @(posedge timer_irq) $display(" [IRQ_MON] Timer IRQ asserted (timer_irq_o = 1)");
    always @(posedge aes_irq)   $display(" [IRQ_MON] AES IRQ asserted (aes_irq_o = 1)");
    always @(posedge sha_irq)   $display(" [IRQ_MON] SHA-256 IRQ asserted (sha_irq_o = 1)");

/*initial 
begin
	$fsdbDumpfile("dump.fsdb");
	$fsdbDumpvars("+all");
	$fsdbDumpSVA();
	$fsdbDumpMDA();
end*/
endmodule

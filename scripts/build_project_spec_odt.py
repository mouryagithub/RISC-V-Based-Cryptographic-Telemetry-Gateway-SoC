#!/usr/bin/env python3
"""
build_project_spec_odt.py
Rebuilds doc/Project_spec.odt with consolidated, authoritative specifications
covering SoC architecture, signal list, memory map, peripheral registers,
data paths, and verification plan.
"""

import os
import sys
import zipfile
import base64
import subprocess

REPO_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
DOC_DIR = os.path.join(REPO_ROOT, "doc")
ORIGINAL_ODT = os.path.join(DOC_DIR, "Project_spec.odt")
TARGET_ODT = os.path.join(DOC_DIR, "Project_spec.odt")
TEMP_HTML = "/tmp/Project_spec_consolidated.html"
TEMP_ODT_DIR = "/tmp/spec_odt_build"

def extract_image_base64():
    # Extract original block diagram image from Project_spec.odt
    with zipfile.ZipFile(ORIGINAL_ODT, 'r') as z:
        for name in z.namelist():
            if 'Pictures/' in name and name.endswith('.png'):
                data = z.read(name)
                print(f"Extracted image {name} ({len(data)} bytes)")
                return base64.b64encode(data).decode('ascii')
    raise RuntimeError("No PNG image found in original Project_spec.odt!")

def generate_html(img_b64):
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>RISC-V Based Cryptographic Telemetry Gateway SoC — Consolidated Specification</title>
<style>
  @page {{
    size: A4;
    margin: 2cm 2cm 2cm 2cm;
  }}
  body {{
    font-family: "Liberation Sans", Arial, Helvetica, sans-serif;
    font-size: 10.5pt;
    line-height: 1.5;
    color: #2d3748;
  }}
  h1 {{
    font-size: 18pt;
    color: #1a365d;
    border-bottom: 2.5px solid #2b6cb0;
    padding-bottom: 5px;
    margin-top: 28pt;
    margin-bottom: 12pt;
    page-break-before: always;
  }}
  h1.first {{
    page-break-before: avoid;
    margin-top: 0;
  }}
  h2 {{
    font-size: 13.5pt;
    color: #2b6cb0;
    margin-top: 18pt;
    margin-bottom: 8pt;
    border-bottom: 1px solid #e2e8f0;
    padding-bottom: 3px;
  }}
  h3 {{
    font-size: 11.5pt;
    color: #2d3748;
    margin-top: 14pt;
    margin-bottom: 6pt;
  }}
  h4 {{
    font-size: 10.5pt;
    color: #4a5568;
    font-style: italic;
    margin-top: 10pt;
    margin-bottom: 4pt;
  }}
  p {{
    margin-top: 0;
    margin-bottom: 8pt;
    text-align: justify;
  }}
  ul, ol {{
    margin-top: 0;
    margin-bottom: 8pt;
    padding-left: 22px;
  }}
  li {{
    margin-bottom: 4pt;
  }}
  table {{
    width: 100%;
    border-collapse: collapse;
    margin-top: 8pt;
    margin-bottom: 14pt;
    font-size: 9.5pt;
  }}
  th {{
    background-color: #2b6cb0;
    color: #ffffff;
    font-weight: bold;
    text-align: left;
    padding: 6px 8px;
    border: 1px solid #2b6cb0;
  }}
  td {{
    padding: 5px 8px;
    border: 1px solid #cbd5e0;
    vertical-align: top;
  }}
  tr:nth-child(even) {{
    background-color: #f7fafc;
  }}
  .code, pre {{
    font-family: "Liberation Mono", "Courier New", monospace;
    font-size: 9pt;
    background-color: #edf2f7;
    border: 1px solid #cbd5e0;
    padding: 8px 12px;
    border-radius: 4px;
    white-space: pre-wrap;
    word-break: break-all;
    margin-top: 6pt;
    margin-bottom: 10pt;
  }}
  .callout {{
    background-color: #ebf8ff;
    border-left: 4px solid #3182ce;
    padding: 10px 14px;
    margin-top: 8pt;
    margin-bottom: 12pt;
    font-size: 10pt;
  }}
  .doc-title {{
    text-align: center;
    color: #1a365d;
    font-size: 24pt;
    font-weight: bold;
    margin-top: 30pt;
    margin-bottom: 8pt;
    line-height: 1.2;
  }}
  .doc-subtitle {{
    text-align: center;
    color: #4a5568;
    font-size: 14pt;
    font-weight: normal;
    margin-bottom: 24pt;
  }}
  .doc-meta {{
    text-align: center;
    color: #718096;
    font-size: 10pt;
    border-top: 1px solid #e2e8f0;
    border-bottom: 1px solid #e2e8f0;
    padding: 10px 0;
    margin-bottom: 30pt;
  }}
  .center {{
    text-align: center;
  }}
</style>
</head>
<body>

<div class="doc-title">RISC-V Based Cryptographic Telemetry Gateway SoC</div>
<div class="doc-subtitle">System Architecture, Signal Interface, Memory Map, Subsystem Register, and Functional Specification</div>
<div class="doc-meta">
  <strong>Document Version:</strong> 2.0 (Consolidated Technical Specification) &nbsp;|&nbsp;
  <strong>Core Architecture:</strong> Western Digital VeeR-EL2 (RV32IMC) &nbsp;|&nbsp;
  <strong>Interconnect:</strong> 64-bit AMBA AXI4 Crossbar &nbsp;|&nbsp;
  <strong>Date:</strong> November 2026
</div>

<h1 class="first">1. Introduction</h1>

<h2>1.1 Problem Statement &amp; Background</h2>
<p>
Modern embedded telemetry systems in aerospace, industrial automation, and defense applications require real-time, deterministic data ingestion coupled with rigorous cryptographic verification and encryption. When high-bandwidth telemetry streams are ingested, executing high-bandwidth stream hashing (SHA-256 for message authentication and integrity verification) and block cipher transformations (AES-256 CBC for confidentiality protection) entirely in software on a 32-bit RISC-V core consumes substantial processor execution cycles. This software compute bottleneck causes substantial processing latency, degrades real-time interrupt response, and limits achievable telemetry ingress throughput.
</p>

<h2>1.2 Purpose of the SoC</h2>
<p>
The <strong>Cryptographic Telemetry Gateway SoC</strong> is a custom System-on-Chip architected to offload bulk data movement and cryptographic compute overhead entirely from the central processor core. By combining an open-source 32-bit Western Digital VeeR EL2 RISC-V processor core (RV32IMC) with an autonomous 64-bit Direct Memory Access (DMA) controller, a shared 64 KB System SRAM frame buffer, and dedicated hardware accelerators for SHA-256 and AES-256, the SoC enables hardware-accelerated telemetry ingestion, integrity hashing, and payload encryption with minimal CPU intervention.
</p>

<h2>1.3 Key Architectural Objectives</h2>
<ul>
  <li><strong>Hardware Accelerator Offload:</strong> Execute payload integrity verification (SHA-256) and confidentiality enforcement (AES-256 in Cipher Block Chaining mode) on dedicated hardware blocks rather than consuming CPU execution cycles with software cryptographic loops.</li>
  <li><strong>Autonomous Data Movement:</strong> Employ an independent 64-bit AXI4 DMA controller to manage bulk data transfers between system memory and accelerator endpoints, minimizing core involvement in payload routing.</li>
  <li><strong>Bus Fabric Separation &amp; Protocol Adaptation:</strong> Carry both high-throughput data traffic and peripheral control-plane register configurations over a unified 64-bit AMBA AXI4 crossbar. Peripherals and accelerators with lightweight 32-bit register interfaces are accessed via AXI4-Lite subordinate ports through combinational AXI4-to-AXI4-Lite protocol bridges.</li>
  <li><strong>Event-Driven Exception Handling:</strong> Route timer, DMA, UART, GPIO, and cryptographic completion/error events directly into the VeeR EL2 core's Programmable Interrupt Controller (PIC) to notify the processor of hardware events deterministically.</li>
</ul>

<div class="callout">
  <strong>Design Highlight:</strong> The architecture cleanly decouples the 64-bit high-speed burst data planes (System SRAM, DMA engine, and Cryptographic FIFO endpoints) from the 32-bit peripheral control planes, ensuring that register configurations never bottleneck active high-bandwidth DMA cryptographic pipelines.
</div>

<h1>2. SoC Architecture Block Diagram</h1>

<p>
The control path defines how the Western Digital VeeR EL2 core orchestrates system operations across the unified AXI4/AXI4-Lite interconnect architecture. The diagram below illustrates the master-slave interconnect topology, the 64-bit AXI4 crossbar, the AXI4-to-AXI4-Lite bridge, the peripheral subsystem, and the hardware accelerators.
</p>

<div class="center" style="margin: 18pt 0;">
  <img src="data:image/png;base64,{img_b64}" style="width: 16.5cm; height: 11cm; object-fit: contain;" alt="RISC-V Cryptographic Telemetry Gateway SoC Architecture Diagram" />
  <p style="font-size: 9pt; color: #718096; margin-top: 6pt;"><em>Figure 2.1: Master SoC Architectural Interconnect and Subsystem Topology</em></p>
</div>

<p>
As illustrated in Figure 2.1, two AXI4 master agents drive transactions across the central crossbar:
</p>
<ol>
  <li><strong>Master 0 (s00):</strong> Western Digital VeeR EL2 Core Instruction Fetch and Load/Store Unit (LSU) interface.</li>
  <li><strong>Master 1 (s01):</strong> 64-bit Autonomous Direct Memory Access (DMA) Controller master interface.</li>
</ol>
<p>
The interconnect arbitrates concurrent accesses and routes transactions to system slaves including the 64 KB System SRAM, Boot ROM, the AXI4-Lite peripheral subsystem via protocol bridge, and dedicated cryptographic data streaming endpoints.
</p>

<h1>3. Complete SoC Signal and Interface Specification</h1>

<h2>1. External SoC Boundary Signals</h2>
<p>
The table below specifies the complete external physical boundary pinout of the SoC top-level module (<code>soc_top</code>), including system clocks, active-low reset, serial telemetry interface, 64-pin general purpose I/O, external interrupt observation lines, processor status, and external testbench master verification interfaces.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 20%;">Signal Name</th>
      <th style="width: 10%;">Direction</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 18%;">Source</th>
      <th style="width: 18%;">Destination</th>
      <th style="width: 26%;">Function &amp; Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>clk</strong> (sys_clk)</td>
      <td>Input</td>
      <td>1</td>
      <td>External Oscillator</td>
      <td>Clock Distribution Network</td>
      <td>Primary system clock (50 MHz / 100 MHz) for AXI4 crossbar, CPU core, DMA, and accelerators.</td>
    </tr>
    <tr>
      <td><strong>uart_clk</strong></td>
      <td>Input</td>
      <td>1</td>
      <td>External Oscillator</td>
      <td>UART Clock Network</td>
      <td>Dedicated fixed reference clock (50 MHz) for UART baud rate generator and serial FSMs.</td>
    </tr>
    <tr>
      <td><strong>aresetn</strong> (sys_rst_n)</td>
      <td>Input</td>
      <td>1</td>
      <td>External Power-On Reset</td>
      <td>Reset Distribution Network</td>
      <td>Global asynchronous active-low system reset. Distributed synchronously to all SoC blocks.</td>
    </tr>
    <tr>
      <td><strong>uart_rx</strong></td>
      <td>Input</td>
      <td>1</td>
      <td>External Host / Sensor</td>
      <td>UART Controller</td>
      <td>Asynchronous serial telemetry data ingress receive pin.</td>
    </tr>
    <tr>
      <td><strong>uart_tx</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>UART Controller</td>
      <td>External Host / Sensor</td>
      <td>Asynchronous serial telemetry data egress transmit pin.</td>
    </tr>
    <tr>
      <td><strong>gpio_i[63:0]</strong></td>
      <td>Input</td>
      <td>64</td>
      <td>External Package Pins</td>
      <td>GPIO Controller</td>
      <td>64-bit parallel raw digital inputs from external package pads (Bank 0: [31:0], Bank 1: [63:32]).</td>
    </tr>
    <tr>
      <td><strong>gpio_o[63:0]</strong></td>
      <td>Output</td>
      <td>64</td>
      <td>GPIO Controller</td>
      <td>External Package Pins</td>
      <td>64-bit parallel digital output drive lines to external package pads.</td>
    </tr>
    <tr>
      <td><strong>gpio_dir_o[63:0]</strong></td>
      <td>Output</td>
      <td>64</td>
      <td>GPIO Controller</td>
      <td>External IO Buffers</td>
      <td>64-bit parallel tri-state output drive enable control (1 = Output Drive, 0 = High-Z / Input).</td>
    </tr>
    <tr>
      <td><strong>uart_irq_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>UART Controller</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of UART RX/TX FIFO and line error interrupt line.</td>
    </tr>
    <tr>
      <td><strong>timer_irq_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>System Timer</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of 64-bit real-time counter compare match event.</td>
    </tr>
    <tr>
      <td><strong>aes_irq_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>AES Accelerator</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of AES cipher operation complete interrupt.</td>
    </tr>
    <tr>
      <td><strong>sha_irq_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>SHA Accelerator</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of SHA-256 digest computation valid interrupt.</td>
    </tr>
    <tr>
      <td><strong>dma_done_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>DMA Controller</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of DMA descriptor block transfer completed interrupt.</td>
    </tr>
    <tr>
      <td><strong>dma_error_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>DMA Controller</td>
      <td>External Observation Pin</td>
      <td>Direct external observation of DMA AXI bus transfer fault (SLVERR/DECERR) interrupt.</td>
    </tr>
    <tr>
      <td><strong>gpio_intr_o[1:0]</strong></td>
      <td>Output</td>
      <td>2</td>
      <td>GPIO Controller</td>
      <td>External Observation Pins</td>
      <td>Direct external observation of GPIO edge/level interrupt triggers ([0]=Bank 0, [1]=Bank 1).</td>
    </tr>
    <tr>
      <td><strong>cpu_halt_status_o</strong></td>
      <td>Output</td>
      <td>1</td>
      <td>VeeR EL2 Core</td>
      <td>External Debug Header</td>
      <td>Processor execution status (asserts when core is in low-power halt or debug mode).</td>
    </tr>
    <tr>
      <td><strong>ext_s00_axi_*</strong></td>
      <td>Input / Output</td>
      <td>Bus</td>
      <td>External Testbench VIP</td>
      <td>AXI Crossbar Master 0</td>
      <td>External AXI4 Master 0 port (5 channels) enabled when <code>USE_INTERNAL_CPU = 0</code>.</td>
    </tr>
    <tr>
      <td><strong>dma_csr_*</strong></td>
      <td>Input / Output</td>
      <td>Bus</td>
      <td>External Testbench / CPU</td>
      <td>DMA Controller Slave</td>
      <td>External 32-bit AXI4-Lite DMA CSR direct configuration port for verification bypass.</td>
    </tr>
  </tbody>
</table>

<h2>2. VeeR EL2 ↔ ICCM Interface</h2>
<table>
  <thead>
    <tr>
      <th>Signal Name</th><th>Direction</th><th>Width</th><th>Source</th><th>Destination</th><th>Function</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>iccm_clken</td><td>Output</td><td>1</td><td>VeeR EL2</td><td>ICCM</td><td>ICCM memory access enable strobe.</td></tr>
    <tr><td>iccm_rw</td><td>Output</td><td>1</td><td>VeeR EL2</td><td>ICCM</td><td>ICCM read/write access direction control (1 = Write, 0 = Read).</td></tr>
    <tr><td>iccm_addr</td><td>Output</td><td>19</td><td>VeeR EL2</td><td>ICCM</td><td>ICCM word address bus (128 KB addressable range).</td></tr>
    <tr><td>iccm_wdata</td><td>Output</td><td>39</td><td>VeeR EL2</td><td>ICCM</td><td>Write data payload including 7-bit SECDED ECC parity bits.</td></tr>
    <tr><td>iccm_rdata</td><td>Input</td><td>39</td><td>ICCM</td><td>VeeR EL2</td><td>Read data payload including 7-bit SECDED ECC parity bits.</td></tr>
  </tbody>
</table>

<h2>3. VeeR EL2 ↔ DCCM Interface</h2>
<table>
  <thead>
    <tr>
      <th>Signal Name</th><th>Direction</th><th>Width</th><th>Source</th><th>Destination</th><th>Function</th>
    </tr>
  </thead>
  <tbody>
    <tr><td>dccm_clken</td><td>Output</td><td>1</td><td>VeeR EL2</td><td>DCCM</td><td>DCCM memory access enable strobe.</td></tr>
    <tr><td>dccm_rw</td><td>Output</td><td>1</td><td>VeeR EL2</td><td>DCCM</td><td>DCCM read/write access direction control (1 = Write, 0 = Read).</td></tr>
    <tr><td>dccm_addr</td><td>Output</td><td>16</td><td>VeeR EL2</td><td>DCCM</td><td>DCCM word address bus (128 KB addressable range).</td></tr>
    <tr><td>dccm_wdata</td><td>Output</td><td>39</td><td>VeeR EL2</td><td>DCCM</td><td>Write data payload including ECC protection.</td></tr>
    <tr><td>dccm_byteen</td><td>Output</td><td>4</td><td>VeeR EL2</td><td>DCCM</td><td>Individual byte lane write strobe enables.</td></tr>
    <tr><td>dccm_rdata</td><td>Input</td><td>39</td><td>DCCM</td><td>VeeR EL2</td><td>Read data payload including ECC protection.</td></tr>
  </tbody>
</table>

<h2>4. VeeR EL2 ↔ AXI4 Interconnect (Master Port S00)</h2>

<h3>Write Address Channel</h3>
<table>
  <thead>
    <tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr>
  </thead>
  <tbody>
    <tr><td>lsu_axi_awid</td><td>Output</td><td>3</td><td>AXI4 write transaction identification tag.</td></tr>
    <tr><td>lsu_axi_awaddr</td><td>Output</td><td>32</td><td>Target memory write start address.</td></tr>
    <tr><td>lsu_axi_awlen</td><td>Output</td><td>8</td><td>Burst length (number of data transfers minus 1).</td></tr>
    <tr><td>lsu_axi_awsize</td><td>Output</td><td>3</td><td>Burst beat size in bytes (e.g., 3'b011 = 8 bytes / 64-bit).</td></tr>
    <tr><td>lsu_axi_awburst</td><td>Output</td><td>2</td><td>Burst type (2'b01 = INCR incremental burst).</td></tr>
    <tr><td>lsu_axi_awlock</td><td>Output</td><td>1</td><td>Atomic access lock indicator.</td></tr>
    <tr><td>lsu_axi_awcache</td><td>Output</td><td>4</td><td>Memory bufferability and cacheability attributes.</td></tr>
    <tr><td>lsu_axi_awprot</td><td>Output</td><td>3</td><td>Privilege level and security access protection.</td></tr>
    <tr><td>lsu_axi_awvalid</td><td>Output</td><td>1</td><td>Write address channel handshake valid flag.</td></tr>
    <tr><td>lsu_axi_awready</td><td>Input</td><td>1</td><td>Write address channel handshake ready from interconnect.</td></tr>
  </tbody>
</table>

<h3>Write Data Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>lsu_axi_wdata</td><td>Output</td><td>64</td><td>64-bit primary write data bus payload.</td></tr>
    <tr><td>lsu_axi_wstrb</td><td>Output</td><td>8</td><td>8-bit individual byte lane write strobes.</td></tr>
    <tr><td>lsu_axi_wlast</td><td>Output</td><td>1</td><td>Indicates final transfer beat in an AXI burst sequence.</td></tr>
    <tr><td>lsu_axi_wvalid</td><td>Output</td><td>1</td><td>Write data channel handshake valid flag.</td></tr>
    <tr><td>lsu_axi_wready</td><td>Input</td><td>1</td><td>Write data channel handshake ready from slave.</td></tr>
  </tbody>
</table>

<h3>Write Response Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>lsu_axi_bid</td><td>Input</td><td>3</td><td>Response transaction identification tag match.</td></tr>
    <tr><td>lsu_axi_bresp</td><td>Input</td><td>2</td><td>Write status response (2'b00=OKAY, 2'b10=SLVERR, 2'b11=DECERR).</td></tr>
    <tr><td>lsu_axi_bvalid</td><td>Input</td><td>1</td><td>Write response valid strobe from slave.</td></tr>
    <tr><td>lsu_axi_bready</td><td>Output</td><td>1</td><td>Master ready to accept write completion response.</td></tr>
  </tbody>
</table>

<h3>Read Address Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>lsu_axi_arid</td><td>Output</td><td>3</td><td>AXI4 read transaction identification tag.</td></tr>
    <tr><td>lsu_axi_araddr</td><td>Output</td><td>32</td><td>Target memory read start address.</td></tr>
    <tr><td>lsu_axi_arlen</td><td>Output</td><td>8</td><td>Burst length (number of beats minus 1).</td></tr>
    <tr><td>lsu_axi_arsize</td><td>Output</td><td>3</td><td>Burst beat size (3'b011 = 8 bytes / 64-bit).</td></tr>
    <tr><td>lsu_axi_arburst</td><td>Output</td><td>2</td><td>Burst type (2'b01 = INCR incremental burst).</td></tr>
    <tr><td>lsu_axi_arlock</td><td>Output</td><td>1</td><td>Atomic read lock indicator.</td></tr>
    <tr><td>lsu_axi_arcache</td><td>Output</td><td>4</td><td>Memory cacheability attributes.</td></tr>
    <tr><td>lsu_axi_arprot</td><td>Output</td><td>3</td><td>Privilege level and security access protection.</td></tr>
    <tr><td>lsu_axi_arvalid</td><td>Output</td><td>1</td><td>Read address channel handshake valid flag.</td></tr>
    <tr><td>lsu_axi_arready</td><td>Input</td><td>1</td><td>Read address channel handshake ready from interconnect.</td></tr>
  </tbody>
</table>

<h3>Read Data Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>lsu_axi_rid</td><td>Input</td><td>3</td><td>Read data transaction identification tag match.</td></tr>
    <tr><td>lsu_axi_rdata</td><td>Input</td><td>64</td><td>64-bit primary read data bus payload.</td></tr>
    <tr><td>lsu_axi_rresp</td><td>Input</td><td>2</td><td>Read status response code.</td></tr>
    <tr><td>lsu_axi_rlast</td><td>Input</td><td>1</td><td>Indicates final transfer beat in a read burst sequence.</td></tr>
    <tr><td>lsu_axi_rvalid</td><td>Input</td><td>1</td><td>Read data channel handshake valid flag from slave.</td></tr>
    <tr><td>lsu_axi_rready</td><td>Output</td><td>1</td><td>Master ready to accept incoming read data beat.</td></tr>
  </tbody>
</table>

<h2>5. DMA ↔ AXI4 Interconnect (Master Port S01)</h2>

<h3>Write Address Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>dma_m_axi_awaddr</td><td>Output</td><td>32</td><td>DMA autonomous write target address.</td></tr>
    <tr><td>dma_m_axi_awlen</td><td>Output</td><td>8</td><td>DMA write burst length (up to 256 beats per transaction).</td></tr>
    <tr><td>dma_m_axi_awsize</td><td>Output</td><td>3</td><td>DMA write transfer beat size (64-bit = 3'b011).</td></tr>
    <tr><td>dma_m_axi_awburst</td><td>Output</td><td>2</td><td>Burst type (2'b01 = INCR incremental mode).</td></tr>
    <tr><td>dma_m_axi_awvalid</td><td>Output</td><td>1</td><td>DMA write address valid handshake strobe.</td></tr>
    <tr><td>dma_m_axi_awready</td><td>Input</td><td>1</td><td>Crossbar accepts DMA write address.</td></tr>
  </tbody>
</table>

<h3>Write Data Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>dma_m_axi_wdata</td><td>Output</td><td>64</td><td>DMA 64-bit payload data stream.</td></tr>
    <tr><td>dma_m_axi_wstrb</td><td>Output</td><td>8</td><td>Active byte lane write strobes.</td></tr>
    <tr><td>dma_m_axi_wlast</td><td>Output</td><td>1</td><td>Last beat indicator for DMA burst block.</td></tr>
    <tr><td>dma_m_axi_wvalid</td><td>Output</td><td>1</td><td>DMA write data valid handshake strobe.</td></tr>
    <tr><td>dma_m_axi_wready</td><td>Input</td><td>1</td><td>Target slave ready to receive DMA data beat.</td></tr>
  </tbody>
</table>

<h3>Write Response Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>dma_m_axi_bresp</td><td>Input</td><td>2</td><td>Write status response code from target memory/slave.</td></tr>
    <tr><td>dma_m_axi_bvalid</td><td>Input</td><td>1</td><td>Write response valid handshake strobe.</td></tr>
    <tr><td>dma_m_axi_bready</td><td>Output</td><td>1</td><td>DMA engine ready to retire write response.</td></tr>
  </tbody>
</table>

<h3>Read Address Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>dma_m_axi_araddr</td><td>Output</td><td>32</td><td>DMA autonomous read source address.</td></tr>
    <tr><td>dma_m_axi_arlen</td><td>Output</td><td>8</td><td>DMA read burst length (up to 256 beats).</td></tr>
    <tr><td>dma_m_axi_arsize</td><td>Output</td><td>3</td><td>DMA read transfer beat size (64-bit = 3'b011).</td></tr>
    <tr><td>dma_m_axi_arburst</td><td>Output</td><td>2</td><td>Burst type (2'b01 = INCR incremental mode).</td></tr>
    <tr><td>dma_m_axi_arvalid</td><td>Output</td><td>1</td><td>DMA read address valid handshake strobe.</td></tr>
    <tr><td>dma_m_axi_arready</td><td>Input</td><td>1</td><td>Crossbar accepts DMA read address.</td></tr>
  </tbody>
</table>

<h3>Read Data Channel</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>dma_m_axi_rdata</td><td>Input</td><td>64</td><td>DMA 64-bit read payload streamed from source slave.</td></tr>
    <tr><td>dma_m_axi_rresp</td><td>Input</td><td>2</td><td>Read status response code.</td></tr>
    <tr><td>dma_m_axi_rlast</td><td>Input</td><td>1</td><td>Last read beat indicator in burst transfer.</td></tr>
    <tr><td>dma_m_axi_rvalid</td><td>Input</td><td>1</td><td>Read data valid handshake strobe from slave.</td></tr>
    <tr><td>dma_m_axi_rready</td><td>Output</td><td>1</td><td>DMA engine ready to accept incoming data beat.</td></tr>
  </tbody>
</table>

<h2>6. AXI4 ↔ System SRAM (Slave Port M00)</h2>
<table>
  <thead><tr><th>Signal Group</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>AXI4 Write Address (aw*)</td><td>Interconnect → SRAM</td><td>32-bit addr, 8-bit len</td><td>SRAM write addressing, burst control, and handshake.</td></tr>
    <tr><td>AXI4 Write Data (w*)</td><td>Interconnect → SRAM</td><td>64-bit data, 8-bit strb</td><td>64-bit high-throughput SRAM write payload and byte enables.</td></tr>
    <tr><td>AXI4 Write Response (b*)</td><td>SRAM → Interconnect</td><td>2-bit bresp</td><td>SRAM write completion acknowledgement.</td></tr>
    <tr><td>AXI4 Read Address (ar*)</td><td>Interconnect → SRAM</td><td>32-bit addr, 8-bit len</td><td>SRAM read addressing, burst length, and handshake.</td></tr>
    <tr><td>AXI4 Read Data (r*)</td><td>SRAM → Interconnect</td><td>64-bit data, 2-bit resp</td><td>64-bit burst read data returned from shared memory.</td></tr>
  </tbody>
</table>

<h2>7. AXI4 ↔ SHA-256 Accelerator Data Plane (Slave Port M05)</h2>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>sha_axi_awaddr</td><td>Input</td><td>32</td><td>SHA streaming write destination address (0x9000_0030).</td></tr>
    <tr><td>sha_axi_awlen</td><td>Input</td><td>8</td><td>Write burst length (8 beats = 64 bytes = 512-bit block).</td></tr>
    <tr><td>sha_axi_awsize</td><td>Input</td><td>3</td><td>Write beat transfer size (64-bit = 3'b011).</td></tr>
    <tr><td>sha_axi_awburst</td><td>Input</td><td>2</td><td>Burst mode (2'b01 = INCR).</td></tr>
    <tr><td>sha_axi_awvalid</td><td>Input</td><td>1</td><td>Address valid handshake from crossbar.</td></tr>
    <tr><td>sha_axi_awready</td><td>Output</td><td>1</td><td>SHA data-in FIFO accepts write address.</td></tr>
    <tr><td>sha_axi_wdata</td><td>Input</td><td>64</td><td>64-bit telemetry message block data beat.</td></tr>
    <tr><td>sha_axi_wstrb</td><td>Input</td><td>8</td><td>Byte lane active strobes.</td></tr>
    <tr><td>sha_axi_wlast</td><td>Input</td><td>1</td><td>Indicates final beat of 512-bit message block.</td></tr>
    <tr><td>sha_axi_wvalid</td><td>Input</td><td>1</td><td>Write data beat valid handshake.</td></tr>
    <tr><td>sha_axi_wready</td><td>Output</td><td>1</td><td>SHA data FIFO accepts data beat.</td></tr>
    <tr><td>sha_axi_bresp</td><td>Output</td><td>2</td><td>Write status response code.</td></tr>
    <tr><td>sha_axi_bvalid</td><td>Output</td><td>1</td><td>Write response valid handshake.</td></tr>
    <tr><td>sha_axi_bready</td><td>Input</td><td>1</td><td>Master accepts write response.</td></tr>
  </tbody>
</table>

<h2>8. AXI4 ↔ AES-256 CBC Accelerator Data Plane (Ports M03 &amp; M04)</h2>

<h3>Input Data Interface (Slave Port M03)</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>aes_axi_awaddr</td><td>Input</td><td>32</td><td>AES streaming write target address (0x9000_0010).</td></tr>
    <tr><td>aes_axi_awlen</td><td>Input</td><td>8</td><td>Write burst length (2 beats = 16 bytes = 128-bit block).</td></tr>
    <tr><td>aes_axi_awsize</td><td>Input</td><td>3</td><td>Write beat transfer size (64-bit = 3'b011).</td></tr>
    <tr><td>aes_axi_awburst</td><td>Input</td><td>2</td><td>Burst mode (2'b01 = INCR).</td></tr>
    <tr><td>aes_axi_awvalid</td><td>Input</td><td>1</td><td>Address valid handshake from crossbar.</td></tr>
    <tr><td>aes_axi_awready</td><td>Output</td><td>1</td><td>AES data input FIFO accepts write address.</td></tr>
    <tr><td>aes_axi_wdata</td><td>Input</td><td>64</td><td>64-bit telemetry plaintext block data beat.</td></tr>
    <tr><td>aes_axi_wstrb</td><td>Input</td><td>8</td><td>Byte lane active strobes.</td></tr>
    <tr><td>aes_axi_wlast</td><td>Input</td><td>1</td><td>Indicates final 64-bit beat of 128-bit block.</td></tr>
    <tr><td>aes_axi_wvalid</td><td>Input</td><td>1</td><td>Write data beat valid handshake.</td></tr>
    <tr><td>aes_axi_wready</td><td>Output</td><td>1</td><td>AES input FIFO accepts incoming data beat.</td></tr>
    <tr><td>aes_axi_bresp</td><td>Output</td><td>2</td><td>Write status response code.</td></tr>
    <tr><td>aes_axi_bvalid</td><td>Output</td><td>1</td><td>Write response valid handshake.</td></tr>
    <tr><td>aes_axi_bready</td><td>Input</td><td>1</td><td>Master accepts write response.</td></tr>
  </tbody>
</table>

<h3>Output Data Interface (Slave Port M04)</h3>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>aes_axi_araddr</td><td>Input</td><td>32</td><td>AES streaming read target address (0x9000_0020).</td></tr>
    <tr><td>aes_axi_arvalid</td><td>Input</td><td>1</td><td>Read address valid handshake.</td></tr>
    <tr><td>aes_axi_arready</td><td>Output</td><td>1</td><td>AES output FIFO accepts read address.</td></tr>
    <tr><td>aes_axi_rdata</td><td>Output</td><td>64</td><td>64-bit encrypted ciphertext block data beat.</td></tr>
    <tr><td>aes_axi_rvalid</td><td>Output</td><td>1</td><td>Read data beat valid handshake from AES output FIFO.</td></tr>
    <tr><td>aes_axi_rready</td><td>Input</td><td>1</td><td>Master accepts incoming ciphertext beat.</td></tr>
    <tr><td>aes_axi_rlast</td><td>Output</td><td>1</td><td>Indicates final beat in ciphertext block transfer.</td></tr>
  </tbody>
</table>

<h2>9. AXI4-Lite Peripheral Control Subsystem (Slave Port M02)</h2>
<p>
The 64-bit AXI4 crossbar connects to an AXI-to-AXI-Lite protocol adaptation bridge (<code>axi_to_axilite_bridge.v</code>). The bridge strips full-AXI burst overhead, passes through 32-bit word addresses, truncates transaction IDs, and drives <code>rlast = 1'b1</code> for single-beat register accesses. The peripheral control bus fans out across memory-mapped endpoints:
</p>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>peri_axi_awaddr</td><td>Output</td><td>32</td><td>Peripheral memory-mapped register write address.</td></tr>
    <tr><td>peri_axi_awvalid</td><td>Output</td><td>1</td><td>Peripheral write address valid handshake.</td></tr>
    <tr><td>peri_axi_awready</td><td>Input</td><td>1</td><td>Target peripheral accepts write address.</td></tr>
    <tr><td>peri_axi_wdata</td><td>Output</td><td>32</td><td>32-bit register write data.</td></tr>
    <tr><td>peri_axi_wstrb</td><td>Output</td><td>4</td><td>4-bit byte-enable write strobes.</td></tr>
    <tr><td>peri_axi_wvalid</td><td>Output</td><td>1</td><td>Write data valid handshake.</td></tr>
    <tr><td>peri_axi_wready</td><td>Input</td><td>1</td><td>Target peripheral accepts write data.</td></tr>
    <tr><td>peri_axi_bresp</td><td>Input</td><td>2</td><td>Register write response status (2'b00 = OKAY).</td></tr>
    <tr><td>peri_axi_bvalid</td><td>Input</td><td>1</td><td>Write response valid handshake.</td></tr>
    <tr><td>peri_axi_bready</td><td>Output</td><td>1</td><td>Bridge accepts write response.</td></tr>
    <tr><td>peri_axi_araddr</td><td>Output</td><td>32</td><td>Peripheral memory-mapped register read address.</td></tr>
    <tr><td>peri_axi_arvalid</td><td>Output</td><td>1</td><td>Peripheral read address valid handshake.</td></tr>
    <tr><td>peri_axi_arready</td><td>Input</td><td>1</td><td>Target peripheral accepts read address.</td></tr>
    <tr><td>peri_axi_rdata</td><td>Input</td><td>32</td><td>32-bit register read data.</td></tr>
    <tr><td>peri_axi_rresp</td><td>Input</td><td>2</td><td>Register read response status (2'b00 = OKAY).</td></tr>
    <tr><td>peri_axi_rvalid</td><td>Input</td><td>1</td><td>Read data valid handshake from peripheral.</td></tr>
    <tr><td>peri_axi_rready</td><td>Output</td><td>1</td><td>Bridge accepts read data word.</td></tr>
  </tbody>
</table>

<h2>10. Complete SoC Interrupt Mapping &amp; PIC Vector Assignments</h2>
<p>
All peripheral interrupt request (IRQ) output lines are routed directly into the Western Digital VeeR-EL2 Programmable Interrupt Controller (PIC) gateway inputs (<code>extintsrc_req[8:1]</code>). The table below specifies the prioritized interrupt architecture:
</p>

<table>
  <thead>
    <tr>
      <th style="width: 8%;">IRQ #</th>
      <th style="width: 18%;">Source Module</th>
      <th style="width: 14%;">Signal Name</th>
      <th style="width: 12%;">Trigger Type</th>
      <th style="width: 10%;">Priority</th>
      <th style="width: 16%;">PIC Vector Reg</th>
      <th style="width: 22%;">Functional Trigger Event</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>IRQ 1</strong></td>
      <td>UART Controller</td>
      <td><code>uart_irq</code></td>
      <td>Level / High</td>
      <td>5</td>
      <td>0xF00C_0004</td>
      <td>RX FIFO data available / Line status error / TX holding register empty.</td>
    </tr>
    <tr>
      <td><strong>IRQ 2</strong></td>
      <td>System Timer</td>
      <td><code>timer_intr[0]</code></td>
      <td>Level / High</td>
      <td>7</td>
      <td>0xF00C_0008</td>
      <td>64-bit real-time counter compare match threshold reached.</td>
    </tr>
    <tr>
      <td><strong>IRQ 3</strong></td>
      <td>AES-256 Accelerator</td>
      <td><code>aes_irq</code></td>
      <td>Edge / Rising</td>
      <td>6</td>
      <td>0xF00C_000C</td>
      <td>AES CBC cipher operation complete across all programmed blocks.</td>
    </tr>
    <tr>
      <td><strong>IRQ 4</strong></td>
      <td>SHA-256 Accelerator</td>
      <td><code>sha_irq</code></td>
      <td>Edge / Rising</td>
      <td>6</td>
      <td>0xF00C_0010</td>
      <td>SHA-256 message digest calculation complete and valid.</td>
    </tr>
    <tr>
      <td><strong>IRQ 5</strong></td>
      <td>DMA Controller</td>
      <td><code>dma_done_o</code></td>
      <td>Edge / Rising</td>
      <td>8</td>
      <td>0xF00C_0014</td>
      <td>DMA block transfer finished across all enabled descriptors.</td>
    </tr>
    <tr>
      <td><strong>IRQ 6</strong></td>
      <td>DMA Controller</td>
      <td><code>dma_error_o</code></td>
      <td>Edge / Rising</td>
      <td>15 (Max)</td>
      <td>0xF00C_0018</td>
      <td>DMA AXI bus fault detected (SLVERR or DECERR abort).</td>
    </tr>
    <tr>
      <td><strong>IRQ 7</strong></td>
      <td>GPIO Bank 0</td>
      <td><code>gpio_intr[0]</code></td>
      <td>Level / Edge</td>
      <td>4</td>
      <td>0xF00C_001C</td>
      <td>GPIO Pins [31:0] edge or level event detected.</td>
    </tr>
    <tr>
      <td><strong>IRQ 8</strong></td>
      <td>GPIO Bank 1</td>
      <td><code>gpio_intr[1]</code></td>
      <td>Level / Edge</td>
      <td>4</td>
      <td>0xF00C_0020</td>
      <td>GPIO Pins [63:32] edge or level event detected.</td>
    </tr>
  </tbody>
</table>

<h2>11. Internal Clock and Reset Signals</h2>
<table>
  <thead><tr><th>Signal Name</th><th>Direction</th><th>Width</th><th>Source</th><th>Destination</th><th>Function</th></tr></thead>
  <tbody>
    <tr><td>clk</td><td>Internal</td><td>1</td><td>Clock Distribution</td><td>All SoC Blocks</td><td>Distributed 50/100 MHz synchronous system clock.</td></tr>
    <tr><td>uart_clk</td><td>Internal</td><td>1</td><td>Clock Distribution</td><td>UART Controller</td><td>Distributed 50 MHz baud-rate reference clock.</td></tr>
    <tr><td>rst_n</td><td>Internal</td><td>1</td><td>Reset Generator</td><td>All Peripheral Blocks</td><td>Distributed active-low synchronous reset (aresetn).</td></tr>
    <tr><td>rst</td><td>Internal</td><td>1</td><td>Reset Inverter</td><td>AXI Crossbar Core</td><td>Distributed active-high reset (rst = ~aresetn) required by interconnect core.</td></tr>
  </tbody>
</table>

<h1>4. Master System Address Map &amp; Memory Architecture</h1>

<h2>4.1 Global 4 GB SoC Memory Map</h2>
<p>
The 32-bit physical address space (4 GB) is partitioned into functional regions optimized for low-latency CPU local memory execution, high-bandwidth streaming DMA transfers, and memory-mapped peripheral control.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 14%;">Base Address</th>
      <th style="width: 14%;">End Address</th>
      <th style="width: 8%;">Size</th>
      <th style="width: 14%;">Bus Interface</th>
      <th style="width: 6%;">Port</th>
      <th style="width: 8%;">Access</th>
      <th style="width: 10%;">Master</th>
      <th style="width: 26%;">Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x0000_0000</code></td>
      <td><code>0x0000_FFFF</code></td>
      <td>64 KB</td>
      <td>AXI4 (64-bit)</td>
      <td>m00</td>
      <td>R/W</td>
      <td>CPU, DMA</td>
      <td><strong>System SRAM:</strong> Shared telemetry frame buffer, DMA staging area, packet queue.</td>
    </tr>
    <tr>
      <td><code>0x4000_0000</code></td>
      <td><code>0x4000_00FF</code></td>
      <td>256 B</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU, DMA</td>
      <td><strong>AES-256 Accelerator:</strong> Control, status, 256-bit keys, IV, block count registers.</td>
    </tr>
    <tr>
      <td><code>0x4000_1000</code></td>
      <td><code>0x4000_10FF</code></td>
      <td>256 B</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU</td>
      <td><strong>UART Controller:</strong> 16550-compatible serial port, 16-byte FIFOs, baud divisor.</td>
    </tr>
    <tr>
      <td><code>0x4000_2000</code></td>
      <td><code>0x4000_2FFF</code></td>
      <td>4 KB</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU</td>
      <td><strong>System Timer (rv_timer):</strong> 64-bit real-time counter, prescaler, comparator.</td>
    </tr>
    <tr>
      <td><code>0x4000_3000</code></td>
      <td><code>0x4000_3FFF</code></td>
      <td>4 KB</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU</td>
      <td><strong>GPIO Controller:</strong> 64 General-Purpose I/O pins, atomic set/clear/toggle, IRQs.</td>
    </tr>
    <tr>
      <td><code>0x4000_4000</code></td>
      <td><code>0x4000_40FF</code></td>
      <td>256 B</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU, DMA</td>
      <td><strong>SHA-256 Hash Accelerator:</strong> Control, status, 512-bit block buffer, 256-bit digest.</td>
    </tr>
    <tr>
      <td><code>0x4000_5000</code></td>
      <td><code>0x4000_50FF</code></td>
      <td>256 B</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>R/W</td>
      <td>CPU</td>
      <td><strong>DMA Controller:</strong> Control, status, fault address, dual 64-bit descriptors.</td>
    </tr>
    <tr>
      <td><code>0x4000_6000</code></td>
      <td><code>0x4FFF_FFFF</code></td>
      <td>~256 MB</td>
      <td>AXI4-Lite (32-bit)</td>
      <td>m02</td>
      <td>—</td>
      <td>—</td>
      <td><em>Reserved Peripheral Expansion Space.</em></td>
    </tr>
    <tr>
      <td><code>0x8000_0000</code></td>
      <td><code>0x8000_0FFF</code></td>
      <td>4 KB</td>
      <td>AXI4 (64-bit)</td>
      <td>m01</td>
      <td>R/X</td>
      <td>CPU</td>
      <td><strong>Boot ROM / Reset Vector:</strong> Power-on reset entry point, primary bootloader.</td>
    </tr>
    <tr>
      <td><code>0x9000_0010</code></td>
      <td><code>0x9000_001F</code></td>
      <td>16 B</td>
      <td>AXI4 (64-bit)</td>
      <td>m03</td>
      <td>W</td>
      <td>CPU, DMA</td>
      <td><strong>AES-256 Data In Endpoint:</strong> High-speed burst streaming write target FIFO.</td>
    </tr>
    <tr>
      <td><code>0x9000_0020</code></td>
      <td><code>0x9000_002F</code></td>
      <td>16 B</td>
      <td>AXI4 (64-bit)</td>
      <td>m04</td>
      <td>R</td>
      <td>CPU, DMA</td>
      <td><strong>AES-256 Data Out Endpoint:</strong> High-speed burst streaming read target FIFO.</td>
    </tr>
    <tr>
      <td><code>0x9000_0030</code></td>
      <td><code>0x9000_003F</code></td>
      <td>16 B</td>
      <td>AXI4 (64-bit)</td>
      <td>m05</td>
      <td>W</td>
      <td>CPU, DMA</td>
      <td><strong>SHA-256 Data In Endpoint:</strong> High-speed burst streaming write target FIFO.</td>
    </tr>
  </tbody>
</table>

<h2>4.2 System SRAM Memory Map &amp; Partitioning (64 KB)</h2>
<p>
The 64 KB System SRAM (<code>0x0000_0000 – 0x0000_FFFF</code>) serves as the primary on-chip staging area, decoupling external low-speed ingress/egress from multi-megabyte cryptographic compute engines. It is partitioned into four dedicated 16 KB functional regions:
</p>

<table>
  <thead>
    <tr>
      <th style="width: 20%;">Address Range</th>
      <th style="width: 10%;">Size</th>
      <th style="width: 25%;">Buffer Function</th>
      <th style="width: 45%;">Firmware Allocation &amp; Operational Usage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x0000_0000 – 0x0000_3FFF</code></td>
      <td>16 KB</td>
      <td>Telemetry Ingress Buffer</td>
      <td>Raw incoming telemetry packet frames transferred from UART RX FIFOs by CPU/DMA.</td>
    </tr>
    <tr>
      <td><code>0x0000_4000 – 0x0000_7FFF</code></td>
      <td>16 KB</td>
      <td>Cryptographic Staging Buffer</td>
      <td>Pre-processed plaintext staging and destination for decrypted/encrypted AES payloads.</td>
    </tr>
    <tr>
      <td><code>0x0000_8000 – 0x0000_BFFF</code></td>
      <td>16 KB</td>
      <td>SHA-256 Scratchpad</td>
      <td>Pre-padded message blocks (512-bit multiples) for hardware SHA digest verification.</td>
    </tr>
    <tr>
      <td><code>0x0000_C000 – 0x0000_FFFF</code></td>
      <td>16 KB</td>
      <td>Telemetry Egress Buffer &amp; Descriptors</td>
      <td>Finalized encrypted ciphertext packets awaiting serial transmission, and DMA descriptor memory.</td>
    </tr>
  </tbody>
</table>

<h2>4.3 VeeR-EL2 Processor Core Memory &amp; PIC Subsystem</h2>
<table>
  <thead>
    <tr>
      <th style="width: 24%;">Region / Register Window</th>
      <th style="width: 16%;">Base Address</th>
      <th style="width: 12%;">Size / Bits</th>
      <th style="width: 8%;">Access</th>
      <th style="width: 40%;">Functional Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Reset Vector (RV_RESET_VEC)</td>
      <td><code>0x8000_0000</code></td>
      <td>Entry Point</td>
      <td>R/X</td>
      <td>Power-on CPU instruction fetch destination (Boot ROM entry).</td>
    </tr>
    <tr>
      <td>ICCM (Instruction Memory)</td>
      <td><code>0xEE00_0000</code></td>
      <td>128 KB</td>
      <td>R/W/X</td>
      <td>Single-cycle local instruction RAM with ECC protection (RV_ICCM_BITS=17).</td>
    </tr>
    <tr>
      <td>DCCM (Data Scratchpad)</td>
      <td><code>0xF004_0000</code></td>
      <td>128 KB</td>
      <td>R/W</td>
      <td>Single-cycle local data scratchpad for stack, heap, and fast variables (RV_DCCM_BITS=17).</td>
    </tr>
    <tr>
      <td>PIC Base Window</td>
      <td><code>0xF00C_0000</code></td>
      <td>64 KB</td>
      <td>R/W</td>
      <td>VeeR-EL2 Programmable Interrupt Controller configuration and gateway registers.</td>
    </tr>
    <tr>
      <td>PIC MEIPL[1..8]</td>
      <td><code>0xF00C_0004..20</code></td>
      <td>8 × 32-bit</td>
      <td>R/W</td>
      <td>Interrupt priority levels (0 to 15) for external interrupt request lines 1 through 8.</td>
    </tr>
    <tr>
      <td>PIC MEIP[0]</td>
      <td><code>0xF00C_1000</code></td>
      <td>32-bit</td>
      <td>RO</td>
      <td>Interrupt pending status flags for IRQs 1 through 8.</td>
    </tr>
    <tr>
      <td>PIC MEIE[0]</td>
      <td><code>0xF00C_2000</code></td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>Interrupt enable bits for external interrupt gateway lines 1 through 8.</td>
    </tr>
    <tr>
      <td>PIC MEIGWCTRL[1..8]</td>
      <td><code>0xF00C_4004..20</code></td>
      <td>8 × 32-bit</td>
      <td>R/W</td>
      <td>Gateway configuration: bit 0 = Polarity (1=High, 0=Low), bit 1 = Type (1=Edge, 0=Level).</td>
    </tr>
    <tr>
      <td>PIC MEIGWCLR[1..8]</td>
      <td><code>0xF00C_5004..20</code></td>
      <td>8 × 32-bit</td>
      <td>WO</td>
      <td>Gateway interrupt clear: Write 1 to clear pending edge-triggered interrupt.</td>
    </tr>
  </tbody>
</table>

<h1>5. Subsystem Register Specifications</h1>

<h2>5.1 AES-256 Cryptographic Accelerator (Base: <code>0x4000_0000</code>)</h2>
<p>
The AES-256 accelerator performs high-speed block encryption and decryption adhering to FIPS-197. It implements a 14-round transformation pipeline with autonomous Cipher Block Chaining (CBC) feedback logic, 256-bit key expansion, and 128-bit Initialization Vector (IV) register integration.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 16%;">Register Name</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 8%;">Type</th>
      <th style="width: 14%;">Reset Value</th>
      <th style="width: 44%;">Field Descriptions &amp; Functional Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x00</code></td>
      <td>AES_CTRL</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>start</code>: Write 1 to start cipher operation.<br>
        [1] <code>enc_dec</code>: 0 = Encrypt, 1 = Decrypt.<br>
        [2] <code>cbc_mode</code>: 1 = Enable CBC mode (IV chaining), 0 = ECB mode.<br>
        [3] <code>key_len</code>: 1 = 256-bit key (14 rounds), 0 = 128-bit key (10 rounds).<br>
        [4] <code>irq_en</code>: 1 = Assert <code>aes_irq</code> on completion.<br>
        [5] <code>soft_rst</code>: Write 1 to reset internal state and FIFOs.
      </td>
    </tr>
    <tr>
      <td><code>0x04</code></td>
      <td>AES_STATUS</td>
      <td>32-bit</td>
      <td>RO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>busy</code>: High while round transformations are in progress.<br>
        [1] <code>done</code>: Asserted when all blocks in <code>AES_BLK_CNT</code> finish.<br>
        [2] <code>key_ready</code>: Key expansion schedule complete.<br>
        [3] <code>err</code>: FIFO overrun or illegal configuration detected.
      </td>
    </tr>
    <tr>
      <td><code>0x08</code></td>
      <td>AES_BLK_CNT</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0001</code></td>
      <td>
        [15:0] <code>block_count</code>: Total number of 128-bit blocks to process in active burst.
      </td>
    </tr>
    <tr>
      <td><code>0x0C</code></td>
      <td>AES_IRQ_CLR</td>
      <td>32-bit</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>irq_clr</code>: Write 1 to clear <code>done</code> status flag and de-assert <code>aes_irq</code>.
      </td>
    </tr>
    <tr>
      <td><code>0x10–0x2C</code></td>
      <td>AES_KEY0–7</td>
      <td>8×32</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        256-bit Cipher Key: KEY0 (bits [31:0]) through KEY7 (bits [255:224]).
      </td>
    </tr>
    <tr>
      <td><code>0x30–0x3C</code></td>
      <td>AES_IV0–3</td>
      <td>4×32</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        128-bit Initialization Vector: IV0 (bits [31:0]) through IV3 (bits [127:96]).
      </td>
    </tr>
    <tr>
      <td><code>0x40–0x4C</code></td>
      <td>AES_DIN0–3</td>
      <td>4×32</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        128-bit Direct Plaintext Input Register (AXI-Lite CPU direct access bypass).
      </td>
    </tr>
    <tr>
      <td><code>0x50–0x5C</code></td>
      <td>AES_DOUT0–3</td>
      <td>4×32</td>
      <td>RO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        128-bit Direct Ciphertext Output Register (AXI-Lite CPU direct access bypass).
      </td>
    </tr>
  </tbody>
</table>

<h2>5.2 SHA-256 Cryptographic Hash Accelerator (Base: <code>0x4000_4000</code>)</h2>
<p>
The SHA-256 accelerator implements the Secure Hash Algorithm specified in FIPS 180-4. It computes a 256-bit message digest across arbitrary-length telemetry payloads by iterating over 512-bit message blocks.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 16%;">Register Name</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 8%;">Type</th>
      <th style="width: 14%;">Reset Value</th>
      <th style="width: 44%;">Field Descriptions &amp; Functional Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x00</code></td>
      <td>SHA_CTRL</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>init</code>: Write 1 to load standard initial hash values H(0)..H(7).<br>
        [1] <code>next</code>: Write 1 to hash the next 512-bit block.<br>
        [2] <code>mode</code>: 1 = SHA-256, 0 = SHA-224.<br>
        [3] <code>irq_en</code>: 1 = Assert <code>sha_irq</code> when digest is computed.<br>
        [4] <code>soft_rst</code>: Write 1 to reset internal state and clear working registers.
      </td>
    </tr>
    <tr>
      <td><code>0x04</code></td>
      <td>SHA_STATUS</td>
      <td>32-bit</td>
      <td>RO</td>
      <td><code>0x0000_0001</code></td>
      <td>
        [0] <code>ready</code>: Core is idle and ready to accept the next 512-bit block.<br>
        [1] <code>valid</code>: Final 256-bit digest computation complete and valid in DIGEST0..7.<br>
        [2] <code>busy</code>: 64-round compression function currently active.
      </td>
    </tr>
    <tr>
      <td><code>0x08</code></td>
      <td>SHA_BLOCK_COUNT</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0001</code></td>
      <td>
        [15:0] <code>block_count</code>: Total number of 512-bit blocks in current message stream.
      </td>
    </tr>
    <tr>
      <td><code>0x0C</code></td>
      <td>SHA_MSG_BYTE_LEN</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [31:0] <code>byte_len</code>: Total message length in bytes prior to padding.
      </td>
    </tr>
    <tr>
      <td><code>0x10</code></td>
      <td>SHA_DATA_IN</td>
      <td>32-bit</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [31:0] <code>data_word</code>: Direct CPU write port for sequential 512-bit block loading (16 words).
      </td>
    </tr>
    <tr>
      <td><code>0x20–0x3C</code></td>
      <td>SHA_DIGEST0–7</td>
      <td>8×32</td>
      <td>RO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        Final 256-bit Digest Result: DIGEST0 (H0: bits [255:224]) through DIGEST7 (H7: bits [31:0]).
      </td>
    </tr>
  </tbody>
</table>

<h2>5.3 DMA Controller &amp; Dual Descriptor Engine (Base: <code>0x4000_5000</code>)</h2>
<p>
The DMA engine performs autonomous, high-throughput memory-to-memory and memory-to-peripheral block data transfers over the 64-bit AXI4 crossbar. It supports programmable burst lengths (up to 256 beats), dual descriptor chaining, fixed FIFO streaming, and bus fault trapping.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 18%;">Register Name</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 8%;">Type</th>
      <th style="width: 14%;">Reset Value</th>
      <th style="width: 42%;">Field Descriptions &amp; Functional Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x00</code></td>
      <td>DMA_CONTROL</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_03FC</code></td>
      <td>
        [0] <code>go</code>: Write 1 to launch DMA execution across enabled descriptors.<br>
        [1] <code>abort</code>: Write 1 to abort active transfer immediately.<br>
        [9:2] <code>max_burst</code>: Maximum AXI burst length ALEN (0x00 = 1 beat, 0xFF = 256 beats). Default = 16 beats.
      </td>
    </tr>
    <tr>
      <td><code>0x08</code></td>
      <td>DMA_STATUS</td>
      <td>32-bit</td>
      <td>RO</td>
      <td><code>0x0000_CAFE</code></td>
      <td>
        [15:0] <code>version</code>: Hardware IP signature (reads <code>0xCAFE</code>).<br>
        [16] <code>done</code>: Asserted when all enabled descriptors finish.<br>
        [17] <code>error</code>: Asserted on AXI bus fault (SLVERR/DECERR) or misaligned parameter.<br>
        [18] <code>busy</code>: DMA master actively issuing AXI bus read/write requests.
      </td>
    </tr>
    <tr>
      <td><code>0x10</code></td>
      <td>DMA_ERROR_ADDR</td>
      <td>32-bit</td>
      <td>RO</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [31:0] <code>fault_addr</code>: Exact 32-bit bus address that triggered an AXI slave error response.
      </td>
    </tr>
    <tr>
      <td><code>0x20</code></td>
      <td>DMA_DESC0_SRC</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Descriptor 0 32-bit Source Base Address.</td>
    </tr>
    <tr>
      <td><code>0x24</code></td>
      <td>DMA_DESC0_DST</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Descriptor 0 32-bit Destination Base Address.</td>
    </tr>
    <tr>
      <td><code>0x28</code></td>
      <td>DMA_DESC0_BYTES</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Total Transfer Length in Bytes (up to 4 GB).</td>
    </tr>
    <tr>
      <td><code>0x2C</code></td>
      <td>DMA_DESC0_BURST</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0010</code></td>
      <td>AXI Burst Length for Descriptor 0 (default = 16 beats).</td>
    </tr>
    <tr>
      <td><code>0x30</code></td>
      <td>DMA_DESC0_CFG</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>src_mode</code>: 0 = Incrementing address, 1 = Fixed (FIFO endpoint).<br>
        [1] <code>dst_mode</code>: 0 = Incrementing address, 1 = Fixed (FIFO endpoint).<br>
        [2] <code>enable</code>: 1 = Descriptor 0 valid for execution.<br>
        [3] <code>irq_en</code>: 1 = Assert <code>dma_done_o</code> on Descriptor 0 completion.
      </td>
    </tr>
    <tr>
      <td><code>0x40–0x50</code></td>
      <td>DMA_DESC1_*</td>
      <td>5×32</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Descriptor 1 configuration registers (identical structure to Descriptor 0).</td>
    </tr>
  </tbody>
</table>

<h2>5.4 UART Serial Controller (Base: <code>0x4000_1000</code>)</h2>
<p>
The UART peripheral implements a standard 16550-compatible serial communications interface with 16-byte internal transmit and receive FIFOs, programmable baud rate divisor, line status monitoring, and interrupt generation.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 16%;">Register Name</th>
      <th style="width: 8%;">Access</th>
      <th style="width: 14%;">Reset Value</th>
      <th style="width: 52%;">Field Descriptions &amp; Functional Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x00</code> (DLAB=0)</td>
      <td>UART_RBR / THR</td>
      <td>R / W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        Read: Receiver Buffer Register (RBR) — pops oldest byte from RX FIFO.<br>
        Write: Transmitter Holding Register (THR) — pushes byte into TX FIFO.
      </td>
    </tr>
    <tr>
      <td><code>0x00</code> (DLAB=1)</td>
      <td>UART_DLL</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Divisor Latch LSB: Lower 8 bits of 16-bit baud rate divisor.</td>
    </tr>
    <tr>
      <td><code>0x04</code> (DLAB=0)</td>
      <td>UART_IER</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [0] <code>rx_data_ready_en</code>: Enable Received Data Available Interrupt.<br>
        [1] <code>tx_empty_en</code>: Enable Transmitter Holding Register Empty Interrupt.<br>
        [2] <code>rx_line_status_en</code>: Enable Receiver Line Status Interrupt (parity/framing error).
      </td>
    </tr>
    <tr>
      <td><code>0x04</code> (DLAB=1)</td>
      <td>UART_DLM</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Divisor Latch MSB: Upper 8 bits of 16-bit baud rate divisor.</td>
    </tr>
    <tr>
      <td><code>0x08</code></td>
      <td>UART_IIR / FCR</td>
      <td>R / W</td>
      <td><code>0x0000_0001</code></td>
      <td>
        Read (IIR): Interrupt Identification Register.<br>
        Write (FCR): [0] FIFO Enable, [1] Clear RX FIFO, [2] Clear TX FIFO.
      </td>
    </tr>
    <tr>
      <td><code>0x0C</code></td>
      <td>UART_LCR</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [1:0] Word Length: 2'b11 = 8 data bits.<br>
        [2] Stop Bits: 0 = 1 stop bit, 1 = 2 stop bits.<br>
        [3] Parity Enable: 0 = Disabled, 1 = Enabled.<br>
        [7] <code>DLAB</code>: Divisor Latch Access Bit (1 = DLL/DLM accessible, 0 = RBR/THR/IER).
      </td>
    </tr>
    <tr>
      <td><code>0x14</code></td>
      <td>UART_LSR</td>
      <td>RO</td>
      <td><code>0x0000_0060</code></td>
      <td>
        [0] <code>dr</code>: Data Ready (1 = Valid byte present in RX FIFO).<br>
        [1] <code>oe</code>: Overrun Error.<br>
        [2] <code>pe</code>: Parity Error.<br>
        [3] <code>fe</code>: Framing Error.<br>
        [5] <code>thre</code>: Transmitter Holding Register Empty (1 = Ready for next TX byte).<br>
        [6] <code>temt</code>: Transmitter Empty (both THR and shift register empty).
      </td>
    </tr>
  </tbody>
</table>

<div class="code">Baud Divisor Formula: Divisor = F_uart_clk / (16 × Desired_Baud)
Example: For F_uart_clk = 50 MHz and Baud = 115,200 bps:
         Divisor = 50,000,000 / (16 × 115,200) = 27.127 ≈ 27 (DLL = 0x1B, DLM = 0x00)
         With 50 MHz bus reference: 434 (0x01B2) yields 115,207 bps (0.006% error).</div>

<h2>5.5 System Timer Subsystem (rv_timer, Base: <code>0x4000_2000</code>)</h2>
<p>
The system timer peripheral implements a 64-bit real-time monotonic counter with a 12-bit programmable prescaler, increment step configurability, 64-bit compare match threshold register, and edge/level interrupt generation.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 18%;">Register Name</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 8%;">Type</th>
      <th style="width: 14%;">Reset Value</th>
      <th style="width: 42%;">Field Descriptions &amp; Functional Purpose</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x000</code></td>
      <td>ALERT_TEST</td>
      <td>32-bit</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>[0] <code>fatal_fault</code>: Write 1 to trigger fatal alert diagnostic interrupt test.</td>
    </tr>
    <tr>
      <td><code>0x004</code></td>
      <td>CTRL</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>[0] <code>active</code>: 1 = Timer enabled; 64-bit counter increments on configured prescaler ticks.</td>
    </tr>
    <tr>
      <td><code>0x100</code></td>
      <td>INTR_ENABLE0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>[0] <code>timer_expired_en</code>: Enable timer expiration interrupt to PIC.</td>
    </tr>
    <tr>
      <td><code>0x104</code></td>
      <td>INTR_STATE0</td>
      <td>32-bit</td>
      <td>RW1C</td>
      <td><code>0x0000_0000</code></td>
      <td>[0] <code>timer_expired</code>: Interrupt pending flag. Write 1 to clear.</td>
    </tr>
    <tr>
      <td><code>0x108</code></td>
      <td>INTR_TEST0</td>
      <td>32-bit</td>
      <td>WO</td>
      <td><code>0x0000_0000</code></td>
      <td>[0] <code>timer_expired_test</code>: Write 1 to software-force timer expiration interrupt.</td>
    </tr>
    <tr>
      <td><code>0x10C</code></td>
      <td>CFG0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>
        [11:0] <code>prescale</code>: Prescaler divisor (Counter ticks every <code>prescale + 1</code> clocks).<br>
        [23:16] <code>step</code>: Value added to 64-bit counter on each tick (default = 1).
      </td>
    </tr>
    <tr>
      <td><code>0x110</code></td>
      <td>TIMER_V_LOWER0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Lower 32 bits [31:0] of 64-bit real-time counter value.</td>
    </tr>
    <tr>
      <td><code>0x114</code></td>
      <td>TIMER_V_UPPER0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0x0000_0000</code></td>
      <td>Upper 32 bits [63:32] of 64-bit real-time counter value.</td>
    </tr>
    <tr>
      <td><code>0x118</code></td>
      <td>COMPARE_LOWER0_0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0xFFFF_FFFF</code></td>
      <td>Lower 32 bits [31:0] of 64-bit compare match threshold.</td>
    </tr>
    <tr>
      <td><code>0x11C</code></td>
      <td>COMPARE_UPPER0_0</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td><code>0xFFFF_FFFF</code></td>
      <td>Upper 32 bits [63:32] of 64-bit compare match threshold.</td>
    </tr>
  </tbody>
</table>

<h2>5.6 64-Pin GPIO Controller (Base: <code>0x4000_3000</code>)</h2>
<p>
The GPIO subsystem manages 64 independent digital I/O pins partitioned into Bank 0 (pins [31:0]) and Bank 1 (pins [63:32]). It includes 2-stage input synchronizers to prevent metastability, atomic bit manipulation registers (Set, Clear, Toggle) that eliminate software read-modify-write races, and per-pin edge/level interrupt generation.
</p>

<table>
  <thead>
    <tr>
      <th style="width: 10%;">Offset</th>
      <th style="width: 18%;">Register Name</th>
      <th style="width: 8%;">Width</th>
      <th style="width: 8%;">Type</th>
      <th style="width: 14%;">Pins Covered</th>
      <th style="width: 42%;">Functional Purpose &amp; Operational Usage</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>0x000</code></td>
      <td>GPIO_INFO</td>
      <td>32-bit</td>
      <td>RO</td>
      <td>All [63:0]</td>
      <td>Hardware info register: Reads decimal 64 (implemented pin count).</td>
    </tr>
    <tr>
      <td><code>0x004</code></td>
      <td>GPIO_CFG</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>Global</td>
      <td>Global configuration (push-pull vs open-drain drive mode).</td>
    </tr>
    <tr>
      <td><code>0x080 / 0x084</code></td>
      <td>GPIO_EN_0 / EN_1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Direction control: 1 = Output drive enabled, 0 = High-Z / Input mode.</td>
    </tr>
    <tr>
      <td><code>0x100 / 0x104</code></td>
      <td>GPIO_IN_0 / IN_1</td>
      <td>32-bit</td>
      <td>RO</td>
      <td>[31:0] / [63:32]</td>
      <td>Sampled raw synchronized input pin states.</td>
    </tr>
    <tr>
      <td><code>0x180 / 0x184</code></td>
      <td>GPIO_OUT_0 / OUT_1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Output data register: Sets drive level when pin is enabled as output.</td>
    </tr>
    <tr>
      <td><code>0x200 / 0x204</code></td>
      <td>GPIO_SET_0 / SET_1</td>
      <td>32-bit</td>
      <td>WO</td>
      <td>[31:0] / [63:32]</td>
      <td>Atomic Bit Set: Writing 1 drives corresponding pin HIGH without R-M-W.</td>
    </tr>
    <tr>
      <td><code>0x280 / 0x284</code></td>
      <td>GPIO_CLR_0 / CLR_1</td>
      <td>32-bit</td>
      <td>WO</td>
      <td>[31:0] / [63:32]</td>
      <td>Atomic Bit Clear: Writing 1 drives corresponding pin LOW without R-M-W.</td>
    </tr>
    <tr>
      <td><code>0x300 / 0x304</code></td>
      <td>GPIO_TOGGLE_0 / 1</td>
      <td>32-bit</td>
      <td>WO</td>
      <td>[31:0] / [63:32]</td>
      <td>Atomic Bit Toggle: Writing 1 inverts current state of corresponding pin.</td>
    </tr>
    <tr>
      <td><code>0x380 / 0x384</code></td>
      <td>INTRPT_RISE_EN_0 / 1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Rising-edge transition interrupt enable per pin.</td>
    </tr>
    <tr>
      <td><code>0x400 / 0x404</code></td>
      <td>INTRPT_FALL_EN_0 / 1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Falling-edge transition interrupt enable per pin.</td>
    </tr>
    <tr>
      <td><code>0x480 / 0x484</code></td>
      <td>INTRPT_HIGH_EN_0 / 1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Active-high level-sensitive interrupt enable per pin.</td>
    </tr>
    <tr>
      <td><code>0x500 / 0x504</code></td>
      <td>INTRPT_LOW_EN_0 / 1</td>
      <td>32-bit</td>
      <td>R/W</td>
      <td>[31:0] / [63:32]</td>
      <td>Active-low level-sensitive interrupt enable per pin.</td>
    </tr>
    <tr>
      <td><code>0x580 / 0x584</code></td>
      <td>INTRPT_STATUS_0 / 1</td>
      <td>32-bit</td>
      <td>RW1C</td>
      <td>[31:0] / [63:32]</td>
      <td>Cumulative interrupt pending status. Write 1 to clear pending flag.</td>
    </tr>
  </tbody>
</table>

<h1>6. Control Path and System Coordination</h1>

<h2>6.1 System Control Topology</h2>
<p>
The control path defines how the Western Digital VeeR EL2 core orchestrates system operations across the unified AXI4/AXI4-Lite interconnect architecture. Both high-throughput data movement and peripheral control-plane register configurations are carried over the 64-bit AXI4 crossbar. Peripherals with lightweight register interfaces are connected via AXI4-Lite subordinate ports through protocol bridges.
</p>
<p>
<strong>Downward Configuration Flow:</strong> Control transactions originate from the VeeR EL2 Core through its Load/Store Unit (LSU) master interface across the 64-bit AMBA AXI4 interconnect directly to the AXI4-Lite slave interfaces of individual peripherals and accelerators (Timer at <code>0x4000_2000</code>, UART at <code>0x4000_1000</code>, GPIO at <code>0x4000_3000</code>, DMA at <code>0x4000_5000</code>, SHA-256 at <code>0x4000_4000</code>, and AES-256 at <code>0x4000_0000</code>).
</p>
<p>
<strong>Upward Event Flow:</strong> Hardware event notifications flow upward from these endpoints into the Programmable Interrupt Controller (PIC), which asserts the VeeR EL2 core's external interrupt vector (<code>extintsrc_req</code>). This triggers the execution of the corresponding Interrupt Service Routine (ISR), followed by status register readback, event clearance via write-1-to-clear registers, and resumption of background execution.
</p>

<h2>6.2 Step-by-Step Operational Control Sequences</h2>

<h3>A. General Peripheral and Accelerator Initialization Sequence</h3>
<ol>
  <li>The VeeR EL2 core issues memory-mapped I/O write requests across the AXI4 interconnect to the AXI4-Lite slave interfaces of peripheral control registers.</li>
  <li>Firmware programs operating modes, intervals for the system timer (CFG0 prescaler and COMPARE match registers), baud rate divisor for the UART, pin directions for the GPIO controller, and cryptographic parameters such as AES 256-bit keys and 128-bit initialization vectors.</li>
  <li>Software sets the active and enable bits in the respective peripheral control registers to initiate autonomous operation.</li>
</ol>

<h3>B. Autonomous DMA Control Sequence</h3>
<ol>
  <li>Firmware programs the DMA transfer source address (<code>DMA_DESC0_SRC</code>), destination address (<code>DMA_DESC0_DST</code>), and byte transfer length (<code>DMA_DESC0_BYTES</code>) via the DMA controller's AXI4-Lite control interface.</li>
  <li>Software programs descriptor configuration options (address mode FIXED for FIFOs or INCR for memory) and enables Descriptor 0.</li>
  <li>Software writes the <code>go</code> command (bit 0) to <code>DMA_CONTROL</code> (<code>0x4000_5000</code>).</li>
  <li>The DMA controller operates independently as an AXI4 master on crossbar port s01 and executes high-bandwidth burst data transfers without CPU involvement.</li>
  <li>Data moves independently between System SRAM and the target hardware endpoint (AES/SHA data FIFO).</li>
  <li>Upon completion of the programmed transfer or detection of a bus fault, the DMA controller asserts <code>dma_done_o</code> (IRQ 5) or <code>dma_error_o</code> (IRQ 6), respectively.</li>
  <li>The event propagates through the PIC to the VeeR EL2 core.</li>
  <li>The core executes the DMA service routine to inspect status flags, acknowledge the interrupt, and release the memory buffer for downstream processing.</li>
</ol>

<h3>C. Cryptographic Accelerator Control Sequence</h3>
<ol>
  <li>Firmware configures the cryptographic accelerator parameters (AES_CTRL or SHA_CTRL) and schedules the associated DMA transfer parameters required for payload delivery.</li>
  <li>Firmware enables or initiates the required cryptographic operation and triggers the DMA streaming transfer.</li>
  <li>The configured hardware performs data movement and cryptographic transformations independently of core intervention.</li>
  <li>Upon finalizing the 256-bit message digest or 128-bit block cipher transformation, the block asserts <code>sha_done_irq</code> (IRQ 4) or <code>aes_done_irq</code> (IRQ 3).</li>
  <li>The PIC routes the completion signal to the VeeR EL2 core.</li>
  <li>The CPU services the corresponding interrupt, reads the relevant completion and status information, and retrieves the cryptographic result (e.g. SHA digest from <code>0x4000_4020..3C</code> or ciphertext from SRAM) before continuing the pipeline flow.</li>
</ol>

<h1>7. Data Path and Telemetry Pipeline Flow</h1>

<h2>7.1 Data-Path Overview</h2>
<div class="code">
[Ingress Path]
External Host ──► Serial Line ──► UART ──► AXI4-Lite ──► VeeR EL2 Core ──► AXI4 ──► System SRAM

[Data Movement & Processing]
System SRAM ──► AXI4 ──► DMA Controller ──┬──► SHA-256 ──► Digest ──► AXI4-Lite / CPU Readback
                                          │
                                          └──► AES-256 CBC ──► Ciphertext ──► System SRAM

[Egress Path]
System SRAM ──► VeeR EL2 (LSU) ──► AXI4-Lite ──► UART ──► Serial Line ──► External Host
</div>

<p>
The data path consists of two cryptographic processing branches. The SHA-256 branch produces an integrity digest, while the AES-256 CBC branch produces the encrypted payload. The architecture does not assume that the SHA-256 output is directly connected to the AES-256 input unless such a dependency is explicitly defined by application firmware. The DMA controller executes the required transfers between System SRAM and the respective cryptographic accelerator interfaces. The SHA-256 and AES-256 paths are independent processing branches and can operate concurrently or sequentially as scheduled by system firmware.
</p>

<h2>7.2 Data Ingress</h2>
<p>
<strong>Ingress Source:</strong> The data path begins at the external host, which supplies raw telemetry payloads, configuration frames, or command streams across the asynchronous serial communication line.<br>
<strong>Ingress Interface:</strong> The physical UART controller receives the serial data stream, converts serial frames into parallel bytes, and buffers incoming bytes into its internal 16-byte receive holding FIFO accessible via the UART's AXI4-Lite control interface.<br>
<strong>Transport Mechanism:</strong> The VeeR EL2 core retrieves received data from the UART controller through memory-mapped register accesses over the AXI4 interconnect via the UART's AXI4-Lite slave interface, or alternatively delegates fixed-source streaming to the DMA controller.<br>
<strong>Initial Storage Destination:</strong> The core issues write transactions through its AXI4 LSU master interface across the 64-bit crossbar to deposit incoming telemetry bytes directly into the System SRAM Ingress Frame Buffer (<code>0x0000_0000 – 0x0000_3FFF</code>), establishing the base payload for subsequent cryptographic processing.
</p>

<h2>7.3 SRAM as the Shared Data Buffer</h2>
<p>
<strong>Buffer Role:</strong> The 64 KB System SRAM serves as the primary on-chip staging area and memory-mapped repository where raw telemetry payloads, intermediate processing blocks, and final encrypted outputs reside.<br>
<strong>Interface Access:</strong> Both the VeeR EL2 core via its LSU interface and the DMA controller access the SRAM as central memory slaves over the 64-bit AMBA AXI4 interconnect.<br>
<strong>Functional Purpose:</strong> It decouples the ingress and egress routines from high-speed cryptographic and transfer operations by providing stable, addressable memory ranges.<br>
<strong>Operational Boundary:</strong> The SRAM provides addressable storage for telemetry payloads, intermediate data, and encrypted results accessed through the AXI4 crossbar.
</p>

<h2>7.4 DMA Data Movement</h2>
<p>
<strong>Transfer Source:</strong> The DMA controller reads payload data from configured base addresses residing within the System SRAM.<br>
<strong>Transport Mechanism:</strong> Operating as an independent AXI4 master on crossbar port s01, the DMA controller executes block data transfers without requiring byte-by-byte CPU intervention.<br>
<strong>Execution Processing:</strong> The DMA controller operates using transfer parameters programmed into its descriptor registers and manages data movement autonomously while signaling completion or error states via separate interrupt lines to the PIC.<br>
<strong>Transfer Destinations:</strong> Supported architectural transfers map explicitly to hardware endpoints:
</p>
<ul>
  <li>System SRAM to SHA-256 accelerator data interface (<code>0x9000_0030</code>) for message integrity verification.</li>
  <li>System SRAM to AES-256 CBC engine data interface (<code>0x9000_0010</code>) for block cipher transformation.</li>
  <li>AES-256 CBC engine data output interface (<code>0x9000_0020</code>) back to System SRAM for writing finalized ciphertext results.</li>
</ul>

<h2>7.5 SHA-256 Data Path</h2>
<p>
<strong>Data Source:</strong> Buffered plaintext telemetry blocks residing in System SRAM.<br>
<strong>Transport Mechanism:</strong> The DMA controller streams these blocks across the AXI4 interconnect directly into the SHA-256 accelerator data FIFO endpoint.<br>
<strong>Processing Operation:</strong> The hardware accelerator computes the cryptographic message digest entirely through dedicated internal logic without modifying the underlying data blocks in SRAM.<br>
<strong>Result Destination:</strong> The resulting 256-bit hash digest is held in internal accelerator result registers (<code>SHA_DIGEST0–7</code> at <code>0x4000_4020–3C</code>), from which it is retrieved by the processor through the accelerator's control interface.
</p>

<h2>7.6 AES-256 Data Path</h2>
<p>
<strong>Data Source:</strong> Plaintext telemetry payload blocks stored within System SRAM.<br>
<strong>Transport Mechanism:</strong> The DMA controller reads and streams the plaintext blocks over the AXI4 interconnect into the AES-256 CBC engine data interface.<br>
<strong>Processing Operation:</strong> Operating in Cipher Block Chaining mode, the engine combines incoming plaintext blocks with an Initialization Vector (IV) and a pre-loaded 256-bit key, chaining ciphertext dependencies across sequential transformation cycles.<br>
<strong>Result Destination:</strong> The resulting encrypted ciphertext blocks are written back across the AXI4 interconnect and stored in the designated Egress Buffer (<code>0x0000_C000 – 0x0000_FFFF</code>) within System SRAM.
</p>

<h2>7.7 Data Egress</h2>
<p>
<strong>Egress Source:</strong> Finalized, encrypted payload blocks residing within the System SRAM result buffers.<br>
<strong>Transport Mechanism:</strong> Under firmware direction, the VeeR EL2 core reads the secured payload from SRAM using its AXI4 LSU interface and directs it toward the UART transmit registers via the AXI4 interconnect through the UART's AXI4-Lite slave interface.<br>
<strong>Processing Operation:</strong> The UART controller accepts the bytes through AXI4-Lite register writes and serializes the data stream according to pre-configured baud rates and frame formats.<br>
<strong>External Destination:</strong> The serialized ciphertext leaves the SoC pins across the <code>uart_tx</code> pin to reach the external host or telemetry ground station.
</p>

<h1>8. Verification Architecture &amp; Testplan Summary</h1>

<h2>8.1 Multi-Tier Verification Strategy</h2>
<p>
The SoC design is verified through a rigorous, multi-tiered verification framework combining:
</p>
<ol>
  <li><strong>Bare-Metal C Firmware Verification (<code>c_test/</code>):</strong> C programs compiled with GCC RISC-V toolchain running on the VeeR EL2 core, verifying reset vectors, ICCM/DCCM SRAMs, peripheral register configuration, DMA transfers, and end-to-end cryptographic processing.</li>
  <li><strong>SystemVerilog UVM VIP Testbenches (<code>tb/</code>):</strong> Comprehensive UVM Verification IP environments for UART (<code>uart_vip_uvm_tb</code>) and GPIO (<code>gpio_vip_uvm_tb</code>), featuring random stimulus drivers, passive monitors, and scoreboard checks.</li>
  <li><strong>Protocol Assertions &amp; Bus Checking:</strong> SVA assertions and protocol checkers monitoring all 5 channels of the 64-bit AMBA AXI4 crossbar to guarantee zero protocol violations, no deadlocks, and valid arbitration handshakes.</li>
</ol>

<h2>8.2 SoC Verification Test Matrix Summary</h2>
<p>
The verification testplan covers 38 structured test cases across 8 functional groups:
</p>

<table>
  <thead>
    <tr>
      <th style="width: 14%;">Group Identifier</th>
      <th style="width: 12%;">Test Count</th>
      <th style="width: 28%;">Subsystem Verified</th>
      <th style="width: 46%;">Key Checkpoints &amp; Verification Objectives</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><strong>TC_BOOT_01..03</strong></td>
      <td>3 Tests</td>
      <td>Boot, Memory &amp; Reset</td>
      <td>Reset vector execution from 0x8000_0000, ICCM/DCCM zero-wait-state memory execution, 64 KB System SRAM read/write byte-enable integrity.</td>
    </tr>
    <tr>
      <td><strong>TC_UART_01..05</strong></td>
      <td>5 Tests</td>
      <td>UART 16550 Serial Controller</td>
      <td>Register access via crossbar, 115,200 baud serialization timing on <code>uart_tx</code>, RX FIFO reception, parity/framing error detection, RX/TX interrupt generation.</td>
    </tr>
    <tr>
      <td><strong>TC_TIMER_01..04</strong></td>
      <td>4 Tests</td>
      <td>System Timer (rv_timer)</td>
      <td>64-bit real-time counter increment, prescaler tick divisor accuracy, compare match interrupt firing on <code>timer_irq_o</code>, interrupt clearing via W1C.</td>
    </tr>
    <tr>
      <td><strong>TC_GPIO_01..06</strong></td>
      <td>6 Tests</td>
      <td>64-Pin GPIO Subsystem</td>
      <td>Output drive state across 64 pins, input sampling with 2-stage synchronizers, atomic SET/CLR/TOGGLE verification, rising/falling/level interrupt triggers.</td>
    </tr>
    <tr>
      <td><strong>TC_SHA_01..04</strong></td>
      <td>4 Tests</td>
      <td>SHA-256 Hash Accelerator</td>
      <td>NIST CAVP golden test vectors, multi-block 512-bit message hashing, digest valid flag generation, <code>sha_irq_o</code> assertion.</td>
    </tr>
    <tr>
      <td><strong>TC_AES_01..06</strong></td>
      <td>6 Tests</td>
      <td>AES-256 CBC Accelerator</td>
      <td>256-bit key expansion schedule, 128-bit IV feedback chaining, multi-block encryption and decryption, ciphertext comparison against NIST SP 800-38A golden vectors, <code>aes_irq_o</code> assertion.</td>
    </tr>
    <tr>
      <td><strong>TC_DMA_01..05</strong></td>
      <td>5 Tests</td>
      <td>64-bit AXI DMA Controller</td>
      <td>CSR identification (signature 0xCAFE), linear SRAM-to-SRAM burst transfers, dual descriptor chaining, fixed-address FIFO streaming, bus fault address latching in <code>DMA_ERROR_ADDR</code>.</td>
    </tr>
    <tr>
      <td><strong>TC_SOC_01..05</strong></td>
      <td>5 Tests</td>
      <td>Full SoC Telemetry Integration</td>
      <td>End-to-end telemetry loopback: UART ingress → SRAM → DMA → SHA-256 digest &amp; AES-256 CBC encryption → SRAM → UART egress transmission to host.</td>
    </tr>
  </tbody>
</table>

<h1>9. Physical Implementation &amp; Synthesis Guidelines</h1>

<h2>9.1 Clock Domain Architecture</h2>
<p>
The SoC incorporates two primary asynchronous clock domains:
</p>
<ul>
  <li><strong>System AXI Clock (<code>clk</code>):</strong> Nominal 50 MHz / 100 MHz clock driving the VeeR EL2 CPU core, AXI4 crossbar, System SRAM, DMA master, and cryptographic accelerator computational pipelines.</li>
  <li><strong>UART Baud Reference Clock (<code>uart_clk</code>):</strong> Stable 50 MHz external oscillator reference driving the UART baud rate generator and serial transmit/receive shift registers. Two-stage synchronizers isolate the AXI register interface from the UART baud domain.</li>
</ul>

<h2>9.2 Reset Strategy</h2>
<p>
The SoC boundary receives an active-low asynchronous reset (<code>aresetn</code>). An internal reset synchronizer bridges this signal into the <code>clk</code> domain to provide clean synchronous de-assertion. An internal inverter derives active-high reset <code>rst = ~aresetn</code> to drive the <code>axi_interconnect</code> core, ensuring glitch-free power-on sequencing across all crossbar channels.
</p>

</body>
</html>
"""
    return html

def main():
    print("Extracting embedded architecture diagram...")
    img_b64 = extract_image_base64()
    
    print("Generating comprehensive HTML...")
    html_content = generate_html(img_b64)
    with open(TEMP_HTML, "w", encoding="utf-8") as f:
        f.write(html_content)
    print(f"HTML written to {TEMP_HTML} ({len(html_content)} bytes)")
    
    os.makedirs(TEMP_ODT_DIR, exist_ok=True)
    temp_odt = os.path.join(TEMP_ODT_DIR, "Project_spec_consolidated.odt")
    
    print("Converting HTML to ODT via LibreOffice...")
    cmd = [
        "soffice", "--headless",
        "--convert-to", "odt",
        TEMP_HTML,
        "--outdir", TEMP_ODT_DIR
    ]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    if res.returncode != 0:
        print("LibreOffice conversion failed!", res.stderr)
        sys.exit(1)
    
    print(f"Generated intermediate ODT: {temp_odt}")
    
    # Backup original Project_spec.odt
    backup_path = ORIGINAL_ODT + ".bak"
    if not os.path.exists(backup_path):
        os.system(f"cp '{ORIGINAL_ODT}' '{backup_path}'")
        print(f"Backed up original ODT to {backup_path}")
        
    # Copy generated ODT over target
    os.system(f"cp '{temp_odt}' '{TARGET_ODT}'")
    print(f"Successfully updated {TARGET_ODT} ({os.path.getsize(TARGET_ODT)} bytes)")

if __name__ == "__main__":
    main()

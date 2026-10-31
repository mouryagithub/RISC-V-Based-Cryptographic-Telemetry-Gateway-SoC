import csv
import os

soc_root = "/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC"
doc_dir = os.path.join(soc_root, "doc")
os.makedirs(doc_dir, exist_ok=True)

# ------------------------------------------------------------------------------
# 1. UART External Interface CSV (from Testplan.xlsx External Interfaces)
# ------------------------------------------------------------------------------
uart_ext_signals = [
    ("uart_rx", "input", "1"),
    ("uart_tx", "output", "1"),
]

# ------------------------------------------------------------------------------
# 2. GPIO External Interface CSV (from Testplan.xlsx External Interfaces)
# ------------------------------------------------------------------------------
gpio_ext_signals = [
    ("gpio_i", "input", "64"),
    ("gpio_o", "output", "64"),
    ("gpio_dir_o", "output", "64"),
]

# ------------------------------------------------------------------------------
# 3. UART Detailed (including interrupt and clock from test descriptions)
# ------------------------------------------------------------------------------
uart_detailed_signals = [
    ("uart_rx", "input", "1"),
    ("uart_tx", "output", "1"),
    ("uart_irq_o", "output", "1"),
    ("uart_clk", "input", "1"),
]

# ------------------------------------------------------------------------------
# 4. GPIO Detailed (including bank slices and interrupt lines from testplan)
# ------------------------------------------------------------------------------
gpio_detailed_signals = [
    ("gpio_i", "input", "64"),
    ("gpio_i[63:0]", "input", "64"),
    ("gpio_i[31:0]", "input", "32"),
    ("gpio_i[63:32]", "input", "32"),
    ("gpio_i[0]", "input", "1"),
    ("gpio_o", "output", "64"),
    ("gpio_o[63:0]", "output", "64"),
    ("gpio_o[31:0]", "output", "32"),
    ("gpio_o[63:32]", "output", "32"),
    ("gpio_o[0]", "output", "1"),
    ("gpio_dir_o", "output", "64"),
    ("gpio_dir_o[63:0]", "output", "64"),
    ("gpio_dir_o[31:0]", "output", "32"),
    ("gpio_dir_o[63:32]", "output", "32"),
    ("gpio_intr_o", "output", "2"),
    ("gpio_intr_o[0]", "output", "1"),
    ("gpio_intr_o[1]", "output", "1"),
]

# ------------------------------------------------------------------------------
# 5. Full IP Core Port Lists (axi_uart_top and axi_gpio_top)
# ------------------------------------------------------------------------------
uart_all_ip_signals = [
    # External serial pins
    ("uart_rx_i", "input", "1"),
    ("uart_tx_o", "output", "1"),
    ("read_interrupt_o", "output", "1"),
    # Clocks & Reset
    ("fixed_clk_i", "input", "1"),
    ("axi_aclk_i", "input", "1"),
    ("axi_aresetn_i", "input", "1"),
    # AXI Read Channel
    ("axi_arid_i", "input", "4"),
    ("axi_araddr_i", "input", "8"),
    ("axi_arvalid_i", "input", "1"),
    ("axi_arready_o", "output", "1"),
    ("axi_rid_o", "output", "4"),
    ("axi_rdata_o", "output", "32"),
    ("axi_rresp_o", "output", "2"),
    ("axi_rvalid_o", "output", "1"),
    ("axi_rready_i", "input", "1"),
    # AXI Write Channel
    ("axi_awid_i", "input", "4"),
    ("axi_awaddr_i", "input", "8"),
    ("axi_awvalid_i", "input", "1"),
    ("axi_awready_o", "output", "1"),
    ("axi_wdata_i", "input", "32"),
    ("axi_wstrb_i", "input", "4"),
    ("axi_wvalid_i", "input", "1"),
    ("axi_wready_o", "output", "1"),
    ("axi_bid_o", "output", "4"),
    ("axi_bresp_o", "output", "2"),
    ("axi_bvalid_o", "output", "1"),
    ("axi_bready_i", "input", "1"),
]

gpio_all_ip_signals = [
    # External GPIO Pins & Interrupts
    ("gpio_i", "input", "64"),
    ("gpio_o", "output", "64"),
    ("gpio_dir_o", "output", "64"),
    ("gpio_intr_o", "output", "2"),
    # Clocks & Reset
    ("aclk", "input", "1"),
    ("aresetn", "input", "1"),
    # AXI4-Lite Write Channels
    ("s_axi_awaddr", "input", "12"),
    ("s_axi_awprot", "input", "3"),
    ("s_axi_awvalid", "input", "1"),
    ("s_axi_awready", "output", "1"),
    ("s_axi_wdata", "input", "32"),
    ("s_axi_wstrb", "input", "4"),
    ("s_axi_wvalid", "input", "1"),
    ("s_axi_wready", "output", "1"),
    ("s_axi_bresp", "output", "2"),
    ("s_axi_bvalid", "output", "1"),
    ("s_axi_bready", "input", "1"),
    # AXI4-Lite Read Channels
    ("s_axi_araddr", "input", "12"),
    ("s_axi_arprot", "input", "3"),
    ("s_axi_arvalid", "input", "1"),
    ("s_axi_arready", "output", "1"),
    ("s_axi_rdata", "output", "32"),
    ("s_axi_rresp", "output", "2"),
    ("s_axi_rvalid", "output", "1"),
    ("s_axi_rready", "input", "1"),
]

def write_csv(filepath, rows):
    with open(filepath, "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["signal", "input or output", "size"])
        for row in rows:
            writer.writerow(row)
    print(f"Written: {filepath} ({len(rows)} signals)")

# Generate UART files
for path in [
    os.path.join(soc_root, "uart.csv"),
    os.path.join(soc_root, "uart_external_interface.csv"),
    os.path.join(doc_dir, "uart.csv"),
    os.path.join(doc_dir, "uart_external_interface.csv"),
]:
    write_csv(path, uart_ext_signals)

# Generate GPIO files
for path in [
    os.path.join(soc_root, "gpio.csv"),
    os.path.join(soc_root, "gpio_external_interface.csv"),
    os.path.join(doc_dir, "gpio.csv"),
    os.path.join(doc_dir, "gpio_external_interface.csv"),
]:
    write_csv(path, gpio_ext_signals)

# Generate Detailed files
write_csv(os.path.join(soc_root, "uart_detailed.csv"), uart_detailed_signals)
write_csv(os.path.join(doc_dir, "uart_detailed.csv"), uart_detailed_signals)
write_csv(os.path.join(soc_root, "gpio_detailed.csv"), gpio_detailed_signals)
write_csv(os.path.join(doc_dir, "gpio_detailed.csv"), gpio_detailed_signals)

# Generate Full IP Core files
write_csv(os.path.join(soc_root, "uart_all_ip_signals.csv"), uart_all_ip_signals)
write_csv(os.path.join(doc_dir, "uart_all_ip_signals.csv"), uart_all_ip_signals)
write_csv(os.path.join(soc_root, "gpio_all_ip_signals.csv"), gpio_all_ip_signals)
write_csv(os.path.join(doc_dir, "gpio_all_ip_signals.csv"), gpio_all_ip_signals)

print("All CSV files generated successfully!")

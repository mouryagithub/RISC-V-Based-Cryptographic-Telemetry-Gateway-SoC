# ==============================================================================
# Makefile for UVM VIP Testbenches
# Directory: tb/
# ==============================================================================

export VCS_HOME ?= /home/student/snps_tools_target/vcs/U-2023.03
export VERDI_HOME ?= /home/student/snps_tools_target/verdi/U-2023.03-SP1
export PATH := $(VCS_HOME)/bin:$(VERDI_HOME)/bin:$(PATH)
export SNPSLMD_LICENSE_FILE ?= 27021@14.139.1.126

VCS_FLAGS = -full64 -sverilog -timescale=1ns/1ps -ntb_opts uvm -debug_access+all -kdb

.PHONY: all soc gpio uart c_test clean

all: soc

c_test:
	@echo "=== Compiling & Running SoC C Firmware Test Suite on UVM VIP Top (tb_top.sv) ==="
	vcs $(VCS_FLAGS) -f tb_top.f -o simv_soc_vips
	./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES

soc:
	@echo "=== Compiling Integrated SoC VIP Testbench (tb_top.sv) ==="
	vcs $(VCS_FLAGS) -f tb_top.f -o simv_soc_vips
	@echo "=== Running C Firmware Test Suite on SoC UVM Top (tb_top.sv) ==="
	./simv_soc_vips +UVM_TESTNAME=soc_c_test +UVM_NO_RELNOTES
	@echo "=== Running GPIO VIP Test on SoC UVM Top (tb_top.sv) ==="
	./simv_soc_vips +UVM_TESTNAME=gpio_vip_test +UVM_NO_RELNOTES
	@echo "=== Running UART VIP Test on SoC UVM Top (tb_top.sv) ==="
	./simv_soc_vips +UVM_TESTNAME=uart_vip_test +UVM_NO_RELNOTES

gpio:
	@echo "=== Compiling & Running Standalone GPIO VIP Testbench ==="
	cd gpio_vip_uvm_tb && \
	vcs $(VCS_FLAGS) ../../rtl/gpio/axi_gpio_top.v gpio_vip_if.sv gpio_vip_pkg.sv tb_top.sv -o simv_gpio_vip && \
	./simv_gpio_vip +UVM_NO_RELNOTES

uart:
	@echo "=== Compiling & Running Standalone UART VIP Testbench ==="
	cd uart_vip_uvm_tb && \
	vcs $(VCS_FLAGS) +incdir+../../rtl/uart \
		../../rtl/uart/timescale.v \
		../../rtl/uart/uart_parity_bit_compute.v \
		../../rtl/uart/axi_internal_fifo.v \
		../../rtl/uart/uart_receiver.v \
		../../rtl/uart/uart_transmitter.v \
		../../rtl/uart/uart_controller.v \
		../../rtl/uart/axi_uart_top.v \
		uart_vip_if.sv uart_vip_pkg.sv tb_top.sv -o simv_uart_vip && \
	./simv_uart_vip +UVM_NO_RELNOTES

clean:
	rm -rf simv* csrc *.log *.key *.h *.vcd *.fsdb novas.* ucli.key
	rm -rf gpio_vip_uvm_tb/simv* gpio_vip_uvm_tb/csrc gpio_vip_uvm_tb/*.log gpio_vip_uvm_tb/*.key gpio_vip_uvm_tb/*.h
	rm -rf uart_vip_uvm_tb/simv* uart_vip_uvm_tb/csrc uart_vip_uvm_tb/*.log uart_vip_uvm_tb/*.key uart_vip_uvm_tb/*.h

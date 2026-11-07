verdiSetActWin -dock widgetDock_<Message>
debImport "-f" \
          "/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/run/run_vip.f" \
          -path \
          {/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/run}
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
wvCreateWindow
verdiSetActWin -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvOpenFile -win $_nWave2 \
           {/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/run/soc_vips_tb.fsdb}
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "uart_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "uart_vip_if"
srcTBTreeAction -win $_nTrace1 -path "uart_vip_if"
wvCreateWindow
verdiSetActWin -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 0)}
wvOpenFile -win $_nWave3 \
           {/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/run/soc_vips_tb.fsdb}
srcSignalView -on
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelectAll -curPage
wvAddSignal -win $_nWave3 "/tb_top/uart_vif/clk" "/tb_top/uart_vif/aresetn" \
           "/tb_top/uart_vif/uart_rx" "/tb_top/uart_vif/uart_tx" \
           "/tb_top/uart_vif/uart_irq"
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G1" 5)}
wvSetPosition -win $_nWave3 {("G1" 5)}
verdiSetActWin -win $_nWave3
wvScrollDown -win $_nWave3 1
wvSelectGroup -win $_nWave3 {G2}
wvScrollUp -win $_nWave3 3
wvScrollDown -win $_nWave3 3
wvScrollDown -win $_nWave3 0
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBTreeAction -win $_nTrace1 -path "axi_uart_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -win $_nWave3
wvScrollUp -win $_nWave3 3
wvScrollDown -win $_nWave3 3
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSetFilter "uart_rx"
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBTreeAction -win $_nTrace1 -path "axi_uart_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalView -off
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcSignalView -on
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSort -name
srcSignalViewSort -name
verdiSetActWin -win $_nWave3
wvScrollDown -win $_nWave3 0
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_rx_i"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_rx_i"
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G1" 2)}
wvSetPosition -win $_nWave3 {("G1" 3)}
wvSetPosition -win $_nWave3 {("G1" 5)}
wvSetPosition -win $_nWave3 {("G2" 0)}
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G2" 0)}
wvAddSignal -win $_nWave3 "/tb_top/u_soc_dut/u_uart/uart_rx_i"
wvSetPosition -win $_nWave3 {("G2" 0)}
wvSetPosition -win $_nWave3 {("G2" 1)}
wvSetPosition -win $_nWave3 {("G2" 1)}
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_tx_o"
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_tx_o"
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G1" 3)}
wvSetPosition -win $_nWave3 {("G1" 2)}
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G2" 0)}
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G3" 0)}
wvSetPosition -win $_nWave3 {("G2" 1)}
wvAddSignal -win $_nWave3 "/tb_top/u_soc_dut/u_uart/uart_tx_o"
wvSetPosition -win $_nWave3 {("G2" 1)}
wvSetPosition -win $_nWave3 {("G2" 2)}
verdiSetActWin -win $_nWave3
wvScrollUp -win $_nWave3 1
wvScrollUp -win $_nWave3 4
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_3
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 55855169.451074 -snap {("G3" 0)}
wvSetCursor -win $_nWave3 90299190.612570 -snap {("G3" 0)}
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiDockWidgetRestore -dock windowDock_nWave_3
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBTreeAction -win $_nTrace1 -path "gpio_vip_if"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -dock widgetDock_<Signal_List>
wvScrollDown -win $_nWave3 1
verdiSetActWin -win $_nWave3
wvScrollDown -win $_nWave3 5
srcSignalViewSelect "tb_top.gpio_vif.gpio_i\[63:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]"
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]" \
           "tb_top.gpio_vif.gpio_i\[63:0\]"
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]" \
           "tb_top.gpio_vif.gpio_i\[63:0\]" \
           "tb_top.gpio_vif.gpio_intr_o\[1:0\]"
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]" \
           "tb_top.gpio_vif.gpio_i\[63:0\]" \
           "tb_top.gpio_vif.gpio_intr_o\[1:0\]" \
           "tb_top.gpio_vif.gpio_o\[63:0\]"
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G1" 5)}
wvSetPosition -win $_nWave3 {("G2" 0)}
wvSetPosition -win $_nWave3 {("G1" 0)}
wvSetPosition -win $_nWave3 {("G2" 1)}
wvSetPosition -win $_nWave3 {("G2" 2)}
wvSetPosition -win $_nWave3 {("G3" 0)}
wvAddSignal -win $_nWave3 "/tb_top/gpio_vif/gpio_dir_o\[63:0\]" \
           "/tb_top/gpio_vif/gpio_i\[63:0\]" \
           "/tb_top/gpio_vif/gpio_intr_o\[1:0\]" \
           "/tb_top/gpio_vif/gpio_o\[63:0\]"
wvSetPosition -win $_nWave3 {("G3" 0)}
wvSetPosition -win $_nWave3 {("G3" 4)}
wvSetPosition -win $_nWave3 {("G3" 4)}
verdiSetActWin -win $_nWave3
wvScrollDown -win $_nWave3 1
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
srcTBTreeAction -win $_nTrace1 -path "axi_gpio_top"
verdiSetActWin -win $_nWave3
wvScrollUp -win $_nWave3 1
wvScrollUp -win $_nWave3 1
wvScrollDown -win $_nWave3 1
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]"
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_intr_o\[1:0\]"
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_intr_o\[1:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_o\[63:0\]"
verdiSetActWin -win $_nWave3
wvScrollDown -win $_nWave3 1
wvSetPosition -win $_nWave3 {("G1" 0)}
verdiSetActWin -dock widgetDock_<Signal_List>
wvSetPosition -win $_nWave3 {("G3" 1)}
wvSetPosition -win $_nWave3 {("G3" 0)}
wvSetPosition -win $_nWave3 {("G3" 1)}
wvSetPosition -win $_nWave3 {("G3" 2)}
wvSetPosition -win $_nWave3 {("G3" 3)}
wvSetPosition -win $_nWave3 {("G3" 4)}
wvSetPosition -win $_nWave3 {("G4" 0)}
wvAddSignal -win $_nWave3 "/tb_top/u_soc_dut/u_gpio/gpio_dir_o\[63:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_i\[63:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_intr_o\[1:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_o\[63:0\]"
wvSetPosition -win $_nWave3 {("G4" 0)}
wvSetPosition -win $_nWave3 {("G4" 4)}
wvSetPosition -win $_nWave3 {("G4" 4)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_3
verdiSetActWin -win $_nWave3
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 169892807.080350 -snap {("G5" 0)}
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvSetCursor -win $_nWave3 680698.501193 -snap {("G4" 1)}
wvZoomIn -win $_nWave3
wvZoomAll -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvSetCursor -win $_nWave3 97210.806981 -snap {("G1" 4)}
wvSetCursor -win $_nWave3 41404.602973 -snap {("G1" 3)}
wvSetCursor -win $_nWave3 25202.801810 -snap {("G1" 1)}
wvSetCursor -win $_nWave3 10801.200776 -snap {("G1" 1)}
wvSetCursor -win $_nWave3 106211.807627 -snap {("G1" 1)}
wvSetCursor -win $_nWave3 165618.411893 -snap {("G1" 2)}
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvZoomIn -win $_nWave3
wvSetCursor -win $_nWave3 36022904.686878 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 35848285.274339 -snap {("G5" 0)}
wvZoomAll -win $_nWave3
wvSetCursor -win $_nWave3 1861838.981702 -snap {("G4" 2)}
wvSetCursor -win $_nWave3 930919.490851 -snap {("G4" 2)}
wvSetCursor -win $_nWave3 0.000000 -snap {("G4" 2)}
wvSetCursor -win $_nWave3 52131491.487669 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 20480228.798727 -snap {("G4" 3)}
wvSetCursor -win $_nWave3 13963792.362768 -snap {("G4" 2)}
wvSetCursor -win $_nWave3 27927584.725537 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 67026203.341289 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 1861838.981702 -snap {("G3" 2)}
wvSetCursor -win $_nWave3 0.000000 -snap {("G3" 2)}
wvSetCursor -win $_nWave3 0.000000 -snap {("G3" 2)}
wvSetCursor -win $_nWave3 930919.490851 -snap {("G3" 2)}
wvSetCursor -win $_nWave3 0.000000 -snap {("G4" 2)}
wvSelectSignal -win $_nWave3 {( "G2" 2 )} 
wvSelectSignal -win $_nWave3 {( "G1" 4 )} 
wvSetCursor -win $_nWave3 186649357.915672 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 167565508.353222 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 284861364.200477 -snap {("G5" 0)}
wvSelectSignal -win $_nWave3 {( "G1" 5 )} 
wvSetCursor -win $_nWave3 72611720.286396 -snap {("G5" 0)}
wvSelectSignal -win $_nWave3 {( "G4" 3 )} 
wvSelectSignal -win $_nWave3 {( "G4" 4 )} 
wvSetCursor -win $_nWave3 22342067.780430 -snap {("G5" 0)}
wvSetCursor -win $_nWave3 579031923.309467 -snap {("G1" 1)}
verdiDockWidgetHide -dock windowDock_nWave_3
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiSetActWin -win $_nWave2
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiDockWidgetHide -dock windowDock_nWave_2
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiSetActWin -dock widgetDock_<Decl._Tree>
wvCreateWindow
verdiSetActWin -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
wvOpenFile -win $_nWave4 \
           {/home/student/Documents/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/run/soc_vips_tb.fsdb}
srcTBBTreeSelect -win $_nTrace1 -path "uart_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "uart_vip_if"
srcTBTreeAction -win $_nTrace1 -path "uart_vip_if"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelectAll -curPage
wvSetPosition -win $_nWave3 {("G1" 0)}
wvAddSignal -win $_nWave4 "/tb_top/uart_vif/aresetn" "/tb_top/uart_vif/clk" \
           "/tb_top/uart_vif/uart_irq" "/tb_top/uart_vif/uart_rx" \
           "/tb_top/uart_vif/uart_tx"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 5)}
wvSetPosition -win $_nWave4 {("G1" 5)}
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_uart_top"
srcTBTreeAction -win $_nTrace1 -path "axi_uart_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -win $_nWave4
wvScrollDown -win $_nWave4 1
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_rx_i"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.u_soc_dut.u_uart.uart_rx_i" \
           "tb_top.u_soc_dut.u_uart.uart_tx_o"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 3)}
wvSetPosition -win $_nWave4 {("G1" 4)}
wvSetPosition -win $_nWave4 {("G1" 5)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvAddSignal -win $_nWave4 "/tb_top/u_soc_dut/u_uart/uart_rx_i" \
           "/tb_top/u_soc_dut/u_uart/uart_tx_o"
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G2" 2)}
wvSetPosition -win $_nWave4 {("G2" 2)}
verdiSetActWin -win $_nWave4
wvScrollDown -win $_nWave4 1
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBTreeAction -win $_nTrace1 -path "gpio_vip_if"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]"
srcSignalViewSelect "tb_top.gpio_vif.gpio_dir_o\[63:0\]" \
           "tb_top.gpio_vif.gpio_i\[63:0\]" \
           "tb_top.gpio_vif.gpio_intr_o\[1:0\]" \
           "tb_top.gpio_vif.gpio_o\[63:0\]"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 5)}
wvSetPosition -win $_nWave4 {("G1" 4)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G2" 1)}
wvSetPosition -win $_nWave4 {("G2" 2)}
wvSetPosition -win $_nWave4 {("G3" 0)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G3" 0)}
wvAddSignal -win $_nWave4 "/tb_top/gpio_vif/gpio_dir_o\[63:0\]" \
           "/tb_top/gpio_vif/gpio_i\[63:0\]" \
           "/tb_top/gpio_vif/gpio_intr_o\[1:0\]" \
           "/tb_top/gpio_vif/gpio_o\[63:0\]"
wvSetPosition -win $_nWave4 {("G3" 0)}
wvSetPosition -win $_nWave4 {("G3" 4)}
wvSetPosition -win $_nWave4 {("G3" 4)}
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
srcTBBTreeSelect -win $_nTrace1 -path "axi_gpio_top"
srcTBTreeAction -win $_nTrace1 -path "axi_gpio_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -win $_nWave4
wvScrollDown -win $_nWave4 1
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
verdiSetActWin -win $_nWave4
wvScrollUp -win $_nWave4 1
wvScrollDown -win $_nWave4 1
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]"
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]"
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_intr_o\[1:0\]"
srcSignalViewSelect "tb_top.u_soc_dut.u_gpio.gpio_dir_o\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_i\[63:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_intr_o\[1:0\]" \
           "tb_top.u_soc_dut.u_gpio.gpio_o\[63:0\]"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G3" 1)}
wvSetPosition -win $_nWave4 {("G3" 2)}
wvSetPosition -win $_nWave4 {("G3" 3)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G4" 0)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G4" 0)}
wvAddSignal -win $_nWave4 "/tb_top/u_soc_dut/u_gpio/gpio_dir_o\[63:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_i\[63:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_intr_o\[1:0\]" \
           "/tb_top/u_soc_dut/u_gpio/gpio_o\[63:0\]"
wvSetPosition -win $_nWave4 {("G4" 0)}
wvSetPosition -win $_nWave4 {("G4" 4)}
wvSetPosition -win $_nWave4 {("G4" 4)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_4
verdiSetActWin -win $_nWave4
wvZoomAll -win $_nWave4
wvSelectSignal -win $_nWave4 {( "G1" 2 )} 
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvMoveSelected -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetCursor -win $_nWave4 89882300.579710 -snap {("G5" 0)}
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomAll -win $_nWave4
wvSetCursor -win $_nWave4 57236370.652174 -snap {("G5" 0)}
wvSetCursor -win $_nWave4 116168633.768116 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 33069903.043478 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 13991112.826087 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 8055489.202899 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 5087677.391304 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 18654817.101449 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 27982225.652174 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 56388424.420290 -snap {("G5" 0)}
wvZoom -win $_nWave4 0.000000 8055489.202899
wvZoom -win $_nWave4 0.000000 677128.077925
wvZoom -win $_nWave4 25024.298532 396954.068870
wvZoom -win $_nWave4 123936.056296 298042.311106
wvZoomAll -win $_nWave4
wvZoom -win $_nWave4 15687005.289855 102601494.057971
wvZoom -win $_nWave4 15687005.289850 53349950.422700
wvZoom -win $_nWave4 15878049.214437 26167129.152904
wvSetCursor -win $_nWave4 15967519.474764 -snap {("G1" 2)}
wvZoomAll -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoom -win $_nWave4 1154382.246377 45703042.572464
wvZoom -win $_nWave4 2477929.400992 33436020.163830
wvSetCursor -win $_nWave4 3016330.979475 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2567662.997405 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2477929.400991 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2477929.400991 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2477929.400991 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2634960.590064 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 2634960.590064 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 628124.756292 -snap {("G3" 2)}
wvSetCursor -win $_nWave4 628124.756292 -snap {("G3" 2)}
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvSelectSignal -win $_nWave4 {( "G4" 2 )} 
wvSelectSignal -win $_nWave4 {( "G3" 3 )} 
wvSelectSignal -win $_nWave4 {( "G3" 2 )} 
wvSelectSignal -win $_nWave4 {( "G4" 2 )} 
wvSetCursor -win $_nWave4 192082.793777 -snap {("G5" 0)}
wvSelectSignal -win $_nWave4 {( "G4" 4 )} 
wvSelectGroup -win $_nWave4 {G5}
wvZoomOut -win $_nWave4
wvZoomAll -win $_nWave4
wvSelectSignal -win $_nWave4 {( "G1" 1 2 3 4 5 )} 
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiDockWidgetRestore -dock windowDock_nWave_4
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
verdiWindowBeWindow -win $_nWave4
verdiSetActWin -win $_nWave4
wvResizeWindow -win $_nWave4 0 0 1600 836
wvResizeWindow -win $_nWave4 -10 112 1431 743
wvResizeWindow -win $_nWave4 -10 19 1600 836
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBTreeAction -win $_nTrace1 -path "tb_top"
verdiSetActWin -win $_nWave4
wvResizeWindow -win $_nWave4 52 112 1431 743
wvResizeWindow -win $_nWave4 -10 19 1600 836
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBTreeAction -win $_nTrace1 -path "tb_top"
srcSignalViewSelect "tb_top.soc_uart_tx"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.soc_uart_tx" "tb_top.soc_uart_rx"
wvSetPosition -win $_nWave4 {("G4" 4)}
verdiSetActWin -win $_nWave4
wvAddSignal -win $_nWave4 "/tb_top/soc_uart_tx" "/tb_top/soc_uart_rx"
wvSetPosition -win $_nWave4 {("G4" 4)}
wvSetPosition -win $_nWave4 {("G4" 6)}
wvSetPosition -win $_nWave4 {("G4" 5)}
wvSetPosition -win $_nWave4 {("G4" 6)}
wvSetPosition -win $_nWave4 {("G5" 0)}
wvMoveSelected -win $_nWave4
wvSetPosition -win $_nWave4 {("G5" 2)}
wvSetPosition -win $_nWave4 {("G5" 2)}
wvSelectSignal -win $_nWave4 {( "G2" 1 )} {( "G5" 1 2 )} 
wvSelectSignal -win $_nWave4 {( "G5" 1 2 )} 
wvSelectSignal -win $_nWave4 {( "G2" 2 )} {( "G5" 1 2 )} 
wvSelectSignal -win $_nWave4 {( "G2" 1 2 )} {( "G5" 1 2 )} 
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G5" 0)}
wvSelectSignal -win $_nWave4 {( "G4" 1 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 3 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 4 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 3 4 )} 
wvSelectSignal -win $_nWave4 {( "G4" 1 2 3 4 )} 
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G5" 0)}
wvSelectGroup -win $_nWave4 {G6}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G5" 0)}
wvSelectGroup -win $_nWave4 {G5}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G4" 0)}
wvSelectGroup -win $_nWave4 {G4}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G3" 4)}
wvSetPosition -win $_nWave4 {("G3" 4)}
wvSelectGroup -win $_nWave4 {G2}
wvSelectGroup -win $_nWave4 {G3}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSelectGroup -win $_nWave4 {G4}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 0)}
verdiWindowBeDocked -win $_nWave4
verdiDockWidgetHide -dock widgetDock_<Message>
wvScrollDown -win $_nWave4 2
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBBTreeSelect -win $_nTrace1 -path "gpio_vip_if"
srcTBTreeAction -win $_nTrace1 -path "gpio_vip_if"
verdiSetActWin -dock widgetDock_<Decl._Tree>
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelectAll -curPage
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvAddSignal -win $_nWave4 "/tb_top/gpio_vif/aresetn" "/tb_top/gpio_vif/clk" \
           "/tb_top/gpio_vif/gpio_dir_o\[63:0\]" \
           "/tb_top/gpio_vif/gpio_i\[63:0\]" \
           "/tb_top/gpio_vif/gpio_intr_o\[1:0\]" \
           "/tb_top/gpio_vif/gpio_o\[63:0\]"
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G2" 6)}
wvSetPosition -win $_nWave4 {("G2" 6)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_4
verdiSetActWin -win $_nWave4
wvSetCursor -win $_nWave4 44029393.342981 -snap {("G3" 0)}
wvSelectSignal -win $_nWave4 {( "G2" 1 )} 
wvSelectSignal -win $_nWave4 {( "G2" 2 )} 
wvSelectSignal -win $_nWave4 {( "G2" 1 2 )} 
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 4)}
wvSetCursor -win $_nWave4 60540415.846599 -snap {("G3" 0)}
wvZoomAll -win $_nWave4
wvSetCursor -win $_nWave4 10160629.232996 -snap {("G1" 4)}
wvSelectGroup -win $_nWave4 {G3}
wvSelectAll -win $_nWave4
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSelectGroup -win $_nWave4 {G3}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSelectGroup -win $_nWave4 {G2}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 0)}
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiDockWidgetRestore -dock windowDock_nWave_4
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBBTreeSelect -win $_nTrace1 -path "tb_top"
srcTBTreeAction -win $_nTrace1 -path "tb_top"
verdiSetActWin -dock widgetDock_<Decl._Tree>
srcSignalViewSelect "tb_top.soc_uart_tx"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.soc_uart_tx" "tb_top.soc_uart_rx"
wvAddSignal -win $_nWave4 "/tb_top/soc_uart_tx" "/tb_top/soc_uart_rx"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSelectGroup -win $_nWave4 {G2}
verdiSetActWin -win $_nWave4
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]" "tb_top.soc_gpio_intr\[1:0\]"
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]" "tb_top.soc_gpio_intr\[1:0\]" \
           "tb_top.soc_gpio_i\[63:0\]"
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]" "tb_top.soc_gpio_i\[63:0\]"
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]" "tb_top.soc_gpio_i\[63:0\]" \
           "tb_top.soc_gpio_dir_o\[63:0\]"
srcSignalViewSelect "tb_top.soc_gpio_o\[63:0\]" "tb_top.soc_gpio_i\[63:0\]" \
           "tb_top.soc_gpio_dir_o\[63:0\]" "tb_top.soc_gpio_intr\[1:0\]"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvAddSignal -win $_nWave4 "/tb_top/soc_gpio_o\[63:0\]" \
           "/tb_top/soc_gpio_i\[63:0\]" "/tb_top/soc_gpio_dir_o\[63:0\]" \
           "/tb_top/soc_gpio_intr\[1:0\]"
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G2" 4)}
wvSetPosition -win $_nWave4 {("G2" 4)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_4
verdiSetActWin -win $_nWave4
wvSetCursor -win $_nWave4 2540157.308249 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 6350393.270622 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 846719.102750 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 11854067.438495 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 14817584.298119 -snap {("G2" 0)}
wvSetCursor -win $_nWave4 15240943.849493 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 16934382.054993 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 20744618.017366 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 36832280.969609 -snap {("G1" 2)}
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiDockWidgetRestore -dock windowDock_nWave_4
srcSignalViewSelect "tb_top.CLK_PERIOD"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_top.UART_CLK_PERIOD"
srcSignalViewSelect "tb_top.aresetn"
srcSignalViewSelect "tb_top.aresetn" "tb_top.clk"
srcSignalViewSelect "tb_top.clk"
srcSignalViewSelect "tb_top.clk"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G2" 1)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G2" 2)}
wvSetPosition -win $_nWave4 {("G2" 1)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G1" 2)}
wvSetPosition -win $_nWave4 {("G1" 1)}
wvSetPosition -win $_nWave4 {("G1" 0)}
wvAddSignal -win $_nWave4 "/tb_top/clk"
wvSetPosition -win $_nWave4 {("G1" 0)}
wvSetPosition -win $_nWave4 {("G1" 1)}
verdiSetActWin -win $_nWave4
wvScrollDown -win $_nWave4 3
wvSelectSignal -win $_nWave4 {( "G2" 4 )} 
wvSelectSignal -win $_nWave4 {( "G2" 1 4 )} 
wvSelectSignal -win $_nWave4 {( "G2" 1 2 4 )} 
wvSelectSignal -win $_nWave4 {( "G2" 1 2 3 4 )} 
wvSetPosition -win $_nWave4 {("G2" 1)}
wvSetPosition -win $_nWave4 {("G2" 0)}
wvSetPosition -win $_nWave4 {("G1" 3)}
wvMoveSelected -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 3)}
wvSetPosition -win $_nWave4 {("G1" 7)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_4
wvZoomAll -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomAll -win $_nWave4
wvSetCursor -win $_nWave4 9300450.722543 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 24096622.326590 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 15218919.364162 -snap {("G1" 3)}
wvGoToTime -win $_nWave4 8390000
wvSetCursor -win $_nWave4 1690991.040462 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 5918468.641618 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 3381982.080925 -snap {("G1" 3)}
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvSetCursor -win $_nWave4 261601.336705 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 732483.742775 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 366241.871387 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 313921.604046 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 104640.534682 -snap {("G1" 1)}
wvGoToTime -win $_nWave4 200000
wvGoToTime -win $_nWave4 300000
wvSetCursor -win $_nWave4 5859869.942197 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 7586438.764451 -snap {("G1" 3)}
wvZoomAll -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomAll -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomAll -win $_nWave4
wvSetCursor -win $_nWave4 10991441.763006 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 3804729.841040 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 73135362.500000 -snap {("G3" 0)}
wvSelectSignal -win $_nWave4 {( "G1" 3 )} 
wvZoom -win $_nWave4 77785587.861272 80322074.421965
wvSetCursor -win $_nWave4 78012845.327691 -snap {("G3" 0)}
wvZoomAll -win $_nWave4
wvSetCursor -win $_nWave4 76517344.580925 -snap {("G3" 0)}
wvSelectGroup -win $_nWave4 {G3}
wvSetCursor -win $_nWave4 2536486.560694 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 16064414.884393 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 26210361.127168 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 19869144.725434 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 19446396.965318 -snap {("G1" 3)}
wvCut -win $_nWave4
wvSetPosition -win $_nWave4 {("G1" 7)}
wvSetCursor -win $_nWave4 452340103.323699 -snap {("G2" 0)}
wvSetCursor -win $_nWave4 0.000000 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 15641667.124277 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 26210361.127168 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 18178153.684971 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 7186711.921965 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 7186711.921965 -snap {("G1" 3)}
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvSetCursor -win $_nWave4 16219282.875723 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 15486799.132948 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 11091896.676301 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 9522288.656069 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 8685164.378613 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 8266602.239884 -snap {("G1" 1)}
wvSetCursor -win $_nWave4 100245632.225433 -snap {("G2" 0)}
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvSetCursor -win $_nWave4 57193808.968034 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 6278432.080925 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 2302091.763006 -snap {("G1" 2)}
wvSetCursor -win $_nWave4 14440393.786127 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 0.000000 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 837124.277457 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 209281.069364 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 418562.138728 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 3976340.317919 -snap {("G1" 3)}
wvSetCursor -win $_nWave4 11719739.884393 -snap {("G1" 3)}
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanRight -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvPanLeft -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvSelectSignal -win $_nWave4 {( "G1" 3 )} 
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvSetCursor -win $_nWave4 458258571.965318 -snap {("G2" 0)}
wvZoom -win $_nWave4 845495.520231 584237404.479769
wvZoom -win $_nWave4 4639229.032251 583394352.588209
wvZoom -win $_nWave4 33911525.743896 582558001.253590
wvZoom -win $_nWave4 1189262.591423 547853633.782079
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomIn -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4
wvZoomOut -win $_nWave4

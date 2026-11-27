// =============================================================================
// File        : tb/soc_cov_inst.svh
// Description : Shared instantiation macro binding soc_cov_collector to a
//               soc_top instance without duplicating port maps across testbenches.
// =============================================================================

`ifndef SOC_COV_INST_SVH
`define SOC_COV_INST_SVH

`define INST_SOC_COV(SOC_INST, CPU_MODE, BOOT_OK, CPU_HALT) \
    soc_cov_collector u_soc_cov ( \
        .clk              (clk), \
        .aresetn          (aresetn), \
        .is_cpu_mode      (CPU_MODE), \
        .cpu_boot_ok      (BOOT_OK), \
        .cpu_halted       (CPU_HALT), \
        .s00_awvalid      (SOC_INST.s00_awvalid), \
        .s00_awready      (SOC_INST.s00_awready), \
        .s00_awaddr       (SOC_INST.s00_awaddr), \
        .s00_bvalid       (SOC_INST.s00_bvalid), \
        .s00_bready       (SOC_INST.s00_bready), \
        .s00_bresp        (SOC_INST.s00_bresp), \
        .s00_arvalid      (SOC_INST.s00_arvalid), \
        .s00_arready      (SOC_INST.s00_arready), \
        .s00_araddr       (SOC_INST.s00_araddr), \
        .s00_rvalid       (SOC_INST.s00_rvalid), \
        .s00_rready       (SOC_INST.s00_rready), \
        .s00_rresp        (SOC_INST.s00_rresp), \
        .s01_awvalid      (SOC_INST.s01_awvalid), \
        .s01_awready      (SOC_INST.s01_awready), \
        .s01_awaddr       (SOC_INST.s01_awaddr), \
        .s01_arvalid      (SOC_INST.s01_arvalid), \
        .s01_arready      (SOC_INST.s01_arready), \
        .s01_araddr       (SOC_INST.s01_araddr), \
        .m05_awvalid      (SOC_INST.m05_awvalid), \
        .m05_awready      (SOC_INST.m05_awready), \
        .m05_awlen        (SOC_INST.m05_awlen), \
        .m05_wvalid       (SOC_INST.m05_wvalid), \
        .m05_wready       (SOC_INST.m05_wready), \
        .m05_wstrb        (SOC_INST.m05_wstrb), \
        .m05_arvalid      (SOC_INST.m05_arvalid), \
        .m05_arready      (SOC_INST.m05_arready), \
        .m05_arlen        (SOC_INST.m05_arlen), \
        .uart_tx_pin      (SOC_INST.uart_tx), \
        .uart_lcr         (SOC_INST.u_uart.uart_config_reg_int), \
        .uart_baud_div    (SOC_INST.u_uart.uart_baudrate_div_int), \
        .uart_irq_en      (SOC_INST.u_uart.uart_irq_en_int), \
        .uart_lsr         (SOC_INST.u_uart.uart_lsr_reg_int), \
        .uart_rx_push     (SOC_INST.u_uart.push_controller_rx_fifo), \
        .uart_wr_hpn      (SOC_INST.u_uart.axi_bvalid_o && SOC_INST.u_uart.axi_bready_i), \
        .uart_rd_hpn      (SOC_INST.u_uart.axi_rvalid_o && SOC_INST.u_uart.axi_rready_i), \
        .uart_irq         (SOC_INST.uart_irq), \
        .tmr_active       (SOC_INST.u_timer.reg_active), \
        .tmr_prescale     (SOC_INST.u_timer.reg_prescale), \
        .tmr_step         (SOC_INST.u_timer.reg_step), \
        .tmr_intr_en      (SOC_INST.u_timer.reg_intr_en), \
        .tmr_intr_state   (SOC_INST.u_timer.reg_intr_state), \
        .tmr_irq          (SOC_INST.timer_irq), \
        .gpio_wr_hpn      (SOC_INST.u_gpio.s_axi_awvalid && SOC_INST.u_gpio.s_axi_awready), \
        .gpio_awaddr      (SOC_INST.u_gpio.s_axi_awaddr), \
        .gpio_en_0        (SOC_INST.u_gpio.reg_en_0), \
        .gpio_en_1        (SOC_INST.u_gpio.reg_en_1), \
        .gpio_rise_en_0   (SOC_INST.u_gpio.reg_rise_en_0), \
        .gpio_rise_en_1   (SOC_INST.u_gpio.reg_rise_en_1), \
        .gpio_fall_en_0   (SOC_INST.u_gpio.reg_fall_en_0), \
        .gpio_fall_en_1   (SOC_INST.u_gpio.reg_fall_en_1), \
        .gpio_high_en_0   (SOC_INST.u_gpio.reg_high_en_0), \
        .gpio_high_en_1   (SOC_INST.u_gpio.reg_high_en_1), \
        .gpio_low_en_0    (SOC_INST.u_gpio.reg_low_en_0), \
        .gpio_low_en_1    (SOC_INST.u_gpio.reg_low_en_1), \
        .gpio_intr        (SOC_INST.gpio_intr), \
        .sha_wr_hpn       (SOC_INST.u_sha.s_axi_awvalid && SOC_INST.u_sha.s_axi_awready), \
        .sha_awaddr       (SOC_INST.u_sha.s_axi_awaddr), \
        .sha_wdata        (SOC_INST.u_sha.s_axi_wdata), \
        .sha_irq          (SOC_INST.sha_irq), \
        .aes_key_size     (SOC_INST.u_aes.ctrl_key_size), \
        .aes_decrypt      (SOC_INST.u_aes.ctrl_decrypt), \
        .aes_mode_cbc     (SOC_INST.u_aes.ctrl_mode_cbc), \
        .aes_mode_ctr     (SOC_INST.u_aes.ctrl_mode_ctr), \
        .aes_total_blocks (SOC_INST.u_aes.total_blocks), \
        .aes_irq_en       (SOC_INST.u_aes.ctrl_irq_en), \
        .aes_soft_rst     (SOC_INST.u_aes.ctrl_soft_rst), \
        .aes_done_pulse   (SOC_INST.u_aes.core_done_r), \
        .aes_irq          (SOC_INST.aes_irq), \
        .dma_desc_en      (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_desc_en), \
        .dma_desc_rd_mod  (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_desc_rd_mod), \
        .dma_desc_wr_mod  (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_desc_wr_mod), \
        .dma_go           (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_ctrl.go), \
        .dma_max_burst    (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_ctrl.max_burst), \
        .dma_done         (SOC_INST.dma_done), \
        .dma_error        (SOC_INST.dma_error), \
        .dma_err_valid    (SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_error.valid), \
        .dma_err_src      (1'(SOC_INST.u_dma_controller.u_dma_axi_wrapper.dma_error.src)) \
    );

`endif

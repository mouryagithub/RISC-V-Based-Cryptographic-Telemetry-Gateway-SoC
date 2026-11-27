// =============================================================================
// File        : soc_test.h
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : DPI-C interface declarations and test framework functions
// =============================================================================

#ifndef SOC_TEST_H
#define SOC_TEST_H

#include <stdint.h>
#include "soc_regs.h"

#ifdef __cplusplus
extern "C" {
#endif

// =============================================================================
// DPI-C Functions exported from SystemVerilog Testbench to C
// =============================================================================
extern void sv_axi_write(uint32_t addr, uint32_t data);
extern void sv_axi_read(uint32_t addr, uint32_t *data);
extern void sv_axi_write_resp(uint32_t addr, uint32_t data, uint32_t *resp);
extern void sv_axi_write_strb(uint32_t addr, uint32_t data,
                              uint32_t wstrb, uint32_t *resp);
extern void sv_axi_read_resp(uint32_t addr, uint32_t *data, uint32_t *resp);
extern void sv_axi_concurrent_rw(uint32_t wr_addr, uint32_t wr_data,
                                 uint32_t rd_addr, uint32_t *rd_data,
                                 uint32_t *bresp, uint32_t *rresp);
extern void sv_delay_cycles(int cycles);
extern void sv_uart_send_byte(uint8_t byte_val);
extern void sv_uart_send_err(uint8_t byte_val, uint8_t parity_en,
                             uint8_t parity_odd, uint8_t corrupt_parity,
                             uint8_t corrupt_stop);
extern void sv_uart_recv_byte(uint8_t *rx_byte);
extern void sv_uart_tx_loopback(uint8_t tx_val, uint8_t *rx_cap);
extern void sv_uart_b2b_tx(uint8_t b0, uint8_t b1, uint8_t b2,
                           uint8_t *r0, uint8_t *r1, uint8_t *r2);
extern void sv_set_gpio_in(uint32_t in_val_low, uint32_t in_val_high);
extern void sv_get_gpio_out(uint32_t *out_val_low, uint32_t *out_val_high);
extern void sv_get_gpio_dir(uint32_t *dir_val_low, uint32_t *dir_val_high);
extern void sv_get_gpio_intr(uint32_t *bank0_intr, uint32_t *bank1_intr);
extern void sv_get_irqs(uint32_t *uart_irq, uint32_t *timer_irq,
                        uint32_t *aes_irq, uint32_t *sha_irq,
                        uint32_t *dma_done, uint32_t *dma_error);
extern void sv_get_aes_done_dout(uint32_t *w3, uint32_t *w2,
                                 uint32_t *w1, uint32_t *w0,
                                 uint32_t *valid);
extern void sv_get_sim_flags(uint32_t *is_xsim);
extern void sv_axi_burst_wr4(uint32_t addr, uint32_t burst,
                             uint32_t w0, uint32_t w1, uint32_t w2, uint32_t w3,
                             uint32_t *bresp);
extern void sv_axi_burst_rd4(uint32_t addr, uint32_t burst,
                             uint32_t *w0, uint32_t *w1, uint32_t *w2, uint32_t *w3,
                             uint32_t *rresp);
extern void sv_uart_send_cfg(uint8_t byte_val, uint32_t baud_div,
                             uint8_t parity_en, uint8_t parity_odd,
                             uint8_t stop_2bit, uint8_t err_mask);
extern void sv_uart_tx_cfg(uint8_t tx_val, uint32_t baud_div,
                           uint8_t parity_en, uint8_t parity_odd,
                           uint8_t stop_2bit, uint8_t *rx_cap,
                           uint32_t *frame_ok);

// =============================================================================
// Memory-Mapped I/O C Access Wrappers
// =============================================================================
static inline void soc_write32(uint32_t addr, uint32_t data) {
    sv_axi_write(addr, data);
}

static inline uint32_t soc_read32(uint32_t addr) {
    uint32_t data = 0;
    sv_axi_read(addr, &data);
    return data;
}

// =============================================================================
// Test Suite Function Declarations
// =============================================================================
int test_sram_c(void);
int test_uart_c(void);
int test_gpio_c(void);
int test_timer_c(void);
int test_sha256_c(void);
int test_aes256_c(void);
int test_dma_c(void);
int test_pipelines_and_bus_c(void);

// Main C Test Entry Point (called from SystemVerilog testbench)
int soc_c_main(int *status);

#ifdef __cplusplus
}
#endif

#endif // SOC_TEST_H

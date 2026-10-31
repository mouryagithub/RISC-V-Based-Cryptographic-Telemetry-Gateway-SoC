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
extern void sv_delay_cycles(int cycles);
extern void sv_uart_send_byte(uint8_t byte_val);
extern void sv_uart_recv_byte(uint8_t *rx_byte);
extern void sv_uart_tx_loopback(uint8_t tx_val, uint8_t *rx_cap);
extern void sv_uart_b2b_tx(uint8_t b0, uint8_t b1, uint8_t b2,
                           uint8_t *r0, uint8_t *r1, uint8_t *r2);
extern void sv_set_gpio_in(uint32_t in_val_low, uint32_t in_val_high);
extern void sv_get_gpio_out(uint32_t *out_val_low, uint32_t *out_val_high);
extern void sv_get_irqs(uint32_t *uart_irq, uint32_t *timer_irq,
                        uint32_t *aes_irq, uint32_t *sha_irq,
                        uint32_t *dma_done, uint32_t *dma_error);

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
int test_uart_c(void);
int test_gpio_c(void);
int test_timer_c(void);
int test_sha256_c(void);
int test_aes256_c(void);

// Main C Test Entry Point (called from SystemVerilog testbench)
int soc_c_main(int *status);

#ifdef __cplusplus
}
#endif

#endif // SOC_TEST_H

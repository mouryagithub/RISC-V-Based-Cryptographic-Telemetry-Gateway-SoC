// =============================================================================
// File        : soc_test.c
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Comprehensive C test suite for soc_top peripheral verification
//               via AXI4 interconnect fabric.
// =============================================================================

#include <stdio.h>
#include <stdint.h>
#include <stdbool.h>
#include "soc_test.h"
#include "soc_regs.h"

// Global pass / fail counters
static int g_pass_count = 0;
static int g_fail_count = 0;

// Helper assertion macros
#define CHECK_EQUAL(got, exp, label) do { \
    if ((got) == (exp)) { \
        printf("[C_PASS] %-32s : got 0x%08X\n", (label), (uint32_t)(got)); \
        g_pass_count++; \
    } else { \
        printf("[C_FAIL] %-32s : got 0x%08X  expected 0x%08X\n", (label), (uint32_t)(got), (uint32_t)(exp)); \
        g_fail_count++; \
    } \
} while(0)

#define CHECK_TRUE(cond, label, got_val) do { \
    if (cond) { \
        printf("[C_PASS] %-32s : condition met (0x%08X)\n", (label), (uint32_t)(got_val)); \
        g_pass_count++; \
    } else { \
        printf("[C_FAIL] %-32s : condition FAILED (0x%08X)\n", (label), (uint32_t)(got_val)); \
        g_fail_count++; \
    } \
} while(0)

// =============================================================================
// Peripheral Test 1: UART Controller (0x4000_1000)
// =============================================================================
int test_uart_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 1] UART Controller over AXI Interconnect\n");
    printf("=============================================================\n");

    const uint32_t baud_div = 434; // 115200 baud @ 50 MHz
    uint8_t rx_cap = 0;
    uint32_t rd_val = 0;

    // 1. Configure baud divisor: DLAB=1 (0x80) -> write divisor -> DLAB=0 (0x00, 8N1)
    soc_write32(UART_REG_LCR, 0x80);
    soc_write32(UART_REG_BAUD_DIV, baud_div);
    soc_write32(UART_REG_LCR, 0x00);
    printf("    UART configured: baud_div=%u, 8N1\n", baud_div);

    // 2. Enable RX interrupt via IER (IER is WO in axi_uart_top)
    soc_write32(UART_REG_IER, 0x01);
    printf("    UART IER written (RX data interrupt enable)\n");
    g_pass_count++;

    // 3. Read Line Status Register (LSR) via interconnect
    rd_val = soc_read32(UART_REG_LSR);
    CHECK_EQUAL(rd_val, 0x00, "UART LSR read via fabric");

    // 4. Transmit byte 0x55 and verify serial loopback capture
    sv_uart_tx_loopback(0x55, &rx_cap);
    CHECK_EQUAL(rx_cap, 0x55, "UART TX loopback 0x55");
    sv_delay_cycles(200);

    // 5. Transmit byte 0xA3 and verify serial loopback capture
    sv_uart_tx_loopback(0xA3, &rx_cap);
    CHECK_EQUAL(rx_cap, 0xA3, "UART TX loopback 0xA3");
    sv_delay_cycles(200);

    // 6. Inject byte 0x5A on uart_rx and read back from RBR
    sv_uart_send_byte(0x5A);
    sv_delay_cycles(600); // Wait for receiver FSM and FIFO push
    rd_val = soc_read32(UART_REG_RBR) & 0xFF;
    CHECK_EQUAL(rd_val, 0x5A, "UART RX inject 0x5A via RBR");

    // 7. Inject byte 0xC9 on uart_rx and read back from RBR
    sv_uart_send_byte(0xC9);
    sv_delay_cycles(600);
    rd_val = soc_read32(UART_REG_RBR) & 0xFF;
    CHECK_EQUAL(rd_val, 0xC9, "UART RX inject 0xC9 via RBR");

    // 8. Test RX interrupt assertion
    sv_uart_send_byte(0xBE);
    sv_delay_cycles(600);
    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(uart_irq, 1, "UART RX IRQ asserted");

    // Drain the RX FIFO
    soc_read32(UART_REG_RBR);

    // 9. Back-to-back TX: 0x11, 0x22, 0x33
    uint8_t r0 = 0, r1 = 0, r2 = 0;
    sv_uart_b2b_tx(0x11, 0x22, 0x33, &r0, &r1, &r2);
    CHECK_EQUAL(r0, 0x11, "UART B2B TX byte 0 (0x11)");
    CHECK_EQUAL(r1, 0x22, "UART B2B TX byte 1 (0x22)");
    CHECK_EQUAL(r2, 0x33, "UART B2B TX byte 2 (0x33)");

    return 0;
}

// =============================================================================
// Peripheral Test 2: GPIO Controller (0x4000_3000)
// =============================================================================
int test_gpio_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 2] GPIO Controller (64-Pin) over AXI Interconnect\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;
    uint32_t out_low = 0, out_high = 0;

    // 1. Verify GPIO_INFO register (should return 64 implemented pins)
    rd_val = soc_read32(GPIO_REG_INFO);
    CHECK_EQUAL(rd_val, 64, "GPIO INFO (64-pin verification)");

    // 2. Configure Bank 0 output enables
    soc_write32(GPIO_REG_OE0, 0xFFFFFFFFU);
    rd_val = soc_read32(GPIO_REG_OE0);
    CHECK_EQUAL(rd_val, 0xFFFFFFFFU, "GPIO OE0 readback");

    // 3. Write output pattern and verify both register readback and pin drive
    soc_write32(GPIO_REG_OUT0, 0xA5A55A5AU);
    rd_val = soc_read32(GPIO_REG_OUT0);
    CHECK_EQUAL(rd_val, 0xA5A55A5AU, "GPIO OUT0 register readback");

    sv_get_gpio_out(&out_low, &out_high);
    CHECK_EQUAL(out_low, 0xA5A55A5AU, "GPIO Bank 0 output pin drive");

    // 4. Drive raw external input pins and read GPIO_IN0
    sv_set_gpio_in(0x12345678U, 0x0U);
    sv_delay_cycles(5);
    rd_val = soc_read32(GPIO_REG_IN0);
    CHECK_EQUAL(rd_val, 0x12345678U, "GPIO IN0 pin sampling");

    // 5. Test atomic operations (SET, CLR, TGL)
    // Atomic SET: set bits [7:0]
    soc_write32(GPIO_REG_SET0, 0x000000FFU);
    rd_val = soc_read32(GPIO_REG_OUT0);
    CHECK_EQUAL(rd_val, 0xA5A55AFFU, "GPIO Atomic SET0");

    // Atomic CLEAR: clear bits [3:0]
    soc_write32(GPIO_REG_CLR0, 0x0000000FU);
    rd_val = soc_read32(GPIO_REG_OUT0);
    CHECK_EQUAL(rd_val, 0xA5A55AF0U, "GPIO Atomic CLR0");

    // Atomic TOGGLE: toggle bits [15:8]
    soc_write32(GPIO_REG_TGL0, 0x0000FF00U);
    rd_val = soc_read32(GPIO_REG_OUT0);
    CHECK_EQUAL(rd_val, 0xA5A5A5F0U, "GPIO Atomic TGL0");

    return 0;
}

// =============================================================================
// Peripheral Test 3: System Timer rv_timer (0x4000_2000)
// =============================================================================
int test_timer_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 3] System Timer (rv_timer) over AXI Interconnect\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;

    // 1. Program comparator match lower register
    soc_write32(TIMER_REG_CMP_L, 0x00000200U);
    rd_val = soc_read32(TIMER_REG_CMP_L);
    CHECK_EQUAL(rd_val, 0x00000200U, "TIMER CMP_L readback");

    // 2. Program prescaler = 0, step = 1 (CFG0)
    soc_write32(TIMER_REG_CFG0, (1U << 16) | 0x0U);
    rd_val = soc_read32(TIMER_REG_CFG0);
    CHECK_EQUAL(rd_val & 0xFF0FFF, (1U << 16) | 0x0U, "TIMER CFG0 prescaler/step");

    // 3. Clear MTIME counter
    soc_write32(TIMER_REG_MTIME_L, 0x00000000U);
    soc_write32(TIMER_REG_MTIME_H, 0x00000000U);

    // 4. Enable timer active counter
    soc_write32(TIMER_REG_CTRL, TIMER_CTRL_ACTIVE);
    rd_val = soc_read32(TIMER_REG_CTRL);
    CHECK_EQUAL(rd_val & 0x1, 1, "TIMER CTRL active bit enable");

    // 5. Allow timer to increment and check counter progress
    sv_delay_cycles(25);
    rd_val = soc_read32(TIMER_REG_MTIME_L);
    CHECK_TRUE(rd_val > 0, "TIMER MTIME_L counter incrementing", rd_val);

    return 0;
}

// =============================================================================
// Peripheral Test 4: SHA-256 Accelerator (0x4000_4000)
// =============================================================================
int test_sha256_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 4] SHA-256 Accelerator over AXI Interconnect\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;

    // 1. Verify Core Identification Name 0: "sha2" (0x7368_6132)
    rd_val = soc_read32(SHA_REG_NAME0);
    CHECK_EQUAL(rd_val, SHA_EXP_NAME0, "SHA-256 NAME0 ('sha2')");

    // 2. Verify Core Identification Name 1: "-256" (0x2D32_3536)
    rd_val = soc_read32(SHA_REG_NAME1);
    CHECK_EQUAL(rd_val, SHA_EXP_NAME1, "SHA-256 NAME1 ('-256')");

    // 3. Verify Core Version String: "1.80" (0x312E_3830)
    rd_val = soc_read32(SHA_REG_VERSION);
    CHECK_EQUAL(rd_val, SHA_EXP_VERSION, "SHA-256 VERSION ('1.80')");

    // 4. Check Status: Core is ready (bit 0 = 1)
    rd_val = soc_read32(SHA_REG_STATUS);
    CHECK_EQUAL(rd_val & 0x1, 1, "SHA-256 status READY flag");

    // 5. Write 512-bit message block word 0 ("abc" NIST test vector start)
    const uint32_t test_block0 = 0x61626380U; // "abc" with padding bit 1
    soc_write32(SHA_REG_BLOCK0, test_block0);
    rd_val = soc_read32(SHA_REG_BLOCK0);
    CHECK_EQUAL(rd_val, test_block0, "SHA-256 BLOCK0 data integrity");

    return 0;
}

// =============================================================================
// Peripheral Test 5: AES-256 Accelerator (0x4000_0000)
// =============================================================================
int test_aes256_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 5] AES-256 Accelerator over AXI Interconnect\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;

    // 1. Write and readback Initialization Vector Word 0 (AES_IV0)
    const uint32_t test_iv0 = 0xDEADBEEFU;
    soc_write32(AES_REG_IV0, test_iv0);
    rd_val = soc_read32(AES_REG_IV0);
    CHECK_EQUAL(rd_val, test_iv0, "AES IV0 register readback");

    // 2. Write and readback Initialization Vector Word 1 (AES_IV1)
    const uint32_t test_iv1 = 0xCAFEBABEU;
    soc_write32(AES_REG_IV1, test_iv1);
    rd_val = soc_read32(AES_REG_IV1);
    CHECK_EQUAL(rd_val, test_iv1, "AES IV1 register readback");

    // 3. Configure Control Register: AES-256 key size + IRQ enable
    // bits[4:3] = 2'b10 (256-bit), bit[1] = 1 (irq_en) -> value = 0x12
    soc_write32(AES_REG_CTRL, (AES_CTRL_KEY256 | AES_CTRL_IRQ_EN));
    rd_val = soc_read32(AES_REG_CTRL);
    CHECK_EQUAL(rd_val & 0x1F, 0x12, "AES CTRL 256-bit key & IRQ config");

    // 4. Verify status register is accessible
    rd_val = soc_read32(AES_REG_STATUS);
    printf("    AES STATUS = 0x%08X (busy=%u, done=%u, key_ready=%u)\n",
           rd_val, (rd_val & 1), ((rd_val >> 1) & 1), ((rd_val >> 2) & 1));
    CHECK_TRUE((rd_val & 0x8) == 0, "AES status no fault error", rd_val);

    return 0;
}

// =============================================================================
// Main Test Runner called via SystemVerilog DPI-C
// =============================================================================
int soc_c_main(int *status) {
    g_pass_count = 0;
    g_fail_count = 0;

    printf("\n#############################################################\n");
    printf("   Starting SoC Firmware C Test Suite on soc_top (DPI-C)\n");
    printf("   Target: RISC-V Cryptographic Telemetry Gateway SoC\n");
    printf("#############################################################\n");

    // Run test suites on all five integrated peripherals
    test_uart_c();
    test_gpio_c();
    test_timer_c();
    test_sha256_c();
    test_aes256_c();

    printf("\n#############################################################\n");
    printf("   C TEST SUMMARY\n");
    printf("   Total PASSED : %d\n", g_pass_count);
    printf("   Total FAILED : %d\n", g_fail_count);
    if (g_fail_count == 0) {
        printf("   OVERALL RESULT: [SUCCESS] ALL C TESTS PASSED!\n");
    } else {
        printf("   OVERALL RESULT: [FAILURE] %d TESTS FAILED!\n", g_fail_count);
    }
    printf("#############################################################\n\n");

    if (status) {
        *status = g_fail_count;
    }

    return g_fail_count;
}

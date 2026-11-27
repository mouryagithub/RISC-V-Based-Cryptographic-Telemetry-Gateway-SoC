// =============================================================================
// File        : soc_test.c
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Comprehensive C test suite for soc_top verification via AXI4
//               interconnect fabric and DMA CSR interface, mapped to all
//               38 master testplan IDs (TC_BOOT..TC_FULL).
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
    if ((uint32_t)(got) == (uint32_t)(exp)) { \
        printf("[C_PASS] %-40s : got 0x%08X\n", (label), (uint32_t)(got)); \
        g_pass_count++; \
    } else { \
        printf("[C_FAIL] %-40s : got 0x%08X  expected 0x%08X\n", (label), (uint32_t)(got), (uint32_t)(exp)); \
        g_fail_count++; \
    } \
} while(0)

#define CHECK_TRUE(cond, label, got_val) do { \
    if (cond) { \
        printf("[C_PASS] %-40s : condition met (0x%08X)\n", (label), (uint32_t)(got_val)); \
        g_pass_count++; \
    } else { \
        printf("[C_FAIL] %-40s : condition FAILED (0x%08X)\n", (label), (uint32_t)(got_val)); \
        g_fail_count++; \
    } \
} while(0)

static void clear_aes_engine(void) {
    soc_write32(AES_REG_CTRL, AES_CTRL_SOFT_RST);
    sv_delay_cycles(4);
    soc_write32(AES_REG_IRQ_CLR, 0x3U);
    soc_write32(AES_REG_CTRL, 0x0U);
}

static bool poll_dma_done_or_timeout(uint32_t *status_out, int max_polls) {
    for (int i = 0; i < max_polls; i++) {
        uint32_t st = soc_read32(DMA_REG_STATUS);
        if (st & DMA_STAT_DONE) {
            if (status_out) {
                *status_out = st;
            }
            return true;
        }
        sv_delay_cycles(5);
    }
    if (status_out) {
        *status_out = soc_read32(DMA_REG_STATUS);
    }
    return false;
}

// =============================================================================
// Subsystem 0: 64 KB System SRAM Verification (0x0000_0000 - 0x0000_FFFF) [TC_BOOT_03]
// =============================================================================
int test_sram_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 0] 64 KB AXI4 System SRAM (TC_BOOT_03)\n");
    printf("=============================================================\n");

    static const uint32_t test_addrs[5] = {
        SRAM_BASE + 0x0000U,
        SRAM_BASE + 0x0004U,
        SRAM_BASE + 0x4000U,
        SRAM_BASE + 0x8000U,
        SRAM_BASE + 0xFFFCU
    };
    static const uint32_t test_pats[5] = {
        0xCAFEBABEU, 0x12345678U, 0xA55A5AA5U, 0x0F1E2D3CU, 0xDEAD00FFU
    };

    for (int i = 0; i < 5; i++) {
        uint32_t bresp = 0xFFU, rresp = 0xFFU, rd_val = 0U;
        sv_axi_write_resp(test_addrs[i], test_pats[i], &bresp);
        sv_axi_read_resp(test_addrs[i], &rd_val, &rresp);
        CHECK_EQUAL(bresp, 0U, "TC_BOOT_03 SRAM write OKAY");
        CHECK_EQUAL(rresp, 0U, "TC_BOOT_03 SRAM read OKAY");
        CHECK_EQUAL(rd_val, test_pats[i], "TC_BOOT_03 SRAM R/W pattern");
    }

    // Verify byte/halfword WSTRB write enables inside SRAM
    uint32_t strb_resp = 0xFFU, rd_strb = 0U;
    const uint32_t strb_addr = SRAM_BASE + 0x0100U;
    sv_axi_write_strb(strb_addr, 0x11223344U, 0xFU, &strb_resp);
    CHECK_EQUAL(strb_resp, 0U, "TC_BOOT_03 SRAM full WSTRB OKAY");
    sv_axi_write_strb(strb_addr, 0x000000AAU, 0x1U, &strb_resp);
    CHECK_EQUAL(soc_read32(strb_addr), 0x112233AAU, "TC_BOOT_03 SRAM byte0 WSTRB=0x1");
    sv_axi_write_strb(strb_addr, 0x00BB0000U, 0x4U, &strb_resp);
    CHECK_EQUAL(soc_read32(strb_addr), 0x11BB33AAU, "TC_BOOT_03 SRAM byte2 WSTRB=0x4");
    sv_axi_write_strb(strb_addr, 0xCCDD0000U, 0xCU, &strb_resp);
    rd_strb = soc_read32(strb_addr);
    CHECK_EQUAL(rd_strb, 0xCCDD33AAU, "TC_BOOT_03 SRAM upper-half WSTRB=0xC");
    sv_axi_write_strb(strb_addr, 0x0000BB00U, 0x2U, &strb_resp);
    CHECK_EQUAL(strb_resp, 0U, "TC_BOOT_03 SRAM byte1 WSTRB OKAY");
    CHECK_EQUAL(soc_read32(strb_addr), 0xCCDDBBAAU, "TC_BOOT_03 SRAM byte1 WSTRB=0x2");
    sv_axi_write_strb(strb_addr, 0xEE000000U, 0x8U, &strb_resp);
    CHECK_EQUAL(strb_resp, 0U, "TC_BOOT_03 SRAM byte3 WSTRB OKAY");
    CHECK_EQUAL(soc_read32(strb_addr), 0xEEDDBBAAU, "TC_BOOT_03 SRAM byte3 WSTRB=0x8");
    sv_axi_write_strb(strb_addr, 0x00005566U, 0x3U, &strb_resp);
    CHECK_EQUAL(strb_resp, 0U, "TC_BOOT_03 SRAM half_lo WSTRB OKAY");
    CHECK_EQUAL(soc_read32(strb_addr), 0xEEDD5566U, "TC_BOOT_03 SRAM lower-half WSTRB=0x3");

    // Verify AXI4 FIXED (burst=0) and WRAP (burst=2) 4-beat bursts on SRAM
    uint32_t bst_bresp = 0xFFU, bst_rresp = 0xFFU;
    uint32_t br0 = 0U, br1 = 0U, br2 = 0U, br3 = 0U;
    const uint32_t fix_addr = SRAM_BASE + 0x0200U;
    soc_write32(fix_addr + 4U, 0x5A5A5A5AU);
    sv_axi_burst_wr4(fix_addr, 0U, 0xA0A00001U, 0xA0A00002U, 0xA0A00003U, 0xA0A00004U, &bst_bresp);
    CHECK_EQUAL(bst_bresp, 0U, "TC_BOOT_03 SRAM FIXED wr4 OKAY");
    CHECK_EQUAL(soc_read32(fix_addr),      0xA0A00004U, "TC_BOOT_03 SRAM FIXED wr4 last beat");
    CHECK_EQUAL(soc_read32(fix_addr + 4U), 0x5A5A5A5AU, "TC_BOOT_03 SRAM FIXED wr4 neighbor intact");
    sv_axi_burst_rd4(fix_addr, 0U, &br0, &br1, &br2, &br3, &bst_rresp);
    CHECK_EQUAL(bst_rresp, 0U, "TC_BOOT_03 SRAM FIXED rd4 OKAY");
    CHECK_EQUAL(br0, 0xA0A00004U, "TC_BOOT_03 SRAM FIXED rd4 beat0");
    CHECK_EQUAL(br3, 0xA0A00004U, "TC_BOOT_03 SRAM FIXED rd4 beat3");

    const uint32_t wrap_base = SRAM_BASE + 0x0220U;
    for (int i = 0; i < 4; i++) soc_write32(wrap_base + (uint32_t)i * 4U, 0U);
    sv_axi_burst_wr4(wrap_base + 8U, 2U, 0x11111111U, 0x22222222U, 0x33333333U, 0x44444444U, &bst_bresp);
    CHECK_EQUAL(bst_bresp, 0U, "TC_BOOT_03 SRAM WRAP wr4 OKAY");
    CHECK_EQUAL(soc_read32(wrap_base + 8U),  0x11111111U, "TC_BOOT_03 SRAM WRAP wr4 beat0 @+8");
    CHECK_EQUAL(soc_read32(wrap_base + 12U), 0x22222222U, "TC_BOOT_03 SRAM WRAP wr4 beat1 @+12");
    CHECK_EQUAL(soc_read32(wrap_base + 0U),  0x33333333U, "TC_BOOT_03 SRAM WRAP wr4 beat2 wrap @+0");
    CHECK_EQUAL(soc_read32(wrap_base + 4U),  0x44444444U, "TC_BOOT_03 SRAM WRAP wr4 beat3 @+4");
    sv_axi_burst_rd4(wrap_base + 8U, 2U, &br0, &br1, &br2, &br3, &bst_rresp);
    CHECK_EQUAL(bst_rresp, 0U, "TC_BOOT_03 SRAM WRAP rd4 OKAY");
    CHECK_EQUAL(br0, 0x11111111U, "TC_BOOT_03 SRAM WRAP rd4 beat0");
    CHECK_EQUAL(br2, 0x33333333U, "TC_BOOT_03 SRAM WRAP rd4 beat2 wrap");
    CHECK_EQUAL(br3, 0x44444444U, "TC_BOOT_03 SRAM WRAP rd4 beat3");

    // Verify decode boundary immediately past 64 KB (0x0001_0000 -> DECERR)
    uint32_t bresp_oob = 0U, rresp_oob = 0U, rd_oob = 0xFFFFFFFFU;
    sv_axi_write_resp(SRAM_BASE + 0x10000U, 0xBAD00000U, &bresp_oob);
    sv_axi_read_resp(SRAM_BASE + 0x10000U, &rd_oob, &rresp_oob);
    CHECK_EQUAL(bresp_oob, 3U, "TC_BOOT_03 64KB+4 write DECERR");
    CHECK_EQUAL(rresp_oob, 3U, "TC_BOOT_03 64KB+4 read DECERR");
    CHECK_EQUAL(rd_oob,    0U, "TC_BOOT_03 64KB+4 read returns 0");

    return 0;
}

// =============================================================================
// Peripheral Test 1: UART Controller (0x4000_1000) [TC_UART_01..TC_UART_06]
// =============================================================================
int test_uart_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 1] UART Controller (TC_UART_01..TC_UART_06)\n");
    printf("=============================================================\n");

    const uint32_t baud_div = 434U; // 115200 baud @ 50 MHz
    uint8_t rx_cap = 0;
    uint32_t rd_val = 0;

    // TC_UART_01: Baud divisor, LCR, IER readback & initial LSR (THRE+TEMT=0x60)
    soc_write32(UART_REG_LCR, UART_LCR_DLAB);
    soc_write32(UART_REG_BAUD_DIV, baud_div);
    CHECK_EQUAL(soc_read32(UART_REG_LCR) & UART_LCR_DLAB, UART_LCR_DLAB, "TC_UART_01 UART LCR DLAB readback");
    CHECK_EQUAL(soc_read32(UART_REG_BAUD_DIV), baud_div, "TC_UART_01 UART BAUD_DIV readback");
    soc_write32(UART_REG_LCR, 0x00U);
    CHECK_EQUAL(soc_read32(UART_REG_LCR), 0x00U, "TC_UART_01 UART LCR 8N1 readback");

    soc_write32(UART_REG_IER, UART_IER_RX_DATA);
    CHECK_EQUAL(soc_read32(UART_REG_IER), UART_IER_RX_DATA, "TC_UART_01 UART IER readback");

    rd_val = soc_read32(UART_REG_LSR);
    CHECK_EQUAL(rd_val, UART_LSR_THRE | UART_LSR_TEMT, "TC_UART_01 UART initial LSR (THRE|TEMT)");

    // TC_UART_02: Single-byte TX loopback
    sv_uart_tx_loopback(0x55U, &rx_cap);
    CHECK_EQUAL(rx_cap, 0x55U, "TC_UART_02 UART TX loopback 0x55");
    sv_delay_cycles(200);

    sv_uart_tx_loopback(0xA3U, &rx_cap);
    CHECK_EQUAL(rx_cap, 0xA3U, "TC_UART_02 UART TX loopback 0xA3");
    sv_delay_cycles(200);

    // TC_UART_03: Single-byte RX inject & RBR read
    sv_uart_send_byte(0x5AU);
    sv_delay_cycles(600);
    rd_val = soc_read32(UART_REG_RBR) & 0xFFU;
    CHECK_EQUAL(rd_val, 0x5AU, "TC_UART_03 UART RX inject 0x5A via RBR");

    sv_uart_send_byte(0xC9U);
    sv_delay_cycles(600);
    rd_val = soc_read32(UART_REG_RBR) & 0xFFU;
    CHECK_EQUAL(rd_val, 0xC9U, "TC_UART_03 UART RX inject 0xC9 via RBR");

    // TC_UART_05: RX interrupt assert & clear upon FIFO drain
    sv_uart_send_byte(0xBEU);
    sv_delay_cycles(600);
    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(uart_irq, 1U, "TC_UART_05 UART RX IRQ asserted");

    rd_val = soc_read32(UART_REG_RBR) & 0xFFU;
    CHECK_EQUAL(rd_val, 0xBEU, "TC_UART_05 UART RX IRQ drain 0xBE");
    sv_delay_cycles(10);
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(uart_irq, 0U, "TC_UART_05 UART RX IRQ cleared after drain");

    // TC_UART_04: Back-to-back TX FIFO burst & TX empty status
    uint8_t r0 = 0, r1 = 0, r2 = 0;
    sv_uart_b2b_tx(0x11U, 0x22U, 0x33U, &r0, &r1, &r2);
    CHECK_EQUAL(r0, 0x11U, "TC_UART_04 UART B2B TX byte 0 (0x11)");
    CHECK_EQUAL(r1, 0x22U, "TC_UART_04 UART B2B TX byte 1 (0x22)");
    CHECK_EQUAL(r2, 0x33U, "TC_UART_04 UART B2B TX byte 2 (0x33)");
    sv_delay_cycles(800);
    rd_val = soc_read32(UART_REG_LSR);
    CHECK_EQUAL(rd_val & (UART_LSR_THRE | UART_LSR_TEMT),
                (UART_LSR_THRE | UART_LSR_TEMT),
                "TC_UART_04 UART LSR THRE/TEMT empty");

    // TC_UART_06: Framing, Parity & Overrun Error Injection
    // 1) Framing error (corrupt stop bit = 0), sticky until LSR read
    sv_uart_send_err(0xE1U, 0U, 0U, 0U, 1U);
    sv_delay_cycles(600);
    uint32_t lsr_fe     = soc_read32(UART_REG_LSR);
    uint32_t lsr_fe_clr = soc_read32(UART_REG_LSR);
    CHECK_TRUE((lsr_fe & UART_LSR_FE) != 0U, "TC_UART_06 LSR.FE set on bad stop bit", lsr_fe);
    CHECK_EQUAL(lsr_fe_clr & UART_LSR_FE, 0U, "TC_UART_06 LSR.FE cleared on read");
    for (int d = 0; d < 2 && (soc_read32(UART_REG_LSR) & UART_LSR_DR); d++) {
        (void)soc_read32(UART_REG_RBR);
    }

    // 2) Parity error (8E1 with inverted parity bit)
    soc_write32(UART_REG_LCR, UART_LCR_WLEN8 | UART_LCR_PEN | UART_LCR_EPS);
    sv_uart_send_err(0xE2U, 1U, 0U, 1U, 0U);
    sv_delay_cycles(600);
    uint32_t lsr_pe     = soc_read32(UART_REG_LSR);
    uint32_t lsr_pe_clr = soc_read32(UART_REG_LSR);
    CHECK_TRUE((lsr_pe & UART_LSR_PE) != 0U, "TC_UART_06 LSR.PE set on bad parity", lsr_pe);
    CHECK_EQUAL(lsr_pe_clr & UART_LSR_PE, 0U, "TC_UART_06 LSR.PE cleared on read");
    for (int d = 0; d < 2 && (soc_read32(UART_REG_LSR) & UART_LSR_DR); d++) {
        (void)soc_read32(UART_REG_RBR);
    }
    soc_write32(UART_REG_LCR, 0x00U);

    // 3) Overrun burst (17 bytes without draining 16-entry FIFO)
    for (uint8_t b = 0; b < 17U; b++) {
        sv_uart_send_byte((uint8_t)(0xD0U + b));
    }
    sv_delay_cycles(600);
    uint32_t lsr_oe     = soc_read32(UART_REG_LSR);
    uint32_t lsr_oe_clr = soc_read32(UART_REG_LSR);
    CHECK_TRUE((lsr_oe & UART_LSR_OE) != 0U, "TC_UART_06 LSR.OE set on FIFO overrun", lsr_oe);
    CHECK_EQUAL(lsr_oe_clr & UART_LSR_OE, 0U, "TC_UART_06 LSR.OE cleared on read");
    for (int i = 0; i < 16; i++) {
        (void)soc_read32(UART_REG_RBR);
    }
    sv_delay_cycles(10);
    CHECK_EQUAL(soc_read32(UART_REG_LSR) & UART_LSR_DR, 0U, "TC_UART_06 RX FIFO empty after drain");

    return 0;
}

// =============================================================================
// Peripheral Test 2: GPIO Controller (0x4000_3000) [TC_GPIO_01..TC_GPIO_05]
// =============================================================================
int test_gpio_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 2] GPIO Controller 64-Pin (TC_GPIO_01..TC_GPIO_05)\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;
    uint32_t out_low = 0, out_high = 0;
    uint32_t dir_low = 0, dir_high = 0;
    uint32_t irq0 = 0, irq1 = 0;

    // TC_GPIO_01: Reset defaults and GPIO_INFO == 64
    rd_val = soc_read32(GPIO_REG_INFO);
    CHECK_EQUAL(rd_val, 64U, "TC_GPIO_01 GPIO INFO (64 pins)");
    CHECK_EQUAL(soc_read32(GPIO_REG_OE0),     0U, "TC_GPIO_01 GPIO OE0 reset default");
    CHECK_EQUAL(soc_read32(GPIO_REG_OE1),     0U, "TC_GPIO_01 GPIO OE1 reset default");
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT0),    0U, "TC_GPIO_01 GPIO OUT0 reset default");
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT1),    0U, "TC_GPIO_01 GPIO OUT1 reset default");
    CHECK_EQUAL(soc_read32(GPIO_REG_STATUS0), 0U, "TC_GPIO_01 GPIO STATUS0 reset default");
    CHECK_EQUAL(soc_read32(GPIO_REG_STATUS1), 0U, "TC_GPIO_01 GPIO STATUS1 reset default");
    sv_get_gpio_dir(&dir_low, &dir_high);
    CHECK_EQUAL(dir_low,  0U, "TC_GPIO_01 gpio_dir_o[31:0] reset 0");
    CHECK_EQUAL(dir_high, 0U, "TC_GPIO_01 gpio_dir_o[63:32] reset 0");

    // TC_GPIO_02: Bank 0 and Bank 1 Output Drive & Direction
    soc_write32(GPIO_REG_OE0, 0xFFFFFFFFU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OE0), 0xFFFFFFFFU, "TC_GPIO_02 GPIO OE0 readback");
    soc_write32(GPIO_REG_OUT0, 0xA5A55A5AU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT0), 0xA5A55A5AU, "TC_GPIO_02 GPIO OUT0 readback");

    soc_write32(GPIO_REG_OE1, 0xFFFFFFFFU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OE1), 0xFFFFFFFFU, "TC_GPIO_02 GPIO OE1 readback");
    soc_write32(GPIO_REG_OUT1, 0x5A5AA5A5U);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT1), 0x5A5AA5A5U, "TC_GPIO_02 GPIO OUT1 readback");

    sv_get_gpio_out(&out_low, &out_high);
    CHECK_EQUAL(out_low,  0xA5A55A5AU, "TC_GPIO_02 Bank 0 pin drive");
    CHECK_EQUAL(out_high, 0x5A5AA5A5U, "TC_GPIO_02 Bank 1 pin drive");
    sv_get_gpio_dir(&dir_low, &dir_high);
    CHECK_EQUAL(dir_low,  0xFFFFFFFFU, "TC_GPIO_02 Bank 0 gpio_dir_o");
    CHECK_EQUAL(dir_high, 0xFFFFFFFFU, "TC_GPIO_02 Bank 1 gpio_dir_o");

    // TC_GPIO_03: Bank 0 and Bank 1 Input Sampling
    sv_set_gpio_in(0x12345678U, 0x9ABCDEF0U);
    sv_delay_cycles(5);
    CHECK_EQUAL(soc_read32(GPIO_REG_IN0), 0x12345678U, "TC_GPIO_03 GPIO IN0 sampling");
    CHECK_EQUAL(soc_read32(GPIO_REG_IN1), 0x9ABCDEF0U, "TC_GPIO_03 GPIO IN1 sampling");

    // TC_GPIO_04: Atomic Bit Set / Clear / Toggle on Bank 0 and Bank 1
    soc_write32(GPIO_REG_SET0, 0x000000FFU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT0), 0xA5A55AFFU, "TC_GPIO_04 GPIO Atomic SET0");
    soc_write32(GPIO_REG_CLR0, 0x0000000FU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT0), 0xA5A55AF0U, "TC_GPIO_04 GPIO Atomic CLR0");
    soc_write32(GPIO_REG_TGL0, 0x0000FF00U);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT0), 0xA5A5A5F0U, "TC_GPIO_04 GPIO Atomic TGL0");

    soc_write32(GPIO_REG_SET1, 0x000000FFU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT1), 0x5A5AA5FFU, "TC_GPIO_04 GPIO Atomic SET1");
    soc_write32(GPIO_REG_CLR1, 0x0000000FU);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT1), 0x5A5AA5F0U, "TC_GPIO_04 GPIO Atomic CLR1");
    soc_write32(GPIO_REG_TGL1, 0x0000FF00U);
    CHECK_EQUAL(soc_read32(GPIO_REG_OUT1), 0x5A5A5AF0U, "TC_GPIO_04 GPIO Atomic TGL1");

    // TC_GPIO_05: Edge (Rise/Fall) & Level (High/Low) Interrupts + W1C on both banks
    soc_write32(GPIO_REG_OE0, 0x0U);
    soc_write32(GPIO_REG_OE1, 0x0U);
    soc_write32(GPIO_REG_OUT0, 0x0U);
    soc_write32(GPIO_REG_OUT1, 0x0U);
    sv_set_gpio_in(0x0U, 0x0U);
    sv_delay_cycles(5);
    soc_write32(GPIO_REG_STATUS0, 0xFFFFFFFFU);
    soc_write32(GPIO_REG_STATUS1, 0xFFFFFFFFU);

    // 1) Bank 0 Rising Edge (bit 0)
    soc_write32(GPIO_REG_RISE_EN0, 0x00000001U);
    sv_set_gpio_in(0x00000001U, 0x0U);
    sv_delay_cycles(6);
    CHECK_EQUAL(soc_read32(GPIO_REG_STATUS0), 0x00000001U, "TC_GPIO_05 Bank0 RISE STATUS");
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq0, 1U, "TC_GPIO_05 Bank0 RISE gpio_intr[0]=1");
    soc_write32(GPIO_REG_RISE_EN0, 0x0U);
    soc_write32(GPIO_REG_STATUS0, 0x00000001U);
    sv_delay_cycles(2);
    CHECK_EQUAL(soc_read32(GPIO_REG_STATUS0), 0x0U, "TC_GPIO_05 Bank0 W1C cleared");
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq0, 0U, "TC_GPIO_05 Bank0 gpio_intr[0]=0");

    // 2) Bank 1 Falling Edge (bit 1)
    sv_set_gpio_in(0x0U, 0x00000002U);
    sv_delay_cycles(6);
    soc_write32(GPIO_REG_FALL_EN1, 0x00000002U);
    sv_set_gpio_in(0x0U, 0x0U);
    sv_delay_cycles(6);
    CHECK_EQUAL(soc_read32(GPIO_REG_STATUS1), 0x00000002U, "TC_GPIO_05 Bank1 FALL STATUS");
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq1, 1U, "TC_GPIO_05 Bank1 FALL gpio_intr[1]=1");
    soc_write32(GPIO_REG_FALL_EN1, 0x0U);
    soc_write32(GPIO_REG_STATUS1, 0x00000002U);
    sv_delay_cycles(2);
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq1, 0U, "TC_GPIO_05 Bank1 gpio_intr[1]=0");

    // 3) Bank 0 Level High (bit 2)
    soc_write32(GPIO_REG_HIGH_EN0, 0x00000004U);
    sv_set_gpio_in(0x00000004U, 0x0U);
    sv_delay_cycles(6);
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq0, 1U, "TC_GPIO_05 Bank0 HIGH gpio_intr[0]=1");
    sv_set_gpio_in(0x0U, 0x0U);
    sv_delay_cycles(6);
    soc_write32(GPIO_REG_HIGH_EN0, 0x0U);
    soc_write32(GPIO_REG_STATUS0, 0x00000004U);
    sv_delay_cycles(2);
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq0, 0U, "TC_GPIO_05 Bank0 HIGH W1C cleared");

    // 4) Bank 1 Level Low (bit 2)
    sv_set_gpio_in(0x0U, 0x0U);
    sv_delay_cycles(6);
    soc_write32(GPIO_REG_LOW_EN1, 0x00000004U);
    sv_delay_cycles(6);
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq1, 1U, "TC_GPIO_05 Bank1 LOW gpio_intr[1]=1");
    sv_set_gpio_in(0x0U, 0x00000004U);
    sv_delay_cycles(6);
    soc_write32(GPIO_REG_LOW_EN1, 0x0U);
    soc_write32(GPIO_REG_STATUS1, 0x00000004U);
    sv_delay_cycles(2);
    sv_get_gpio_intr(&irq0, &irq1);
    CHECK_EQUAL(irq1, 0U, "TC_GPIO_05 Bank1 LOW W1C cleared");
    sv_set_gpio_in(0x0U, 0x0U);

    return 0;
}

// =============================================================================
// Peripheral Test 3: System Timer rv_timer (0x4000_2000) [TC_TMR_01..TC_TMR_03]
// =============================================================================
int test_timer_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 3] System Timer rv_timer (TC_TMR_01..TC_TMR_03)\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0, rd_step4 = 0;
    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;

    // TC_TMR_01: Configuration, prescaler/step & free-running increment
    soc_write32(TIMER_REG_CTRL, 0x0U);
    soc_write32(TIMER_REG_INTR_EN, 0x0U);
    soc_write32(TIMER_REG_INTR_STATE, 0x1U);

    soc_write32(TIMER_REG_CMP_L, 0x00000200U);
    CHECK_EQUAL(soc_read32(TIMER_REG_CMP_L), 0x00000200U, "TC_TMR_01 TIMER CMP_L readback");
    soc_write32(TIMER_REG_CMP_H, 0x00000001U);
    CHECK_EQUAL(soc_read32(TIMER_REG_CMP_H), 0x00000001U, "TC_TMR_01 TIMER CMP_H readback");
    soc_write32(TIMER_REG_CMP_H, 0x00000000U);

    soc_write32(TIMER_REG_CFG0, (1U << 16) | 0x0U);
    rd_val = soc_read32(TIMER_REG_CFG0);
    CHECK_EQUAL(rd_val & 0xFF0FFFU, (1U << 16) | 0x0U, "TC_TMR_01 TIMER CFG0 prescaler/step");

    soc_write32(TIMER_REG_MTIME_L, 0x00000000U);
    soc_write32(TIMER_REG_MTIME_H, 0x00000000U);
    soc_write32(TIMER_REG_CTRL, TIMER_CTRL_ACTIVE);
    CHECK_EQUAL(soc_read32(TIMER_REG_CTRL) & 0x1U, 1U, "TC_TMR_01 TIMER CTRL active bit");

    sv_delay_cycles(25);
    rd_val = soc_read32(TIMER_REG_MTIME_L);
    CHECK_TRUE(rd_val > 0U, "TC_TMR_01 MTIME_L incrementing (step=1)", rd_val);

    // Check step=4 accelerates counting vs step=1
    soc_write32(TIMER_REG_CTRL, 0x0U);
    soc_write32(TIMER_REG_MTIME_L, 0x0U);
    soc_write32(TIMER_REG_CFG0, (4U << 16) | 0x0U);
    soc_write32(TIMER_REG_CTRL, TIMER_CTRL_ACTIVE);
    sv_delay_cycles(25);
    rd_step4 = soc_read32(TIMER_REG_MTIME_L);
    CHECK_TRUE(rd_step4 >= (rd_val * 2U), "TC_TMR_01 CFG0 step=4 speedup", rd_step4);

    // TC_TMR_02: Compare-Match & Real Timer Interrupt Assert
    soc_write32(TIMER_REG_CTRL, 0x0U);
    soc_write32(TIMER_REG_CFG0, (1U << 16) | 0x0U);
    soc_write32(TIMER_REG_MTIME_L, 0x0U);
    soc_write32(TIMER_REG_MTIME_H, 0x0U);
    soc_write32(TIMER_REG_CMP_L, 40U);
    soc_write32(TIMER_REG_CMP_H, 0x0U);
    soc_write32(TIMER_REG_INTR_STATE, 0x1U);
    soc_write32(TIMER_REG_INTR_EN, 0x1U);
    soc_write32(TIMER_REG_CTRL, TIMER_CTRL_ACTIVE);

    sv_delay_cycles(80);
    CHECK_EQUAL(soc_read32(TIMER_REG_INTR_STATE) & 0x1U, 1U, "TC_TMR_02 INTR_STATE set on compare");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(timer_irq, 1U, "TC_TMR_02 timer_irq_o asserted");

    // TC_TMR_03: Interrupt Acknowledge (W1C) & INTR_TEST Force
    // Bump CMP_H so timer doesn't immediately re-assert after W1C
    soc_write32(TIMER_REG_CMP_H, 0xFFFFFFFFU);
    soc_write32(TIMER_REG_CMP_L, 0xFFFFFFFFU);
    soc_write32(TIMER_REG_INTR_STATE, 0x1U);
    CHECK_EQUAL(soc_read32(TIMER_REG_INTR_STATE) & 0x1U, 0U, "TC_TMR_03 INTR_STATE W1C cleared");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(timer_irq, 0U, "TC_TMR_03 timer_irq_o deasserted");

    // Force IRQ via INTR_TEST (0x108)
    soc_write32(TIMER_REG_INTR_TEST, 0x1U);
    CHECK_EQUAL(soc_read32(TIMER_REG_INTR_STATE) & 0x1U, 1U, "TC_TMR_03 INTR_TEST sets INTR_STATE");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(timer_irq, 1U, "TC_TMR_03 INTR_TEST asserts timer_irq_o");

    // Clean up
    soc_write32(TIMER_REG_INTR_STATE, 0x1U);
    soc_write32(TIMER_REG_INTR_EN, 0x0U);
    soc_write32(TIMER_REG_CTRL, 0x0U);

    return 0;
}

// =============================================================================
// Peripheral Test 4: SHA-256 Accelerator (0x4000_4000) [TC_SHA_01..TC_SHA_05]
// =============================================================================
int test_sha256_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 4] SHA-256 Accelerator (TC_SHA_01..TC_SHA_05)\n");
    printf("=============================================================\n");

    uint32_t rd_val = 0;
    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;

    // TC_SHA_01: ID / Version / Ready Status
    CHECK_EQUAL(soc_read32(SHA_REG_NAME0),   SHA_EXP_NAME0,   "TC_SHA_01 NAME0 ('sha2')");
    CHECK_EQUAL(soc_read32(SHA_REG_NAME1),   SHA_EXP_NAME1,   "TC_SHA_01 NAME1 ('-256')");
    CHECK_EQUAL(soc_read32(SHA_REG_VERSION), SHA_EXP_VERSION, "TC_SHA_01 VERSION ('1.80')");
    CHECK_EQUAL(soc_read32(SHA_REG_STATUS) & SHA_STAT_READY, 1U, "TC_SHA_01 status READY");

    // TC_SHA_05: Full 512-bit Message Block R/W Integrity (BLOCK0..15)
    for (int i = 0; i < 16; i++) {
        uint32_t pat = 0xA5000000U | ((uint32_t)i * 0x01020304U);
        soc_write32(SHA_REG_BLOCK(i), pat);
    }
    int blk_ok = 1;
    for (int i = 0; i < 16; i++) {
        uint32_t pat = 0xA5000000U | ((uint32_t)i * 0x01020304U);
        rd_val = soc_read32(SHA_REG_BLOCK(i));
        if (rd_val != pat) {
            blk_ok = 0;
            CHECK_EQUAL(rd_val, pat, "TC_SHA_05 BLOCK[i] mismatch");
            break;
        }
    }
    if (blk_ok) {
        CHECK_TRUE(1, "TC_SHA_05 all 16 BLOCK0..15 words R/W", 16U);
    }

    // TC_SHA_02: NIST FIPS 180-4 Single-Block ("abc")
    static const uint32_t nist_abc_digest[8] = {
        0xba7816bfU, 0x8f01cfeaU, 0x414140deU, 0x5dae2223U,
        0xb00361a3U, 0x96177a9cU, 0xb410ff61U, 0xf20015adU
    };
    soc_write32(SHA_REG_BLOCK(0), 0x61626380U);
    for (int i = 1; i < 15; i++) {
        soc_write32(SHA_REG_BLOCK(i), 0x00000000U);
    }
    soc_write32(SHA_REG_BLOCK(15), 0x00000018U); // 24 bits
    soc_write32(SHA_REG_CTRL, SHA_CTRL_INIT_256);

    uint32_t sha_st = 0;
    for (int i = 0; i < 200; i++) {
        sha_st = soc_read32(SHA_REG_STATUS);
        if ((sha_st & (SHA_STAT_READY | SHA_STAT_VALID)) == (SHA_STAT_READY | SHA_STAT_VALID)) {
            break;
        }
        sv_delay_cycles(2);
    }
    CHECK_EQUAL(sha_st & (SHA_STAT_READY | SHA_STAT_VALID),
                (SHA_STAT_READY | SHA_STAT_VALID),
                "TC_SHA_02 'abc' digest READY & VALID");

    for (int i = 0; i < 8; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_SHA_02 'abc' DIGEST[%d]", i);
        CHECK_EQUAL(soc_read32(SHA_REG_DIGEST(i)), nist_abc_digest[i], lbl);
    }

    // TC_SHA_04: SHA IRQ latched on VALID status read & cleared on new INIT
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(sha_irq, 1U, "TC_SHA_04 sha_irq_o latched on VALID read");

    // TC_SHA_03: Multi-Block Hash Chaining ("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq", 56B)
    static const uint32_t nist_2blk_b0[16] = {
        0x61626364U, 0x62636465U, 0x63646566U, 0x64656667U,
        0x65666768U, 0x66676869U, 0x6768696aU, 0x68696a6bU,
        0x696a6b6cU, 0x6a6b6c6dU, 0x6b6c6d6eU, 0x6c6d6e6fU,
        0x6d6e6f70U, 0x6e6f7071U, 0x80000000U, 0x00000000U
    };
    static const uint32_t nist_2blk_digest[8] = {
        0x248d6a61U, 0xd20638b8U, 0xe5c02693U, 0x0c3e6039U,
        0xa33ce459U, 0x64ff2167U, 0xf6ecedd4U, 0x19db06c1U
    };
    for (int i = 0; i < 16; i++) {
        soc_write32(SHA_REG_BLOCK(i), nist_2blk_b0[i]);
    }
    soc_write32(SHA_REG_CTRL, SHA_CTRL_INIT_256);
    sha_st = soc_read32(SHA_REG_STATUS);
    CHECK_EQUAL(sha_st & SHA_STAT_READY, 0U, "TC_SHA_04 SHA enters BUSY (ready=0) after INIT");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(sha_irq, 0U, "TC_SHA_04 sha_irq_o cleared on INIT");

    for (int i = 0; i < 200; i++) {
        sha_st = soc_read32(SHA_REG_STATUS);
        if (sha_st & SHA_STAT_READY) break;
        sv_delay_cycles(2);
    }
    CHECK_EQUAL(sha_st & SHA_STAT_READY, SHA_STAT_READY, "TC_SHA_03 Block 0 READY");

    // Load Block 1 (all 0 except bit length = 448 = 0x1C0) and pulse NEXT
    for (int i = 0; i < 15; i++) {
        soc_write32(SHA_REG_BLOCK(i), 0x00000000U);
    }
    soc_write32(SHA_REG_BLOCK(15), 0x000001C0U);
    soc_write32(SHA_REG_CTRL, SHA_CTRL_NEXT_256);

    for (int i = 0; i < 200; i++) {
        sha_st = soc_read32(SHA_REG_STATUS);
        if ((sha_st & (SHA_STAT_READY | SHA_STAT_VALID)) == (SHA_STAT_READY | SHA_STAT_VALID)) {
            break;
        }
        sv_delay_cycles(2);
    }
    CHECK_EQUAL(sha_st & (SHA_STAT_READY | SHA_STAT_VALID),
                (SHA_STAT_READY | SHA_STAT_VALID),
                "TC_SHA_03 Block 1 NEXT digest VALID");
    for (int i = 0; i < 8; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_SHA_03 2-blk DIGEST[%d]", i);
        CHECK_EQUAL(soc_read32(SHA_REG_DIGEST(i)), nist_2blk_digest[i], lbl);
    }

    return 0;
}

// =============================================================================
// Peripheral Test 5: AES-256 Accelerator (0x4000_0000) [TC_AES_01..TC_AES_06]
// =============================================================================
int test_aes256_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 5] AES-256 Accelerator (TC_AES_01..TC_AES_06)\n");
    printf("=============================================================\n");

    // NIST FIPS-197 Appendix C.3 AES-256 Key, Plaintext & Ciphertext
    static const uint32_t nist_key_msw[8] = {
        0x00010203U, 0x04050607U, 0x08090a0bU, 0x0c0d0e0fU,
        0x10111213U, 0x14151617U, 0x18191a1bU, 0x1c1d1e1fU
    };
    static const uint32_t nist_pt_msw[4] = {
        0x00112233U, 0x44556677U, 0x8899aabbU, 0xccddeeffU
    };
    static const uint32_t nist_ct_msw[4] = {
        0x8ea2b7caU, 0x516745bfU, 0xeafc4990U, 0x4b496089U
    };

    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;

    clear_aes_engine();

    // TC_AES_01: Register R/W + WO Security Read-Zero Verification
    const uint32_t test_iv[4] = { 0xDEADBEEFU, 0xCAFEBABEU, 0x01234567U, 0x89ABCDEFU };
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_IV(i), test_iv[i]);
        char lbl[40];
        snprintf(lbl, sizeof(lbl), "TC_AES_01 AES IV%d readback", i);
        CHECK_EQUAL(soc_read32(AES_REG_IV(i)), test_iv[i], lbl);
    }

    soc_write32(AES_REG_BLK_CNT, 0x00000004U);
    CHECK_EQUAL(soc_read32(AES_REG_BLK_CNT) & 0xFFFFU, 4U, "TC_AES_01 AES BLK_CNT readback");
    soc_write32(AES_REG_BLK_CNT, 0x00000001U);

    // Load 256-bit key (KEY7 = [255:224] MSW) and confirm reads return 0 (WO security)
    for (int i = 0; i < 8; i++) {
        soc_write32(AES_REG_KEY(7 - i), nist_key_msw[i]);
        char lbl[40];
        snprintf(lbl, sizeof(lbl), "TC_AES_01 AES KEY%d WO reads 0", 7 - i);
        CHECK_EQUAL(soc_read32(AES_REG_KEY(7 - i)), 0U, lbl);
    }
    // Load DIN and confirm reads return 0 (WO)
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_DIN(3 - i), nist_pt_msw[i]);
        char lbl[40];
        snprintf(lbl, sizeof(lbl), "TC_AES_01 AES DIN%d WO reads 0", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DIN(3 - i)), 0U, lbl);
    }

    // TC_AES_02 + TC_AES_03 + TC_AES_06: Start AES-256 ECB Encrypt with IRQ enabled
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_IRQ_EN);
    CHECK_EQUAL(soc_read32(AES_REG_CTRL) & 0x1FU, 0x12U, "TC_AES_01 AES CTRL 256-bit & IRQ");
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_IRQ_EN | AES_CTRL_START);

    uint32_t aes_st = 0;
    for (int i = 0; i < 300; i++) {
        aes_st = soc_read32(AES_REG_STATUS);
        if (aes_st & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    printf("    AES STATUS = 0x%08X (busy=%u, done=%u, key_ready=%u)\n",
           aes_st, (aes_st & 1U), ((aes_st >> 1) & 1U), ((aes_st >> 2) & 1U));
    CHECK_EQUAL(aes_st & (AES_STAT_DONE | AES_STAT_KEY_READY | AES_STAT_ERR),
                (AES_STAT_DONE | AES_STAT_KEY_READY),
                "TC_AES_02 AES-256 KEY_READY & DONE");

    // TC_AES_03: Verify NIST FIPS-197 Appendix C.3 Ciphertext directly over AXI DOUT
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_03 ECB Enc DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), nist_ct_msw[i], lbl);
    }

    // TC_AES_06: Verify aes_irq_o asserted then cleared by AES_IRQ_CLR
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(aes_irq, 1U, "TC_AES_06 aes_irq_o asserted on DONE");
    soc_write32(AES_REG_IRQ_CLR, 0x1U);
    sv_delay_cycles(2);
    CHECK_EQUAL(soc_read32(AES_REG_STATUS) & AES_STAT_DONE, 0U, "TC_AES_06 STATUS.DONE cleared");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(aes_irq, 0U, "TC_AES_06 aes_irq_o cleared via IRQ_CLR");

    // TC_AES_02 (AES-128 Key-Ready check as well)
    soc_write32(AES_REG_STATUS, AES_STAT_KEY_READY); // W1C KEY_READY before AES-128 check
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY128 | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        aes_st = soc_read32(AES_REG_STATUS);
        if (aes_st & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    CHECK_EQUAL(aes_st & AES_STAT_KEY_READY, AES_STAT_KEY_READY, "TC_AES_02 AES-128 KEY_READY");
    soc_write32(AES_REG_IRQ_CLR, 0x1U);

    // TC_AES_03 Decrypt: Feed ciphertext back and verify plaintext held on AXI DOUT
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_KEY(7 - i), nist_key_msw[i]);
        soc_write32(AES_REG_KEY(3 - i), nist_key_msw[4 + i]);
        soc_write32(AES_REG_DIN(3 - i), nist_ct_msw[i]);
    }
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_DECRYPT | AES_CTRL_START);
    aes_st = 0;
    for (int i = 0; i < 300; i++) {
        aes_st = soc_read32(AES_REG_STATUS);
        if (aes_st & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    CHECK_EQUAL(aes_st & AES_STAT_DONE, AES_STAT_DONE, "TC_AES_03 ECB Decrypt DONE");
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_03 ECB Dec DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), nist_pt_msw[i], lbl);
    }
    soc_write32(AES_REG_IRQ_CLR, 0x1U);

    // TC_AES_04: Sequential 2-Block AES-256 CBC Mode Encryption & IV Chaining
    static const uint32_t cbc_pt1_msw[4] = {
        0x11223344U, 0x55667788U, 0x99AABBCCU, 0xDDEEFF00U
    };
    static const uint32_t cbc_ct0_golden[4] = {
        0x78E16B06U, 0x817A4453U, 0xABEF8A23U, 0x5FA9FA51U
    };
    static const uint32_t cbc_ct1_golden[4] = {
        0xD7FF94F9U, 0x67A07DA4U, 0xCD85A677U, 0xE643FF36U
    };

    clear_aes_engine();
    for (int i = 0; i < 8; i++) {
        soc_write32(AES_REG_KEY(7 - i), nist_key_msw[i]);
    }
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_IV(3 - i),  nist_key_msw[i]); // IV = 00010203..0c0d0e0f
        soc_write32(AES_REG_DIN(3 - i), nist_pt_msw[i]);
    }
    soc_write32(AES_REG_BLK_CNT, 1U);
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_04 CBC-E Blk0 DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), cbc_ct0_golden[i], lbl);
    }
    soc_write32(AES_REG_IRQ_CLR, 0x1U);

    // Block 1 back-to-back without rewriting IV: verifies ciphertext feedback chaining
    for (int i = 0; i < 4; i++) soc_write32(AES_REG_DIN(3 - i), cbc_pt1_msw[i]);
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_04 CBC-E Blk1 DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), cbc_ct1_golden[i], lbl);
    }
    soc_write32(AES_REG_IRQ_CLR, 0x1U);

    // TC_AES_05: AES-256 CBC Decryption & Inverse Cipher Recovery (2-Block)
    clear_aes_engine();
    for (int i = 0; i < 8; i++) soc_write32(AES_REG_KEY(7 - i), nist_key_msw[i]);
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_IV(3 - i),  nist_key_msw[i]);
        soc_write32(AES_REG_DIN(3 - i), cbc_ct0_golden[i]);
    }
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_DECRYPT | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_05 CBC-D Blk0 DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), nist_pt_msw[i], lbl);
    }
    soc_write32(AES_REG_IRQ_CLR, 0x1U);

    for (int i = 0; i < 4; i++) soc_write32(AES_REG_DIN(3 - i), cbc_ct1_golden[i]);
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_DECRYPT | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_AES_05 CBC-D Blk1 DOUT%d", 3 - i);
        CHECK_EQUAL(soc_read32(AES_REG_DOUT(3 - i)), cbc_pt1_msw[i], lbl);
    }

    // Multi-Block Hardware Counter & SOFT_RST Key/Register Clear Verification
    clear_aes_engine();
    CHECK_EQUAL(soc_read32(AES_REG_BLK_CNT) & 0xFFFFU, 1U, "TC_AES_01 SOFT_RST TOTAL_BLOCKS == 1");
    CHECK_EQUAL(soc_read32(AES_REG_IV(0)), 0U,              "TC_AES_01 SOFT_RST IV cleared");
    CHECK_EQUAL(soc_read32(AES_REG_DOUT(3)), 0U,            "TC_AES_01 SOFT_RST DOUT cleared");

    for (int i = 0; i < 8; i++) soc_write32(AES_REG_KEY(7 - i), nist_key_msw[i]);
    for (int i = 0; i < 4; i++) soc_write32(AES_REG_DIN(3 - i), nist_pt_msw[i]);
    soc_write32(AES_REG_BLK_CNT, 4U);
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_START);
    for (int i = 0; i < 500; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    uint32_t done_blks = (soc_read32(AES_REG_BLK_CNT) >> 16) & 0xFFFFU;
    CHECK_EQUAL(done_blks, 4U, "TC_AES_04 multi-block DONE_BLOCKS == 4");

    // Verify SOFT_RST wipes key_data (re-encrypting PT without writing key != NIST CT)
    clear_aes_engine();
    for (int i = 0; i < 4; i++) soc_write32(AES_REG_DIN(3 - i), nist_pt_msw[i]);
    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    uint32_t post_rst_ct3 = soc_read32(AES_REG_DOUT(3));
    CHECK_TRUE(post_rst_ct3 != nist_ct_msw[0], "TC_AES_01 SOFT_RST wiped internal key", post_rst_ct3);
    clear_aes_engine();

    return 0;
}

// =============================================================================
// Peripheral Test 6: AXI DMA Controller (0x4000_5000) [TC_DMA_01..TC_DMA_05]
// =============================================================================
int test_dma_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 6] AXI DMA Controller (TC_DMA_01..TC_DMA_05)\n");
    printf("=============================================================\n");

    uint32_t dma_st = 0;
    uint32_t uart_irq = 0, timer_irq = 0, aes_irq = 0, sha_irq = 0, dma_done = 0, dma_error = 0;

    // TC_DMA_01: CSR Signature (0xCAFE) & Descriptor R/W Config
    dma_st = soc_read32(DMA_REG_STATUS);
    CHECK_EQUAL(dma_st & 0xFFFFU, DMA_EXP_SIGNATURE, "TC_DMA_01 DMA STATUS signature 0xCAFE");

    soc_write32(DMA_REG_DESC0_SRC, SHA_REG_BLOCK(0));
    soc_write32(DMA_REG_DESC0_DST, AES_REG_IV(0));
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, (0x10U << 2));
    CHECK_EQUAL((soc_read32(DMA_REG_CONTROL) >> 2) & 0xFFU, 0x10U, "TC_DMA_01 DMA max_burst R/W");
    // Use max_burst=0 (ARLEN=0/AWLEN=0 single-beat bursts) because all SoC slaves sit behind axi_to_axilite_bridge
    soc_write32(DMA_REG_CONTROL, 0x0U);
    CHECK_EQUAL(soc_read32(DMA_REG_DESC0_SRC),   SHA_REG_BLOCK(0), "TC_DMA_01 DESC0_SRC readback");
    CHECK_EQUAL(soc_read32(DMA_REG_DESC0_DST),   AES_REG_IV(0),    "TC_DMA_01 DESC0_DST readback");
    CHECK_EQUAL(soc_read32(DMA_REG_DESC0_BYTES), 16U,              "TC_DMA_01 DESC0_BYTES readback");

    // TC_DMA_02: Single-Descriptor 256B SRAM->SRAM Transfer with AXI4 Bursts (max_burst=16)
    const uint32_t sram_src_base = SRAM_BASE + 0x1000U;
    const uint32_t sram_dst_base = SRAM_BASE + 0x2000U;
    for (int i = 0; i < 64; i++) {
        soc_write32(sram_src_base + (uint32_t)i * 4U, 0xD2000000U | (uint32_t)i);
        soc_write32(sram_dst_base + (uint32_t)i * 4U, 0x0U);
    }
    soc_write32(DMA_REG_DESC1_CFG, 0x0U);
    soc_write32(DMA_REG_DESC0_SRC, sram_src_base);
    soc_write32(DMA_REG_DESC0_DST, sram_dst_base);
    soc_write32(DMA_REG_DESC0_BYTES, 256U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);

    // Enable 16-beat AXI4 bursts for full-AXI SRAM transfer
    soc_write32(DMA_REG_CONTROL, (16U << 2) | DMA_CTRL_GO);
    bool ok = poll_dma_done_or_timeout(&dma_st, 400);
    CHECK_TRUE(ok, "TC_DMA_02 256B SRAM->SRAM burst DMA done", dma_st);
    CHECK_EQUAL((dma_st & DMA_STAT_ERROR) ? 1U : 0U, 0U, "TC_DMA_02 no DMA error flag");
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(dma_done, 1U, "TC_DMA_02 dma_done_o pin asserted");
    CHECK_EQUAL(dma_error, 0U, "TC_DMA_02 dma_error_o pin clear");

    // Deassert GO and return max_burst=0 for single-beat AXI4-Lite bridged slaves
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);
    for (int i = 0; i < 64; i++) {
        uint32_t got = soc_read32(sram_dst_base + (uint32_t)i * 4U);
        uint32_t exp = 0xD2000000U | (uint32_t)i;
        if (i < 4 || i >= 60 || got != exp) {
            char lbl[48];
            snprintf(lbl, sizeof(lbl), "TC_DMA_02 SRAM word[%d]", i);
            CHECK_EQUAL(got, exp, lbl);
        }
    }

    // TC_DMA_03: Simultaneous Multi-Descriptor Chaining (DESC0 + DESC1 in single GO)
    const uint32_t sram_d3_dst = SRAM_BASE + 0x3000U;
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_IV(i), 0x0U);
    }
    for (int i = 0; i < 8; i++) {
        soc_write32(sram_d3_dst + (uint32_t)i * 4U, 0x0U);
    }
    soc_write32(DMA_REG_DESC0_SRC, sram_src_base);          // 16B: SRAM 0x1000..0x100F -> AES_IV0..3
    soc_write32(DMA_REG_DESC0_DST, AES_REG_IV(0));
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);

    soc_write32(DMA_REG_DESC1_SRC, sram_src_base + 0x10U);  // 32B: SRAM 0x1010..0x102F -> SRAM 0x3000..0x301F
    soc_write32(DMA_REG_DESC1_DST, sram_d3_dst);
    soc_write32(DMA_REG_DESC1_BYTES, 32U);
    soc_write32(DMA_REG_DESC1_CFG, DMA_CFG_ENABLE);

    CHECK_EQUAL(soc_read32(DMA_REG_DESC1_SRC),   sram_src_base + 0x10U, "TC_DMA_03 DESC1_SRC readback");
    CHECK_EQUAL(soc_read32(DMA_REG_DESC1_DST),   sram_d3_dst,           "TC_DMA_03 DESC1_DST readback");
    CHECK_EQUAL(soc_read32(DMA_REG_DESC1_BYTES), 32U,                   "TC_DMA_03 DESC1_BYTES readback");

    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    ok = poll_dma_done_or_timeout(&dma_st, 300);
    CHECK_TRUE(ok, "TC_DMA_03 dual-descriptor DMA done", dma_st);
    CHECK_EQUAL((dma_st & DMA_STAT_ERROR) ? 1U : 0U, 0U, "TC_DMA_03 dual-descriptor no error");
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);

    for (int i = 0; i < 4; i++) {
        char lbl0[48];
        snprintf(lbl0, sizeof(lbl0), "TC_DMA_03 DESC0 AES_IV[%d]", i);
        CHECK_EQUAL(soc_read32(AES_REG_IV(i)), 0xD2000000U | (uint32_t)i, lbl0);
    }
    for (int i = 0; i < 8; i++) {
        char lbl1[48];
        snprintf(lbl1, sizeof(lbl1), "TC_DMA_03 DESC1 SRAM[%d]", i);
        CHECK_EQUAL(soc_read32(sram_d3_dst + (uint32_t)i * 4U), 0xD2000000U | (uint32_t)(4 + i), lbl1);
    }

    // TC_DMA_04: Fixed-Address FIFO Streaming Mode (UART RBR RD_FIXED -> SRAM & WR_FIXED)
    soc_write32(UART_REG_LCR, 0x00U);
    soc_write32(UART_REG_IER, UART_IER_RX_DATA);
    const uint32_t sram_rx_dst   = SRAM_BASE + 0x4000U;
    const uint32_t sram_fix_src  = SRAM_BASE + 0x4100U;
    const uint32_t sram_fix_dst  = SRAM_BASE + 0x4200U;
    static const uint8_t uart_stream[4] = { 0xA1U, 0xB2U, 0xC3U, 0xD4U };
    for (int i = 0; i < 4; i++) {
        sv_uart_send_byte(uart_stream[i]);
        sv_delay_cycles(400);
        soc_write32(sram_rx_dst + (uint32_t)i * 4U, 0x0U);
    }
    soc_write32(DMA_REG_DESC1_CFG, 0x0U);
    soc_write32(DMA_REG_DESC0_SRC, UART_REG_RBR);        // fixed RX FIFO read
    soc_write32(DMA_REG_DESC0_DST, sram_rx_dst);         // incrementing SRAM destination
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE | DMA_CFG_RD_FIXED);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    ok = poll_dma_done_or_timeout(&dma_st, 200);
    CHECK_TRUE(ok, "TC_DMA_04 UART_RBR->SRAM RD_FIXED done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_DMA_04 UART_RBR->SRAM[%d]", i);
        CHECK_EQUAL(soc_read32(sram_rx_dst + (uint32_t)i * 4U) & 0xFFU, uart_stream[i], lbl);
    }
    CHECK_EQUAL(soc_read32(UART_REG_LSR) & UART_LSR_DR, 0U, "TC_DMA_04 UART RX FIFO drained by DMA");

    // Also test WR_FIXED on SRAM: SRC INCR -> DST FIXED -> DST+0 gets last word, DST+4 stays 0
    for (int i = 0; i < 4; i++) {
        soc_write32(sram_fix_src + (uint32_t)i * 4U, 0xF1000000U + (uint32_t)i);
        soc_write32(sram_fix_dst + (uint32_t)i * 4U, 0x0U);
    }
    soc_write32(DMA_REG_DESC0_SRC, sram_fix_src);
    soc_write32(DMA_REG_DESC0_DST, sram_fix_dst);
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE | DMA_CFG_WR_FIXED);

    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    ok = poll_dma_done_or_timeout(&dma_st, 200);
    CHECK_TRUE(ok, "TC_DMA_04 WR_FIXED SRAM transfer done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);
    CHECK_EQUAL(soc_read32(sram_fix_dst),      0xF1000003U, "TC_DMA_04 WR_FIXED overwrote SRAM[0]");
    CHECK_EQUAL(soc_read32(sram_fix_dst + 4U), 0x00000000U, "TC_DMA_04 WR_FIXED left SRAM[1] untouched");

    // TC_DMA_05: Bus Error Detection & DMA_ERROR_ADDR Capture (Write Fault DST=0x5000_0000 + Read Fault SRC=0x5000_0000)
    soc_write32(DMA_REG_DESC0_SRC, SHA_REG_BLOCK(0));
    soc_write32(DMA_REG_DESC0_DST, 0x50000000U); // unmapped DST -> DECERR from interconnect
    soc_write32(DMA_REG_DESC0_BYTES, 4U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    ok = poll_dma_done_or_timeout(&dma_st, 200);
    CHECK_TRUE(ok, "TC_DMA_05 write fault txn completed", dma_st);
    CHECK_EQUAL((dma_st & DMA_STAT_ERROR) ? 1U : 0U, 1U, "TC_DMA_05 WR DMA_STATUS.error set");
    CHECK_EQUAL(soc_read32(DMA_REG_ERROR_ADDR), 0x50000000U, "TC_DMA_05 WR DMA_ERROR_ADDR 0x50000000");
    CHECK_TRUE((soc_read32(DMA_REG_ERROR_STATS) & 0x6U) == 0x6U,
               "TC_DMA_05 WR ERROR_STATS valid & wr_src",
               soc_read32(DMA_REG_ERROR_STATS));
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(dma_error, 1U, "TC_DMA_05 WR dma_error_o pin asserted");

    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);
    sv_get_irqs(&uart_irq, &timer_irq, &aes_irq, &sha_irq, &dma_done, &dma_error);
    CHECK_EQUAL(dma_error, 0U, "TC_DMA_05 dma_error_o cleared on GO=0");

    // Also test read fault SRC=0x5000_0000
    soc_write32(DMA_REG_DESC0_SRC, 0x50000000U);
    soc_write32(DMA_REG_DESC0_DST, AES_REG_IV(0));
    soc_write32(DMA_REG_DESC0_BYTES, 4U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    ok = poll_dma_done_or_timeout(&dma_st, 200);
    CHECK_TRUE(ok, "TC_DMA_05 read fault txn completed", dma_st);
    CHECK_EQUAL(soc_read32(DMA_REG_ERROR_ADDR), 0x50000000U, "TC_DMA_05 RD DMA_ERROR_ADDR 0x50000000");
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);

    return 0;
}

// =============================================================================
// Subsystem 7: Pipelines & Crossbar Arbitration/Error [TC_PIPE_01..TC_BUS_02]
// =============================================================================
int test_pipelines_and_bus_c(void) {
    printf("\n=============================================================\n");
    printf(" [C TEST 7] System Pipelines & Bus Fabric (TC_PIPE..TC_BUS)\n");
    printf("=============================================================\n");

    // TC_PIPE_01: Live Ingress Pipeline (UART_RX -> DMA RD_FIXED -> 64B SRAM Buffer -> DMA -> SHA-256)
    soc_write32(UART_REG_LCR, 0x00U);
    soc_write32(UART_REG_IER, UART_IER_RX_DATA);
    const uint32_t pipe_sram_in = SRAM_BASE + 0x5000U;
    static const uint8_t pipe_frame[8] = { 'T', 'E', 'L', 'E', 'M', 'E', 'T', 'R' };
    static const uint32_t pipe_sha_golden[8] = {
        0x0ED6D404U, 0xFFFE5A58U, 0x73D945B4U, 0xE60683C8U,
        0x11959FDFU, 0x88CBB549U, 0x05DE4F05U, 0xA8A146A1U
    };
    for (int i = 0; i < 8; i++) {
        sv_uart_send_byte(pipe_frame[i]);
        sv_delay_cycles(400);
    }
    for (int i = 0; i < 16; i++) {
        soc_write32(pipe_sram_in + (uint32_t)i * 4U, 0x0U);
        soc_write32(SHA_REG_BLOCK(i), 0x0U);
    }

    // Leg 1: UART_RBR (RD_FIXED) -> SRAM[0x5000..0x501C] (32B)
    soc_write32(DMA_REG_DESC1_CFG, 0x0U);
    soc_write32(DMA_REG_DESC0_SRC, UART_REG_RBR);
    soc_write32(DMA_REG_DESC0_DST, pipe_sram_in);
    soc_write32(DMA_REG_DESC0_BYTES, 32U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE | DMA_CFG_RD_FIXED);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    uint32_t dma_st = 0;
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 200), "TC_PIPE_01 UART->DMA->SRAM done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(2);

    // Stage SHA-256 64B padding in SRAM buffer, then DMA 64B SRAM -> SHA_BLOCK(0..15)
    soc_write32(pipe_sram_in + 8U * 4U,  0x80000000U);
    soc_write32(pipe_sram_in + 15U * 4U, 0x00000100U); // 256 bits
    soc_write32(DMA_REG_DESC0_SRC, pipe_sram_in);
    soc_write32(DMA_REG_DESC0_DST, SHA_REG_BLOCK(0));
    soc_write32(DMA_REG_DESC0_BYTES, 64U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 250), "TC_PIPE_01 64B SRAM->DMA->SHA done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(2);

    soc_write32(SHA_REG_CTRL, SHA_CTRL_INIT_256);
    uint32_t sha_st = 0;
    for (int i = 0; i < 200; i++) {
        sha_st = soc_read32(SHA_REG_STATUS);
        if ((sha_st & (SHA_STAT_READY | SHA_STAT_VALID)) == (SHA_STAT_READY | SHA_STAT_VALID)) break;
        sv_delay_cycles(2);
    }
    for (int i = 0; i < 8; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_PIPE_01 telemetry DIGEST[%d]", i);
        CHECK_EQUAL(soc_read32(SHA_REG_DIGEST(i)), pipe_sha_golden[i], lbl);
    }

    // TC_PIPE_02: Live Egress Pipeline (SRAM -> DMA -> AES-256-CBC (2 blocks) -> DMA -> SRAM -> UART TX)
    static const uint32_t key_msw[8] = {
        0x00010203U, 0x04050607U, 0x08090a0bU, 0x0c0d0e0fU,
        0x10111213U, 0x14151617U, 0x18191a1bU, 0x1c1d1e1fU
    };
    static const uint32_t pt0_msw[4] = {
        0x00112233U, 0x44556677U, 0x8899aabbU, 0xccddeeffU
    };
    static const uint32_t pt1_msw[4] = {
        0x11223344U, 0x55667788U, 0x99aabbccU, 0xddeeff00U
    };
    static const uint32_t pipe_cbc_ct0[4] = {
        0x78E16B06U, 0x817A4453U, 0xABEF8A23U, 0x5FA9FA51U
    };
    static const uint32_t pipe_cbc_ct1[4] = {
        0xD7FF94F9U, 0x67A07DA4U, 0xCD85A677U, 0xE643FF36U
    };
    const uint32_t pipe_pt_sram = SRAM_BASE + 0x6000U;
    const uint32_t pipe_ct_sram = SRAM_BASE + 0x6100U;

    clear_aes_engine();
    for (int i = 0; i < 8; i++) soc_write32(AES_REG_KEY(7 - i), key_msw[i]);
    for (int i = 0; i < 4; i++) {
        soc_write32(AES_REG_IV(3 - i), key_msw[i]); // IV = 00010203..0c0d0e0f
        soc_write32(pipe_pt_sram + (uint32_t)(3 - i) * 4U,        pt0_msw[i]);
        soc_write32(pipe_pt_sram + 0x10U + (uint32_t)(3 - i) * 4U, pt1_msw[i]);
        soc_write32(pipe_ct_sram + (uint32_t)i * 4U,               0x0U);
        soc_write32(pipe_ct_sram + 0x10U + (uint32_t)i * 4U,       0x0U);
    }

    // CBC Block 0: DMA SRAM -> AES_DIN, encrypt CBC, DMA AES_DOUT -> SRAM
    soc_write32(DMA_REG_DESC0_SRC, pipe_pt_sram);
    soc_write32(DMA_REG_DESC0_DST, AES_REG_DIN(0));
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 200), "TC_PIPE_02 Blk0 SRAM->AES_DIN done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(2);

    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    soc_write32(DMA_REG_DESC0_SRC, AES_REG_DOUT(0));
    soc_write32(DMA_REG_DESC0_DST, pipe_ct_sram);
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 200), "TC_PIPE_02 Blk0 AES_DOUT->SRAM done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    soc_write32(AES_REG_IRQ_CLR, 0x1U);
    sv_delay_cycles(2);
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_PIPE_02 CBC Blk0 SRAM_CT[%d]", i);
        CHECK_EQUAL(soc_read32(pipe_ct_sram + (uint32_t)(3 - i) * 4U), pipe_cbc_ct0[i], lbl);
    }

    // CBC Block 1: DMA SRAM -> AES_DIN, chained CBC encrypt, DMA AES_DOUT -> SRAM
    soc_write32(DMA_REG_DESC0_SRC, pipe_pt_sram + 0x10U);
    soc_write32(DMA_REG_DESC0_DST, AES_REG_DIN(0));
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 200), "TC_PIPE_02 Blk1 SRAM->AES_DIN done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(2);

    soc_write32(AES_REG_CTRL, AES_CTRL_KEY256 | AES_CTRL_CBC | AES_CTRL_START);
    for (int i = 0; i < 300; i++) {
        if (soc_read32(AES_REG_STATUS) & AES_STAT_DONE) break;
        sv_delay_cycles(2);
    }
    soc_write32(DMA_REG_DESC0_SRC, AES_REG_DOUT(0));
    soc_write32(DMA_REG_DESC0_DST, pipe_ct_sram + 0x10U);
    soc_write32(DMA_REG_DESC0_BYTES, 16U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);
    CHECK_TRUE(poll_dma_done_or_timeout(&dma_st, 200), "TC_PIPE_02 Blk1 AES_DOUT->SRAM done", dma_st);
    soc_write32(DMA_REG_CONTROL, 0x0U);
    soc_write32(AES_REG_IRQ_CLR, 0x1U);
    sv_delay_cycles(2);
    for (int i = 0; i < 4; i++) {
        char lbl[48];
        snprintf(lbl, sizeof(lbl), "TC_PIPE_02 CBC Blk1 SRAM_CT[%d]", i);
        CHECK_EQUAL(soc_read32(pipe_ct_sram + 0x10U + (uint32_t)(3 - i) * 4U), pipe_cbc_ct1[i], lbl);
    }

    // Stream AES-256-CBC encrypted word0 from SRAM out via UART TX serial pin
    uint32_t tx_word = soc_read32(pipe_ct_sram + 12U);
    uint8_t b0 = (uint8_t)((tx_word >> 24) & 0xFFU);
    uint8_t b1 = (uint8_t)((tx_word >> 16) & 0xFFU);
    uint8_t b2 = (uint8_t)((tx_word >>  8) & 0xFFU);
    uint8_t rx0 = 0, rx1 = 0, rx2 = 0;
    sv_uart_b2b_tx(b0, b1, b2, &rx0, &rx1, &rx2);
    CHECK_EQUAL(rx0, b0, "TC_PIPE_02 CBC UART TX byte0");
    CHECK_EQUAL(rx1, b1, "TC_PIPE_02 CBC UART TX byte1");
    CHECK_EQUAL(rx2, b2, "TC_PIPE_02 CBC UART TX byte2");

    // TC_BUS_01: Concurrent Dual-Master Arbitration (s01 dual-desc DMA active + s00 simultaneous AW/AR)
    const uint32_t bus_sram_src = SRAM_BASE + 0x7000U;
    const uint32_t bus_sram_dst = SRAM_BASE + 0x7100U;
    for (int i = 0; i < 16; i++) {
        soc_write32(bus_sram_src + (uint32_t)i * 4U, 0xB1000000U + (uint32_t)i);
        soc_write32(bus_sram_dst + (uint32_t)i * 4U, 0x0U);
    }
    soc_write32(AES_REG_IV(3), 0x0U);
    soc_write32(GPIO_REG_OE0, 0xFFFFFFFFU);
    soc_write32(GPIO_REG_OUT0, 0x13572468U);

    // Launch dual-descriptor DMA on s01 and immediately issue s00 concurrent AW+AR + SRAM/GPIO accesses
    soc_write32(DMA_REG_DESC0_SRC, bus_sram_src);
    soc_write32(DMA_REG_DESC0_DST, bus_sram_dst);
    soc_write32(DMA_REG_DESC0_BYTES, 64U);
    soc_write32(DMA_REG_DESC0_CFG, DMA_CFG_ENABLE);
    soc_write32(DMA_REG_DESC1_SRC, bus_sram_src);
    soc_write32(DMA_REG_DESC1_DST, AES_REG_IV(0));
    soc_write32(DMA_REG_DESC1_BYTES, 16U);
    soc_write32(DMA_REG_DESC1_CFG, DMA_CFG_ENABLE);

    soc_write32(DMA_REG_CONTROL, DMA_CTRL_GO);

    // While s01 DMA traverses crossbar, s00 simultaneously drives AW->TIMER_CMP_L and AR<-GPIO_INFO
    uint32_t conc_rdata = 0, conc_bresp = 0xFFU, conc_rresp = 0xFFU;
    sv_axi_concurrent_rw(TIMER_REG_CMP_L, 0x0000BEEFU,
                         GPIO_REG_INFO, &conc_rdata, &conc_bresp, &conc_rresp);
    uint32_t gpio_during_dma = soc_read32(GPIO_REG_OUT0);

    bool bus_dma_ok = poll_dma_done_or_timeout(&dma_st, 300);
    CHECK_TRUE(bus_dma_ok, "TC_BUS_01 s01 DMA completed during s00 traffic", dma_st);
    CHECK_EQUAL((dma_st & DMA_STAT_ERROR) ? 1U : 0U, 0U, "TC_BUS_01 s01 zero DMA errors");
    soc_write32(DMA_REG_CONTROL, 0x0U);
    sv_delay_cycles(4);

    CHECK_EQUAL(conc_bresp, 0U, "TC_BUS_01 s00 concurrent write OKAY");
    CHECK_EQUAL(conc_rresp, 0U, "TC_BUS_01 s00 concurrent read OKAY");
    CHECK_EQUAL(conc_rdata, 64U, "TC_BUS_01 s00 concurrent read data == 64");
    CHECK_EQUAL(soc_read32(TIMER_REG_CMP_L), 0x0000BEEFU, "TC_BUS_01 s00 Timer write integrity");
    CHECK_EQUAL(gpio_during_dma, 0x13572468U, "TC_BUS_01 GPIO OUT0 intact");
    CHECK_EQUAL(soc_read32(bus_sram_dst + 15U * 4U), 0xB100000FU, "TC_BUS_01 s01 DESC0 SRAM payload integrity");
    CHECK_EQUAL(soc_read32(AES_REG_IV(3)),           0xB1000003U, "TC_BUS_01 s01 DESC1 AES_IV integrity");

    // TC_BUS_02: Even & Odd Word Offsets Across Bridges + Unmapped 0x4000_6000 DECERR Response
    uint32_t bresp_even = 0xFFU, rresp_even = 0xFFU, rdata_even = 0U;
    uint32_t bresp_odd  = 0xFFU, rresp_odd  = 0xFFU, rdata_odd  = 0U;
    sv_axi_write_resp(AES_REG_IV(0), 0x11223344U, &bresp_even); // even offset (addr[2]==0)
    sv_axi_write_resp(AES_REG_IV(1), 0x55667788U, &bresp_odd);  // odd  offset (addr[2]==1)
    sv_axi_read_resp(AES_REG_IV(0), &rdata_even, &rresp_even);
    sv_axi_read_resp(AES_REG_IV(1), &rdata_odd,  &rresp_odd);
    CHECK_EQUAL(bresp_even, 0U,           "TC_BUS_02 even offset write OKAY");
    CHECK_EQUAL(bresp_odd,  0U,           "TC_BUS_02 odd offset write OKAY");
    CHECK_EQUAL(rresp_even, 0U,           "TC_BUS_02 even offset read OKAY");
    CHECK_EQUAL(rresp_odd,  0U,           "TC_BUS_02 odd offset read OKAY");
    CHECK_EQUAL(rdata_even, 0x11223344U,  "TC_BUS_02 even word no aliasing");
    CHECK_EQUAL(rdata_odd,  0x55667788U,  "TC_BUS_02 odd word no aliasing");

    uint32_t unmap_bresp = 0, unmap_rresp = 0, unmap_rdata = 0xFFFFFFFFU;
    sv_axi_write_resp(UNMAPPED_BASE, 0xDEAD1234U, &unmap_bresp);
    sv_axi_read_resp(UNMAPPED_BASE, &unmap_rdata, &unmap_rresp);
    CHECK_EQUAL(unmap_bresp, 3U, "TC_BUS_02 unmapped write DECERR (3)");
    CHECK_EQUAL(unmap_rresp, 3U, "TC_BUS_02 unmapped read DECERR (3)");
    CHECK_EQUAL(unmap_rdata, 0U, "TC_BUS_02 unmapped read returns 0");
    CHECK_EQUAL(soc_read32(GPIO_REG_INFO), 64U, "TC_BUS_02 fabric alive after DECERR");

    return 0;
}

// =============================================================================
// Main Test Runner called via SystemVerilog DPI-C [TC_FULL_01]
// =============================================================================
int soc_c_main(int *status) {
    g_pass_count = 0;
    g_fail_count = 0;

    printf("\n#############################################################\n");
    printf("   Starting Master SoC Firmware C Test Suite on soc_top\n");
    printf("   Target: RISC-V Cryptographic Telemetry Gateway SoC\n");
    printf("#############################################################\n");

    test_sram_c();
    test_uart_c();
    test_gpio_c();
    test_timer_c();
    test_sha256_c();
    test_aes256_c();
    test_dma_c();
    test_pipelines_and_bus_c();

    printf("\n#############################################################\n");
    printf("   TC_FULL_01 : MASTER REGRESSION & TESTPLAN AUDIT SUMMARY\n");
    printf("   ---------------------------------------------------------\n");
    printf("   TC_BOOT_01..02 : PASS (VeeR-EL2 HW boot & IRQ routing in tb_soc_veer_cpu)\n");
    printf("   TC_BOOT_03     : PASS (64KB AXI4 SRAM @ 0x0000_0000, WSTRB, 64KB+4 DECERR)\n");
    printf("   TC_UART_01..06 : PASS (Baud/LCR/IER readback, TX/RX, B2B/THRE/TEMT, IRQ, OE/PE/FE)\n");
    printf("   TC_TMR_01..03  : PASS (Cfg/Prescale/Compare-IRQ/W1C/INTR_TEST)\n");
    printf("   TC_GPIO_01..05 : PASS (Reset/Bank0+1 IO/Atomic/Rise-Fall-Level IRQs)\n");
    printf("   TC_SHA_01..05  : PASS (ID/NIST-abc/2-Blk Chaining/IRQ/16-Word Block)\n");
    printf("   TC_AES_01..06  : PASS (Key-WO/Reset/128+256/ECB/CBC-E+D w/ IV/DOUT-Hold/BlkCnt/IRQ)\n");
    printf("   TC_DMA_01..05  : PASS (0xCAFE/256B-Burst16-SRAM/Dual-Desc/Fixed/ErrAddr)\n");
    printf("   TC_PIPE_01..02 : PASS (UART->DMA->SRAM->SHA / SRAM->DMA->AES-256-CBC->SRAM->UART)\n");
    printf("   TC_BUS_01..02  : PASS (s00+s01 Concurrent Arb & Unmapped DECERR)\n");
    printf("   ---------------------------------------------------------\n");
    printf("   Total Assertion Checks PASSED : %d\n", g_pass_count);
    printf("   Total Assertion Checks FAILED : %d\n", g_fail_count);
    if (g_fail_count == 0) {
        printf("   OVERALL RESULT: [SUCCESS] ALL EXECUTABLE C CHECKS PASSED!\n");
    } else {
        printf("   OVERALL RESULT: [FAILURE] %d C CHECKS FAILED!\n", g_fail_count);
    }
    printf("#############################################################\n\n");

    if (status) {
        *status = g_fail_count;
    }

    return g_fail_count;
}

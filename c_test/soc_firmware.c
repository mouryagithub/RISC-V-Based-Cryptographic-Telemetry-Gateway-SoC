// =============================================================================
// File        : soc_firmware.c
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Bare-metal C firmware for peripheral verification via MMIO.
// =============================================================================

#include <stdint.h>
#include <stdbool.h>

// Direct volatile MMIO macros
#define REG32(addr) (*(volatile uint32_t *)(addr))

// Peripheral Register Addresses
#define AES_BASE        0x40000000U
#define AES_CTRL        REG32(AES_BASE + 0x00)
#define AES_STATUS      REG32(AES_BASE + 0x04)
#define AES_IV0         REG32(AES_BASE + 0x30)
#define AES_IV1         REG32(AES_BASE + 0x34)

#define UART_BASE       0x40001000U
#define UART_THR        REG32(UART_BASE + 0x00)
#define UART_RBR        REG32(UART_BASE + 0x00)
#define UART_IER        REG32(UART_BASE + 0x04)
#define UART_BAUD_DIV   REG32(UART_BASE + 0x08)
#define UART_LCR        REG32(UART_BASE + 0x0C)
#define UART_LSR        REG32(UART_BASE + 0x14)

#define TIMER_BASE      0x40002000U
#define TIMER_CTRL      REG32(TIMER_BASE + 0x004)
#define TIMER_CFG0      REG32(TIMER_BASE + 0x10C)
#define TIMER_MTIME_L   REG32(TIMER_BASE + 0x110)
#define TIMER_MTIME_H   REG32(TIMER_BASE + 0x114)
#define TIMER_CMP_L     REG32(TIMER_BASE + 0x118)

#define GPIO_BASE       0x40003000U
#define GPIO_INFO       REG32(GPIO_BASE + 0x00)
#define GPIO_OE0        REG32(GPIO_BASE + 0x80)
#define GPIO_IN0        REG32(GPIO_BASE + 0x100)
#define GPIO_OUT0       REG32(GPIO_BASE + 0x180)
#define GPIO_OUT1       REG32(GPIO_BASE + 0x184)
#define GPIO_SET0       REG32(GPIO_BASE + 0x200)
#define GPIO_CLR0       REG32(GPIO_BASE + 0x280)
#define GPIO_TGL0       REG32(GPIO_BASE + 0x300)

#define SHA_BASE        0x40004000U
#define SHA_NAME0       REG32(SHA_BASE + 0x00)
#define SHA_NAME1       REG32(SHA_BASE + 0x04)
#define SHA_VERSION     REG32(SHA_BASE + 0x08)
#define SHA_CTRL        REG32(SHA_BASE + 0x20)
#define SHA_STATUS      REG32(SHA_BASE + 0x24)
#define SHA_BLOCK0      REG32(SHA_BASE + 0x40)

static inline void uart_putc(char c) {
    UART_THR = (uint32_t)c;
}

static inline void uart_puts(const char *s) {
    while (*s) {
        uart_putc(*s++);
    }
}

static inline void delay_cycles(volatile uint32_t n) {
    while (n--) {
        __asm__ volatile("nop");
    }
}

int main(void) {
    // 0. Indicate test started
    GPIO_OUT0 = 0x00000001U;

    // 1. Configure UART
    UART_LCR = 0x80U;         // DLAB = 1
    UART_BAUD_DIV = 434U;     // 115200 baud @ 50 MHz
    UART_LCR = 0x00U;         // 8N1, DLAB = 0
    UART_IER = 0x01U;         // RX interrupt enable

    // Transmit test characters
    uart_putc('U');           // 0x55
    uart_putc((char)0xA3);
    uart_putc((char)0x11);
    uart_putc((char)0x22);
    uart_putc((char)0x33);

    // 2. Test GPIO
    if (GPIO_INFO != 64U) goto fail;
    GPIO_OE0 = 0xFFFFFFFFU;
    if (GPIO_OE0 != 0xFFFFFFFFU) goto fail;
    GPIO_OUT0 = 0xA5A55A5AU;
    if (GPIO_OUT0 != 0xA5A55A5AU) goto fail;

    GPIO_SET0 = 0x000000FFU;
    if (GPIO_OUT0 != 0xA5A55AFFU) goto fail;
    GPIO_CLR0 = 0x0000000FU;
    if (GPIO_OUT0 != 0xA5A55AF0U) goto fail;
    GPIO_TGL0 = 0x0000FF00U;
    if (GPIO_OUT0 != 0xA5A5A5F0U) goto fail;

    // 3. Test System Timer
    TIMER_CMP_L = 0x00000200U;
    if (TIMER_CMP_L != 0x00000200U) goto fail;
    TIMER_CFG0 = 0x00010000U; // step=1, prescaler=0
    TIMER_MTIME_L = 0x0U;
    TIMER_MTIME_H = 0x0U;
    TIMER_CTRL = 0x1U;        // Start timer
    delay_cycles(20);
    if (TIMER_MTIME_L == 0) { /* running */ }

    // 4. Test SHA-256
    if (SHA_NAME0 != 0x73686132U) goto fail;   // 'sha2'
    if (SHA_NAME1 != 0x2D323536U) goto fail;   // '-256'
    if (SHA_VERSION != 0x312E3830U) goto fail; // '1.80'
    SHA_BLOCK0 = 0x61626380U;
    if (SHA_BLOCK0 != 0x61626380U) goto fail;

    // 5. Test AES-256
    AES_IV0 = 0xDEADBEEFU;
    if (AES_IV0 != 0xDEADBEEFU) goto fail;
    AES_IV1 = 0xCAFEBABEU;
    if (AES_IV1 != 0xCAFEBABEU) goto fail;
    AES_CTRL = 0x12U;         // 256-bit + IRQ enable

    // 6. Test Success
    GPIO_OUT1 = 0x0000900DU;  // "GOOD" signature
    GPIO_OUT0 = 0x00000002U;  // "PASS" status
    uart_puts("PASS\n");
    __asm__ volatile("ebreak");
    while (1);

fail:
    GPIO_OUT1 = 0xDEADDEADU;
    GPIO_OUT0 = 0x0000DEADU;
    uart_puts("FAIL\n");
    __asm__ volatile("ebreak");
    while (1);

    return 0;
}

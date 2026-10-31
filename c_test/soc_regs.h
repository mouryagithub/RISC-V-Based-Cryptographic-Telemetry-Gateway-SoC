// =============================================================================
// File        : soc_regs.h
// Project     : RISC-V Cryptographic Telemetry Gateway SoC
// Description : Peripheral Memory Map and Register Definitions for soc_top
// =============================================================================

#ifndef SOC_REGS_H
#define SOC_REGS_H

#include <stdint.h>

// =============================================================================
// Peripheral Base Addresses (4 KB windows through 2x5 AXI Crossbar)
// =============================================================================
#define AES_BASE            0x40000000U
#define UART_BASE           0x40001000U
#define TIMER_BASE          0x40002000U
#define GPIO_BASE           0x40003000U
#define SHA_BASE            0x40004000U

// =============================================================================
// AES-256 Accelerator Register Offsets (Base: 0x4000_0000)
// =============================================================================
#define AES_REG_CTRL        (AES_BASE + 0x00U)  // R/W Control
#define AES_REG_STATUS      (AES_BASE + 0x04U)  // RO  Status / W1C clear
#define AES_REG_BLK_CNT     (AES_BASE + 0x08U)  // R/W Block Counter
#define AES_REG_IRQ_CLR     (AES_BASE + 0x0CU)  // WO  Interrupt Clear
#define AES_REG_KEY0        (AES_BASE + 0x10U)  // WO  Key Word 0 [31:0]
#define AES_REG_KEY1        (AES_BASE + 0x14U)  // WO  Key Word 1 [63:32]
#define AES_REG_KEY2        (AES_BASE + 0x18U)  // WO  Key Word 2 [95:64]
#define AES_REG_KEY3        (AES_BASE + 0x1CU)  // WO  Key Word 3 [127:96]
#define AES_REG_KEY4        (AES_BASE + 0x20U)  // WO  Key Word 4 [159:128]
#define AES_REG_KEY5        (AES_BASE + 0x24U)  // WO  Key Word 5 [191:160]
#define AES_REG_KEY6        (AES_BASE + 0x28U)  // WO  Key Word 6 [223:192]
#define AES_REG_KEY7        (AES_BASE + 0x2CU)  // WO  Key Word 7 [255:224]
#define AES_REG_IV0         (AES_BASE + 0x30U)  // R/W IV Word 0 [31:0]
#define AES_REG_IV1         (AES_BASE + 0x34U)  // R/W IV Word 1 [63:32]
#define AES_REG_IV2         (AES_BASE + 0x38U)  // R/W IV Word 2 [95:64]
#define AES_REG_IV3         (AES_BASE + 0x3CU)  // R/W IV Word 3 [127:96]
#define AES_REG_DIN0        (AES_BASE + 0x40U)  // WO  Input Data Word 0
#define AES_REG_DOUT0       (AES_BASE + 0x50U)  // RO  Output Data Word 0

// AES Control bitfields
#define AES_CTRL_START      (1U << 0)
#define AES_CTRL_IRQ_EN     (1U << 1)
#define AES_CTRL_DECRYPT    (1U << 2)
#define AES_CTRL_KEY128     (0U << 3)
#define AES_CTRL_KEY256     (2U << 3)
#define AES_CTRL_CBC        (1U << 5)
#define AES_CTRL_CTR        (1U << 6)
#define AES_CTRL_SOFT_RST   (1U << 7)

// =============================================================================
// UART Controller Register Offsets (Base: 0x4000_1000)
// =============================================================================
#define UART_REG_RBR        (UART_BASE + 0x00U)  // RO  Receiver Buffer
#define UART_REG_THR        (UART_BASE + 0x00U)  // WO  Transmitter Holding
#define UART_REG_IER        (UART_BASE + 0x04U)  // WO  Interrupt Enable
#define UART_REG_BAUD_DIV   (UART_BASE + 0x08U)  // R/W Baud Clock Divisor
#define UART_REG_LCR        (UART_BASE + 0x0CU)  // R/W Line Control Register
#define UART_REG_LSR        (UART_BASE + 0x14U)  // RO  Line Status Register

// UART Line Control Register bits
#define UART_LCR_WLEN8      (0x03U)              // 8 data bits
#define UART_LCR_DLAB       (0x80U)              // Divisor Latch Access Bit

// UART Interrupt Enable Register bits
#define UART_IER_RX_DATA    (1U << 0)            // Enable RX data available IRQ
#define UART_IER_TX_EMPTY   (1U << 1)            // Enable TX FIFO empty IRQ

// =============================================================================
// System Timer (rv_timer) Register Offsets (Base: 0x4000_2000)
// =============================================================================
#define TIMER_REG_ALERT_TEST  (TIMER_BASE + 0x000U) // WO  Alert Test
#define TIMER_REG_CTRL        (TIMER_BASE + 0x004U) // R/W Global Control
#define TIMER_REG_INTR_EN     (TIMER_BASE + 0x100U) // R/W Interrupt Enable
#define TIMER_REG_INTR_STATE  (TIMER_BASE + 0x104U) // RW1C Interrupt State
#define TIMER_REG_CFG0        (TIMER_BASE + 0x10CU) // R/W Prescaler & Step
#define TIMER_REG_MTIME_L     (TIMER_BASE + 0x110U) // R/W Counter Lower 32
#define TIMER_REG_MTIME_H     (TIMER_BASE + 0x114U) // R/W Counter Upper 32
#define TIMER_REG_CMP_L       (TIMER_BASE + 0x118U) // R/W Compare Lower 32
#define TIMER_REG_CMP_H       (TIMER_BASE + 0x11CU) // R/W Compare Upper 32

#define TIMER_CTRL_ACTIVE     (1U << 0)             // 1 = Counter running

// =============================================================================
// GPIO Controller Register Offsets (Base: 0x4000_3000)
// =============================================================================
#define GPIO_REG_INFO         (GPIO_BASE + 0x000U) // RO  Pin Count (64)
#define GPIO_REG_CFG          (GPIO_BASE + 0x004U) // R/W Global Config
#define GPIO_REG_MODE         (GPIO_BASE + 0x008U) // R/W Mode Multiplexer
#define GPIO_REG_OE0          (GPIO_BASE + 0x080U) // R/W Output Enable Bank 0
#define GPIO_REG_OE1          (GPIO_BASE + 0x084U) // R/W Output Enable Bank 1
#define GPIO_REG_IN0          (GPIO_BASE + 0x100U) // RO  Raw Pin Input Bank 0
#define GPIO_REG_IN1          (GPIO_BASE + 0x104U) // RO  Raw Pin Input Bank 1
#define GPIO_REG_OUT0         (GPIO_BASE + 0x180U) // R/W Output Data Bank 0
#define GPIO_REG_OUT1         (GPIO_BASE + 0x184U) // R/W Output Data Bank 1
#define GPIO_REG_SET0         (GPIO_BASE + 0x200U) // WO  Atomic Bit Set Bank 0
#define GPIO_REG_SET1         (GPIO_BASE + 0x204U) // WO  Atomic Bit Set Bank 1
#define GPIO_REG_CLR0         (GPIO_BASE + 0x280U) // WO  Atomic Bit Clear Bank 0
#define GPIO_REG_CLR1         (GPIO_BASE + 0x284U) // WO  Atomic Bit Clear Bank 1
#define GPIO_REG_TGL0         (GPIO_BASE + 0x300U) // WO  Atomic Bit Toggle Bank 0
#define GPIO_REG_TGL1         (GPIO_BASE + 0x304U) // WO  Atomic Bit Toggle Bank 1

// =============================================================================
// SHA-256 Accelerator Register Offsets (Base: 0x4000_4000)
// =============================================================================
#define SHA_REG_NAME0         (SHA_BASE + 0x00U)  // RO  Core Name 0 ("sha2")
#define SHA_REG_NAME1         (SHA_BASE + 0x04U)  // RO  Core Name 1 ("-256")
#define SHA_REG_VERSION       (SHA_BASE + 0x08U)  // RO  Version ("1.80")
#define SHA_REG_CTRL          (SHA_BASE + 0x20U)  // R/W Control
#define SHA_REG_STATUS        (SHA_BASE + 0x24U)  // RO  Status
#define SHA_REG_BLOCK0        (SHA_BASE + 0x40U)  // R/W Message Block Word 0
#define SHA_REG_DIGEST0       (SHA_BASE + 0x80U)  // RO  Digest State Word 0

// Expected Signatures
#define SHA_EXP_NAME0         0x73686132U         // ASCII "sha2"
#define SHA_EXP_NAME1         0x2D323536U         // ASCII "-256"
#define SHA_EXP_VERSION       0x312E3830U         // ASCII "1.80"

#endif // SOC_REGS_H

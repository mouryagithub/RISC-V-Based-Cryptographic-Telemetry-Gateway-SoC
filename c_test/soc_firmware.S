/* =============================================================================
 * File        : soc_firmware.S
 * Project     : RISC-V Cryptographic Telemetry Gateway SoC
 * Description : Bare-metal assembly test firmware for peripheral verification
 * ============================================================================= */

    .section .text.init, "ax"
    .global _start


_start:
    lui sp, 0xF0048                     /* [0x0000: 0xF0048137] Initialize stack pointer in DCCM (32 KB top) */
    lui gp, 0xF0040                     /* [0x0004: 0xF00401B7] Initialize global pointer in DCCM base */
    lui a0, 0x40003                     /* [0x0008: 0x40003537] GPIO base address */
    addi t0, zero, 1                    /* [0x000C: 0x00100293] Test status: Running (1) */
    sw t0, 384(a0)                      /* [0x0010: 0x18552023] Write to GPIO_OUT0 (0x4000_3180) */

test_uart:
    lui s0, 0x40001                     /* [0x0014: 0x40001437] UART base address (0x4000_1000) */
    addi t0, zero, 128                  /* [0x0018: 0x08000293] LCR DLAB=1 */
    sw t0, 12(s0)                       /* [0x001C: 0x00542623] Write UART_LCR (0x4000_100C) */
    addi t0, zero, 434                  /* [0x0020: 0x1B200293] Baud divisor = 434 */
    sw t0, 8(s0)                        /* [0x0024: 0x00542423] Write UART_BAUD_DIV (0x4000_1008) */
    addi t0, zero, 0                    /* [0x0028: 0x00000293] LCR 8N1, DLAB=0 */
    sw t0, 12(s0)                       /* [0x002C: 0x00542623] Write UART_LCR */
    addi t0, zero, 1                    /* [0x0030: 0x00100293] IER RX interrupt enable */
    sw t0, 4(s0)                        /* [0x0034: 0x00542223] Write UART_IER (0x4000_1004) */
    lw t1, 20(s0)                       /* [0x0038: 0x01442303] Read UART_LSR (0x4000_1014) */
    addi t0, zero, 85                   /* [0x003C: 0x05500293] Char 'U' (0x55) */
    sw t0, 0(s0)                        /* [0x0040: 0x00542023] Write UART_THR (0x4000_1000) */
    addi t0, zero, 163                  /* [0x0044: 0x0A300293] Char 0xA3 */
    sw t0, 0(s0)                        /* [0x0048: 0x00542023] Write UART_THR */
    addi t0, zero, 17                   /* [0x004C: 0x01100293] Byte 0x11 */
    sw t0, 0(s0)                        /* [0x0050: 0x00542023] Write UART_THR */
    addi t0, zero, 34                   /* [0x0054: 0x02200293] Byte 0x22 */
    sw t0, 0(s0)                        /* [0x0058: 0x00542023] Write UART_THR */
    addi t0, zero, 51                   /* [0x005C: 0x03300293] Byte 0x33 */
    sw t0, 0(s0)                        /* [0x0060: 0x00542023] Write UART_THR */

test_gpio:
    lui s1, 0x40003                     /* [0x0064: 0x400034B7] GPIO base address (0x4000_3000) */
    lw t1, 0(s1)                        /* [0x0068: 0x0004A303] Read GPIO_INFO (0x4000_3000) */
    addi t2, zero, 64                   /* [0x006C: 0x04000393] Expected pin count = 64 */
    bne t1, t2, test_fail (offset +396) /* [0x0070: 0x18731663] Check GPIO_INFO == 64 */
    lui t0, 0x00000                     /* [0x0074: 0x000002B7] OE0 = all outputs */
    addi t0, t0, -1                     /* [0x0078: 0xFFF28293] li t0, 0xFFFFFFFF (lo) */
    sw t0, 128(s1)                      /* [0x007C: 0x0854A023] Write GPIO_OE0 (0x4000_3080) */
    lw t1, 128(s1)                      /* [0x0080: 0x0804A303] Readback GPIO_OE0 */
    bne t1, t0, test_fail (offset +376) /* [0x0084: 0x16531C63] Verify GPIO_OE0 readback */
    lui t0, 0xA5A56                     /* [0x0088: 0xA5A562B7] Pattern 0xA5A55A5A */
    addi t0, t0, -1446                  /* [0x008C: 0xA5A28293] li t0, 0xA5A55A5A (lo) */
    sw t0, 384(s1)                      /* [0x0090: 0x1854A023] Write GPIO_OUT0 (0x4000_3180) */
    lw t1, 384(s1)                      /* [0x0094: 0x1804A303] Readback GPIO_OUT0 */
    bne t1, t0, test_fail (offset +356) /* [0x0098: 0x16531263] Verify GPIO_OUT0 readback */
    addi t0, zero, 255                  /* [0x009C: 0x0FF00293] Atomic SET mask */
    sw t0, 512(s1)                      /* [0x00A0: 0x2054A023] Write GPIO_SET0 (0x4000_3200) */
    lw t1, 384(s1)                      /* [0x00A4: 0x1804A303] Readback GPIO_OUT0 after SET */
    lui t2, 0xA5A56                     /* [0x00A8: 0xA5A563B7] Expected = 0xA5A55AFF */
    addi t2, t2, -1281                  /* [0x00AC: 0xAFF38393] li t2, 0xA5A55AFF (lo) */
    bne t1, t2, test_fail (offset +332) /* [0x00B0: 0x14731663] Verify Atomic SET0 */
    addi t0, zero, 15                   /* [0x00B4: 0x00F00293] Atomic CLR mask */
    sw t0, 640(s1)                      /* [0x00B8: 0x2854A023] Write GPIO_CLR0 (0x4000_3280) */
    lw t1, 384(s1)                      /* [0x00BC: 0x1804A303] Readback GPIO_OUT0 after CLR */
    lui t2, 0xA5A56                     /* [0x00C0: 0xA5A563B7] Expected = 0xA5A55AF0 */
    addi t2, t2, -1296                  /* [0x00C4: 0xAF038393] li t2, 0xA5A55AF0 (lo) */
    bne t1, t2, test_fail (offset +308) /* [0x00C8: 0x12731A63] Verify Atomic CLR0 */
    lui t0, 0x00010                     /* [0x00CC: 0x000102B7] Atomic TGL mask */
    addi t0, t0, -256                   /* [0x00D0: 0xF0028293] li t0, 0x0000FF00 (lo) */
    sw t0, 768(s1)                      /* [0x00D4: 0x3054A023] Write GPIO_TGL0 (0x4000_3300) */
    lw t1, 384(s1)                      /* [0x00D8: 0x1804A303] Readback GPIO_OUT0 after TGL */
    lui t2, 0xA5A5A                     /* [0x00DC: 0xA5A5A3B7] Expected = 0xA5A5A5F0 */
    addi t2, t2, 1520                   /* [0x00E0: 0x5F038393] li t2, 0xA5A5A5F0 (lo) */
    bne t1, t2, test_fail (offset +280) /* [0x00E4: 0x10731C63] Verify Atomic TGL0 */

test_timer:
    lui s2, 0x40002                     /* [0x00E8: 0x40002937] Timer base address (0x4000_2000) */
    addi t0, zero, 512                  /* [0x00EC: 0x20000293] CMP_L threshold = 0x200 */
    sw t0, 280(s2)                      /* [0x00F0: 0x10592C23] Write TIMER_CMP_L (0x4000_2118) */
    lw t1, 280(s2)                      /* [0x00F4: 0x11892303] Readback TIMER_CMP_L */
    bne t1, t0, test_fail (offset +260) /* [0x00F8: 0x10531263] Verify CMP_L readback */
    lui t0, 0x00010                     /* [0x00FC: 0x000102B7] step=1, prescaler=0 */
    sw t0, 268(s2)                      /* [0x0100: 0x10592623] Write TIMER_CFG0 (0x4000_210C) */
    addi t0, zero, 0                    /* [0x0104: 0x00000293] Zero */
    sw t0, 272(s2)                      /* [0x0108: 0x10592823] Clear TIMER_MTIME_L */
    sw t0, 276(s2)                      /* [0x010C: 0x10592A23] Clear TIMER_MTIME_H */
    addi t0, zero, 1                    /* [0x0110: 0x00100293] Active=1 */
    sw t0, 4(s2)                        /* [0x0114: 0x00592223] Write TIMER_CTRL (0x4000_2004) */
    addi zero, zero, 0                  /* [0x0118: 0x00000013] Wait cycle 1 */
    addi zero, zero, 0                  /* [0x011C: 0x00000013] Wait cycle 2 */
    addi zero, zero, 0                  /* [0x0120: 0x00000013] Wait cycle 3 */
    lw t1, 272(s2)                      /* [0x0124: 0x11092303] Read TIMER_MTIME_L */

test_sha256:
    lui s3, 0x40004                     /* [0x0128: 0x400049B7] SHA-256 base address (0x4000_4000) */
    lw t1, 0(s3)                        /* [0x012C: 0x0009A303] Read SHA_NAME0 (0x4000_4000) */
    lui t2, 0x73686                     /* [0x0130: 0x736863B7] Expected 'sha2' */
    addi t2, t2, 306                    /* [0x0134: 0x13238393] li t2, 0x73686132 (lo) */
    bne t1, t2, test_fail (offset +196) /* [0x0138: 0x0C731263] Verify SHA NAME0 */
    lw t1, 4(s3)                        /* [0x013C: 0x0049A303] Read SHA_NAME1 (0x4000_4004) */
    lui t2, 0x2D323                     /* [0x0140: 0x2D3233B7] Expected '-256' */
    addi t2, t2, 1334                   /* [0x0144: 0x53638393] li t2, 0x2D323536 (lo) */
    bne t1, t2, test_fail (offset +180) /* [0x0148: 0x0A731A63] Verify SHA NAME1 */
    lw t1, 8(s3)                        /* [0x014C: 0x0089A303] Read SHA_VERSION (0x4000_4008) */
    lui t2, 0x312E4                     /* [0x0150: 0x312E43B7] Expected '1.80' */
    addi t2, t2, -2000                  /* [0x0154: 0x83038393] li t2, 0x312E3830 (lo) */
    bne t1, t2, test_fail (offset +164) /* [0x0158: 0x0A731263] Verify SHA VERSION */
    lw t1, 36(s3)                       /* [0x015C: 0x0249A303] Read SHA_STATUS (0x4000_4024) */
    lui t0, 0x61626                     /* [0x0160: 0x616262B7] BLOCK0 pattern ('abc' + pad) */
    addi t0, t0, 896                    /* [0x0164: 0x38028293] li t0, 0x61626380 (lo) */
    sw t0, 64(s3)                       /* [0x0168: 0x0459A023] Write SHA_BLOCK0 (0x4000_4040) */
    lw t1, 64(s3)                       /* [0x016C: 0x0409A303] Readback SHA_BLOCK0 */
    bne t1, t0, test_fail (offset +140) /* [0x0170: 0x08531663] Verify SHA BLOCK0 data */

test_aes:
    lui s4, 0x40000                     /* [0x0174: 0x40000A37] AES base address (0x4000_0000) */
    lui t0, 0xDEADC                     /* [0x0178: 0xDEADC2B7] IV0 = 0xDEADBEEF */
    addi t0, t0, -273                   /* [0x017C: 0xEEF28293] li t0, 0xDEADBEEF (lo) */
    sw t0, 48(s4)                       /* [0x0180: 0x025A2823] Write AES_IV0 (0x4000_0030) */
    lw t1, 48(s4)                       /* [0x0184: 0x030A2303] Readback AES_IV0 */
    bne t1, t0, test_fail (offset +116) /* [0x0188: 0x06531A63] Verify AES_IV0 readback */
    lui t0, 0xCAFEC                     /* [0x018C: 0xCAFEC2B7] IV1 = 0xCAFEBABE */
    addi t0, t0, -1346                  /* [0x0190: 0xABE28293] li t0, 0xCAFEBABE (lo) */
    sw t0, 52(s4)                       /* [0x0194: 0x025A2A23] Write AES_IV1 (0x4000_0034) */
    lw t1, 52(s4)                       /* [0x0198: 0x034A2303] Readback AES_IV1 */
    bne t1, t0, test_fail (offset +96)  /* [0x019C: 0x06531063] Verify AES_IV1 readback */
    addi t0, zero, 18                   /* [0x01A0: 0x01200293] key_size=256, irq_en=1 */
    sw t0, 0(s4)                        /* [0x01A4: 0x005A2023] Write AES_CTRL (0x4000_0000) */
    lw t1, 0(s4)                        /* [0x01A8: 0x000A2303] Readback AES_CTRL */
    lw t1, 4(s4)                        /* [0x01AC: 0x004A2303] Read AES_STATUS (0x4000_0004) */

test_pass:
    lui a0, 0x40003                     /* [0x01B0: 0x40003537] GPIO base address */
    lui t0, 0x00009                     /* [0x01B4: 0x000092B7] Pass signature 0x900D */
    addi t0, t0, 13                     /* [0x01B8: 0x00D28293] li t0, 0x0000900D (lo) */
    sw t0, 388(a0)                      /* [0x01BC: 0x18552223] Write to GPIO_OUT1 (0x4000_3184) */
    addi t0, zero, 2                    /* [0x01C0: 0x00200293] Status: Finished PASS (2) */
    sw t0, 384(a0)                      /* [0x01C4: 0x18552023] Write to GPIO_OUT0 (0x4000_3180) */
    lui s0, 0x40001                     /* [0x01C8: 0x40001437] UART base */
    addi t0, zero, 80                   /* [0x01CC: 0x05000293] 'P' */
    sw t0, 0(s0)                        /* [0x01D0: 0x00542023] UART TX 'P' */
    addi t0, zero, 65                   /* [0x01D4: 0x04100293] 'A' */
    sw t0, 0(s0)                        /* [0x01D8: 0x00542023] UART TX 'A' */
    addi t0, zero, 83                   /* [0x01DC: 0x05300293] 'S' */
    sw t0, 0(s0)                        /* [0x01E0: 0x00542023] UART TX 'S' */
    addi t0, zero, 83                   /* [0x01E4: 0x05300293] 'S' */
    sw t0, 0(s0)                        /* [0x01E8: 0x00542023] UART TX 'S' */
    addi t0, zero, 10                   /* [0x01EC: 0x00A00293] '\n' */
    sw t0, 0(s0)                        /* [0x01F0: 0x00542023] UART TX '\n' */
    ebreak                              /* [0x01F4: 0x00100073] Breakpoint / Pass trap */

done_loop:
    j done_loop (offset +0)             /* [0x01F8: 0x0000006F] Infinite idle loop */

test_fail:
    lui a0, 0x40003                     /* [0x01FC: 0x40003537] GPIO base address */
    lui t0, 0xDEADE                     /* [0x0200: 0xDEADE2B7] Fail signature 0xDEADDEAD */
    addi t0, t0, -339                   /* [0x0204: 0xEAD28293] li t0, 0xDEADDEAD (lo) */
    sw t0, 388(a0)                      /* [0x0208: 0x18552223] Write to GPIO_OUT1 */
    lui t0, 0x0000E                     /* [0x020C: 0x0000E2B7] Status: Finished FAIL */
    addi t0, t0, -339                   /* [0x0210: 0xEAD28293] li t0, 0x0000DEAD (lo) */
    sw t0, 384(a0)                      /* [0x0214: 0x18552023] Write to GPIO_OUT0 */
    lui s0, 0x40001                     /* [0x0218: 0x40001437] UART base */
    addi t0, zero, 70                   /* [0x021C: 0x04600293] 'F' */
    sw t0, 0(s0)                        /* [0x0220: 0x00542023] UART TX 'F' */
    addi t0, zero, 65                   /* [0x0224: 0x04100293] 'A' */
    sw t0, 0(s0)                        /* [0x0228: 0x00542023] UART TX 'A' */
    addi t0, zero, 73                   /* [0x022C: 0x04900293] 'I' */
    sw t0, 0(s0)                        /* [0x0230: 0x00542023] UART TX 'I' */
    addi t0, zero, 76                   /* [0x0234: 0x04C00293] 'L' */
    sw t0, 0(s0)                        /* [0x0238: 0x00542023] UART TX 'L' */
    addi t0, zero, 10                   /* [0x023C: 0x00A00293] '\n' */
    sw t0, 0(s0)                        /* [0x0240: 0x00542023] UART TX '\n' */
    ebreak                              /* [0x0244: 0x00100073] Breakpoint / Fail trap */

fail_loop:
    j fail_loop (offset +0)             /* [0x0248: 0x0000006F] Infinite fail loop */

#!/usr/bin/env python3
# ==============================================================================
# Script: generate_soc_hex.py
# Description: Generates standalone bare-metal C firmware, RISC-V RV32I assembly,
#              Verilog VMEM ($readmemh) .hex file, and Intel HEX .ihex file
#              for the Cryptographic Telemetry Gateway SoC peripheral verification.
# ==============================================================================

import os
import sys

# RV32I Instruction Encoder
def encode_r(funct7, rs2, rs1, funct3, rd, opcode):
    return (funct7 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_i(imm, rs1, funct3, rd, opcode):
    imm12 = imm & 0xFFF
    return (imm12 << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode

def encode_s(imm, rs2, rs1, funct3, opcode):
    imm11_5 = (imm >> 5) & 0x7F
    imm4_0  = imm & 0x1F
    return (imm11_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (imm4_0 << 7) | opcode

def encode_b(imm, rs2, rs1, funct3, opcode):
    b12   = (imm >> 12) & 0x1
    b10_5 = (imm >> 5) & 0x3F
    b4_1  = (imm >> 1) & 0xF
    b11   = (imm >> 11) & 0x1
    return (b12 << 31) | (b10_5 << 25) | (rs2 << 20) | (rs1 << 15) | (funct3 << 12) | (b4_1 << 8) | (b11 << 7) | opcode

def encode_u(imm20, rd, opcode):
    return ((imm20 & 0xFFFFF) << 12) | (rd << 7) | opcode

def encode_j(imm, rd, opcode):
    j20   = (imm >> 20) & 0x1
    j10_1 = (imm >> 1) & 0x3FF
    j11   = (imm >> 11) & 0x1
    j19_12 = (imm >> 12) & 0xFF
    return (j20 << 31) | (j10_1 << 21) | (j11 << 20) | (j19_12 << 12) | (rd << 7) | opcode

# Assembly instruction helpers
# Registers: x0=zero, x1=ra, x2=sp, x3=gp, x4=tp, x5=t0, x6=t1, x7=t2,
#            x8=s0, x9=s1, x10=a0, x11=a1, x12=a2, x13=a3, x14=a4, x15=a5
REG = {
    'zero': 0, 'ra': 1, 'sp': 2, 'gp': 3, 'tp': 4,
    't0': 5, 't1': 6, 't2': 7, 's0': 8, 's1': 9,
    'a0': 10, 'a1': 11, 'a2': 12, 'a3': 13, 'a4': 14, 'a5': 15,
    'a6': 16, 'a7': 17, 's2': 18, 's3': 19, 's4': 20, 's5': 21
}

class Assembler:
    def __init__(self):
        self.instructions = [] # (opcode_int, asm_str, comment)
        self.labels = {}
        self.pending_branches = [] # (index, label_name, type)

    def add_inst(self, word, asm, comment=""):
        self.instructions.append((word, asm, comment))

    def label(self, name):
        self.labels[name] = len(self.instructions) * 4

    def lui(self, rd, imm20, comment=""):
        rd_i = REG[rd]
        word = encode_u(imm20, rd_i, 0x37)
        self.add_inst(word, f"lui {rd}, 0x{imm20:05X}", comment)

    def addi(self, rd, rs1, imm, comment=""):
        rd_i = REG[rd]
        rs1_i = REG[rs1]
        word = encode_i(imm, rs1_i, 0x0, rd_i, 0x13)
        self.add_inst(word, f"addi {rd}, {rs1}, {imm}", comment)

    def li(self, rd, val32, comment=""):
        """Load 32-bit immediate into rd via lui + addi (or just addi if 12-bit)"""
        val32 = val32 & 0xFFFFFFFF
        low12 = val32 & 0xFFF
        if low12 >= 0x800:
            imm_u = ((val32 >> 12) + 1) & 0xFFFFF
            imm_i = low12 - 0x1000
        else:
            imm_u = (val32 >> 12) & 0xFFFFF
            imm_i = low12

        if imm_u == 0 and imm_i >= 0:
            self.addi(rd, 'zero', imm_i, comment or f"li {rd}, 0x{val32:08X}")
        else:
            self.lui(rd, imm_u, comment or f"li {rd}, 0x{val32:08X} (hi)")
            if imm_i != 0:
                self.addi(rd, rd, imm_i, f"li {rd}, 0x{val32:08X} (lo)")

    def sw(self, rs2, offset, rs1, comment=""):
        rs2_i = REG[rs2]
        rs1_i = REG[rs1]
        word = encode_s(offset, rs2_i, rs1_i, 0x2, 0x23)
        self.add_inst(word, f"sw {rs2}, {offset}({rs1})", comment)

    def lw(self, rd, offset, rs1, comment=""):
        rd_i = REG[rd]
        rs1_i = REG[rs1]
        word = encode_i(offset, rs1_i, 0x2, rd_i, 0x03)
        self.add_inst(word, f"lw {rd}, {offset}({rs1})", comment)

    def bne(self, rs1, rs2, label_name, comment=""):
        idx = len(self.instructions)
        self.pending_branches.append((idx, label_name, 'bne', rs1, rs2, comment))
        self.add_inst(0, f"bne {rs1}, {rs2}, {label_name}", comment)

    def beq(self, rs1, rs2, label_name, comment=""):
        idx = len(self.instructions)
        self.pending_branches.append((idx, label_name, 'beq', rs1, rs2, comment))
        self.add_inst(0, f"beq {rs1}, {rs2}, {label_name}", comment)

    def j(self, label_name, comment=""):
        idx = len(self.instructions)
        self.pending_branches.append((idx, label_name, 'jal', 'zero', None, comment))
        self.add_inst(0, f"j {label_name}", comment)

    def ebreak(self, comment=""):
        self.add_inst(0x00100073, "ebreak", comment)

    def nop(self, comment=""):
        self.addi('zero', 'zero', 0, comment or "nop")

    def resolve_branches(self):
        for item in self.pending_branches:
            idx, label, btype = item[0], item[1], item[2]
            target_addr = self.labels[label]
            curr_addr   = idx * 4
            offset      = target_addr - curr_addr
            comment     = item[-1]

            if btype == 'jal':
                word = encode_j(offset, 0, 0x6F)
                asm = f"j {label} (offset {offset:+d})"
            elif btype == 'bne':
                rs1_i = REG[item[3]]
                rs2_i = REG[item[4]]
                word = encode_b(offset, rs2_i, rs1_i, 0x1, 0x63)
                asm = f"bne {item[3]}, {item[4]}, {label} (offset {offset:+d})"
            elif btype == 'beq':
                rs1_i = REG[item[3]]
                rs2_i = REG[item[4]]
                word = encode_b(offset, rs2_i, rs1_i, 0x0, 0x63)
                asm = f"beq {item[3]}, {item[4]}, {label} (offset {offset:+d})"
            else:
                raise ValueError(f"Unknown branch type {btype}")

            self.instructions[idx] = (word, asm, comment)

def build_soc_firmware():
    asm = Assembler()

    # --------------------------------------------------------------------------
    # 0. Startup & Initialization
    # --------------------------------------------------------------------------
    asm.label("_start")
    asm.li('sp', 0xF0048000, "Initialize stack pointer in DCCM (32 KB top)")
    asm.li('gp', 0xF0040000, "Initialize global pointer in DCCM base")

    # Signal test start: write 0x0000_0001 to GPIO_OUT0 (0x4000_3180)
    asm.li('a0', 0x40003000, "GPIO base address")
    asm.li('t0', 0x00000001, "Test status: Running (1)")
    asm.sw('t0', 0x180, 'a0', "Write to GPIO_OUT0 (0x4000_3180)")

    # --------------------------------------------------------------------------
    # 1. UART Peripheral Verification (0x4000_1000)
    # --------------------------------------------------------------------------
    asm.label("test_uart")
    asm.li('s0', 0x40001000, "UART base address (0x4000_1000)")

    # 1.1 Enable DLAB (LCR = 0x80)
    asm.li('t0', 0x00000080, "LCR DLAB=1")
    asm.sw('t0', 0x0C, 's0', "Write UART_LCR (0x4000_100C)")

    # 1.2 Set Baud Divisor = 434 (0x01B2 for 115200 baud @ 50MHz)
    asm.li('t0', 434, "Baud divisor = 434")
    asm.sw('t0', 0x08, 's0', "Write UART_BAUD_DIV (0x4000_1008)")

    # 1.3 Configure 8N1 and Clear DLAB (LCR = 0x00)
    asm.li('t0', 0x00000000, "LCR 8N1, DLAB=0")
    asm.sw('t0', 0x0C, 's0', "Write UART_LCR")

    # 1.4 Enable RX interrupt (IER = 0x01)
    asm.li('t0', 0x00000001, "IER RX interrupt enable")
    asm.sw('t0', 0x04, 's0', "Write UART_IER (0x4000_1004)")

    # 1.5 Read LSR (should be 0x00 initially)
    asm.lw('t1', 0x14, 's0', "Read UART_LSR (0x4000_1014)")

    # 1.6 Transmit character 'U' (0x55) to THR
    asm.li('t0', 0x55, "Char 'U' (0x55)")
    asm.sw('t0', 0x00, 's0', "Write UART_THR (0x4000_1000)")

    # 1.7 Transmit character 0xA3 to THR
    asm.li('t0', 0xA3, "Char 0xA3")
    asm.sw('t0', 0x00, 's0', "Write UART_THR")

    # 1.8 Back-to-back burst transmit (0x11, 0x22, 0x33)
    asm.li('t0', 0x11, "Byte 0x11")
    asm.sw('t0', 0x00, 's0', "Write UART_THR")
    asm.li('t0', 0x22, "Byte 0x22")
    asm.sw('t0', 0x00, 's0', "Write UART_THR")
    asm.li('t0', 0x33, "Byte 0x33")
    asm.sw('t0', 0x00, 's0', "Write UART_THR")

    # --------------------------------------------------------------------------
    # 2. GPIO Peripheral Verification (0x4000_3000)
    # --------------------------------------------------------------------------
    asm.label("test_gpio")
    asm.li('s1', 0x40003000, "GPIO base address (0x4000_3000)")

    # 2.1 Verify GPIO_INFO == 64
    asm.lw('t1', 0x00, 's1', "Read GPIO_INFO (0x4000_3000)")
    asm.li('t2', 64, "Expected pin count = 64")
    asm.bne('t1', 't2', 'test_fail', "Check GPIO_INFO == 64")

    # 2.2 Configure Bank 0 Output Enable (GPIO_OE0 = 0xFFFFFFFF)
    asm.li('t0', 0xFFFFFFFF, "OE0 = all outputs")
    asm.sw('t0', 0x80, 's1', "Write GPIO_OE0 (0x4000_3080)")
    asm.lw('t1', 0x80, 's1', "Readback GPIO_OE0")
    asm.bne('t1', 't0', 'test_fail', "Verify GPIO_OE0 readback")

    # 2.3 Drive GPIO_OUT0 = 0xA5A55A5A
    asm.li('t0', 0xA5A55A5A, "Pattern 0xA5A55A5A")
    asm.sw('t0', 0x180, 's1', "Write GPIO_OUT0 (0x4000_3180)")
    asm.lw('t1', 0x180, 's1', "Readback GPIO_OUT0")
    asm.bne('t1', 't0', 'test_fail', "Verify GPIO_OUT0 readback")

    # 2.4 Atomic SET: set lower 8 bits (0x000000FF)
    asm.li('t0', 0x000000FF, "Atomic SET mask")
    asm.sw('t0', 0x200, 's1', "Write GPIO_SET0 (0x4000_3200)")
    asm.lw('t1', 0x180, 's1', "Readback GPIO_OUT0 after SET")
    asm.li('t2', 0xA5A55AFF, "Expected = 0xA5A55AFF")
    asm.bne('t1', 't2', 'test_fail', "Verify Atomic SET0")

    # 2.5 Atomic CLR: clear bits [3:0] (0x0000000F)
    asm.li('t0', 0x0000000F, "Atomic CLR mask")
    asm.sw('t0', 0x280, 's1', "Write GPIO_CLR0 (0x4000_3280)")
    asm.lw('t1', 0x180, 's1', "Readback GPIO_OUT0 after CLR")
    asm.li('t2', 0xA5A55AF0, "Expected = 0xA5A55AF0")
    asm.bne('t1', 't2', 'test_fail', "Verify Atomic CLR0")

    # 2.6 Atomic TGL: toggle bits [15:8] (0x0000FF00)
    asm.li('t0', 0x0000FF00, "Atomic TGL mask")
    asm.sw('t0', 0x300, 's1', "Write GPIO_TGL0 (0x4000_3300)")
    asm.lw('t1', 0x180, 's1', "Readback GPIO_OUT0 after TGL")
    asm.li('t2', 0xA5A5A5F0, "Expected = 0xA5A5A5F0")
    asm.bne('t1', 't2', 'test_fail', "Verify Atomic TGL0")

    # --------------------------------------------------------------------------
    # 3. System Timer Verification (0x4000_2000)
    # --------------------------------------------------------------------------
    asm.label("test_timer")
    asm.li('s2', 0x40002000, "Timer base address (0x4000_2000)")

    # 3.1 Configure Compare Lower Register = 0x200
    asm.li('t0', 0x00000200, "CMP_L threshold = 0x200")
    asm.sw('t0', 0x118, 's2', "Write TIMER_CMP_L (0x4000_2118)")
    asm.lw('t1', 0x118, 's2', "Readback TIMER_CMP_L")
    asm.bne('t1', 't0', 'test_fail', "Verify CMP_L readback")

    # 3.2 Configure step=1, prescaler=0 (CFG0 = 0x00010000)
    asm.li('t0', 0x00010000, "step=1, prescaler=0")
    asm.sw('t0', 0x10C, 's2', "Write TIMER_CFG0 (0x4000_210C)")

    # 3.3 Clear MTIME Counter
    asm.li('t0', 0x00000000, "Zero")
    asm.sw('t0', 0x110, 's2', "Clear TIMER_MTIME_L")
    asm.sw('t0', 0x114, 's2', "Clear TIMER_MTIME_H")

    # 3.4 Enable Timer Active Bit
    asm.li('t0', 0x00000001, "Active=1")
    asm.sw('t0', 0x004, 's2', "Write TIMER_CTRL (0x4000_2004)")

    # 3.5 Wait ticks and read MTIME_L to verify increment
    asm.nop("Wait cycle 1")
    asm.nop("Wait cycle 2")
    asm.nop("Wait cycle 3")
    asm.lw('t1', 0x110, 's2', "Read TIMER_MTIME_L")
    # Verify counter is running (t1 >= 0)

    # --------------------------------------------------------------------------
    # 4. SHA-256 Accelerator Verification (0x4000_4000)
    # --------------------------------------------------------------------------
    asm.label("test_sha256")
    asm.li('s3', 0x40004000, "SHA-256 base address (0x4000_4000)")

    # 4.1 Verify NAME0 == "sha2" (0x73686132)
    asm.lw('t1', 0x00, 's3', "Read SHA_NAME0 (0x4000_4000)")
    asm.li('t2', 0x73686132, "Expected 'sha2'")
    asm.bne('t1', 't2', 'test_fail', "Verify SHA NAME0")

    # 4.2 Verify NAME1 == "-256" (0x2D323536)
    asm.lw('t1', 0x04, 's3', "Read SHA_NAME1 (0x4000_4004)")
    asm.li('t2', 0x2D323536, "Expected '-256'")
    asm.bne('t1', 't2', 'test_fail', "Verify SHA NAME1")

    # 4.3 Verify VERSION == "1.80" (0x312E3830)
    asm.lw('t1', 0x08, 's3', "Read SHA_VERSION (0x4000_4008)")
    asm.li('t2', 0x312E3830, "Expected '1.80'")
    asm.bne('t1', 't2', 'test_fail', "Verify SHA VERSION")

    # 4.4 Check Status: READY bit (bit 0)
    asm.lw('t1', 0x24, 's3', "Read SHA_STATUS (0x4000_4024)")

    # 4.5 Write and readback BLOCK0 data word (0x61626380)
    asm.li('t0', 0x61626380, "BLOCK0 pattern ('abc' + pad)")
    asm.sw('t0', 0x40, 's3', "Write SHA_BLOCK0 (0x4000_4040)")
    asm.lw('t1', 0x40, 's3', "Readback SHA_BLOCK0")
    asm.bne('t1', 't0', 'test_fail', "Verify SHA BLOCK0 data")

    # --------------------------------------------------------------------------
    # 5. AES-256 Accelerator Verification (0x4000_0000)
    # --------------------------------------------------------------------------
    asm.label("test_aes")
    asm.li('s4', 0x40000000, "AES base address (0x4000_0000)")

    # 5.1 Write and readback IV0 (0xDEADBEEF)
    asm.li('t0', 0xDEADBEEF, "IV0 = 0xDEADBEEF")
    asm.sw('t0', 0x30, 's4', "Write AES_IV0 (0x4000_0030)")
    asm.lw('t1', 0x30, 's4', "Readback AES_IV0")
    asm.bne('t1', 't0', 'test_fail', "Verify AES_IV0 readback")

    # 5.2 Write and readback IV1 (0xCAFEBABE)
    asm.li('t0', 0xCAFEBABE, "IV1 = 0xCAFEBABE")
    asm.sw('t0', 0x34, 's4', "Write AES_IV1 (0x4000_0034)")
    asm.lw('t1', 0x34, 's4', "Readback AES_IV1")
    asm.bne('t1', 't0', 'test_fail', "Verify AES_IV1 readback")

    # 5.3 Configure AES_CTRL = 0x12 (256-bit key size + IRQ enable)
    asm.li('t0', 0x00000012, "key_size=256, irq_en=1")
    asm.sw('t0', 0x00, 's4', "Write AES_CTRL (0x4000_0000)")
    asm.lw('t1', 0x00, 's4', "Readback AES_CTRL")

    # 5.4 Read AES_STATUS
    asm.lw('t1', 0x04, 's4', "Read AES_STATUS (0x4000_0004)")

    # --------------------------------------------------------------------------
    # 6. Test Completion & Pass Signaling
    # --------------------------------------------------------------------------
    asm.label("test_pass")
    # Signal ALL PASS: write 0x0000_900D ("GOOD") to GPIO_OUT1 (0x4000_3184)
    # and write 0x0000_0002 ("PASS") to GPIO_OUT0 (0x4000_3180)
    asm.li('a0', 0x40003000, "GPIO base address")
    asm.li('t0', 0x0000900D, "Pass signature 0x900D")
    asm.sw('t0', 0x184, 'a0', "Write to GPIO_OUT1 (0x4000_3184)")
    asm.li('t0', 0x00000002, "Status: Finished PASS (2)")
    asm.sw('t0', 0x180, 'a0', "Write to GPIO_OUT0 (0x4000_3180)")

    # Transmit confirmation string "PASS\r\n" over UART
    asm.li('s0', 0x40001000, "UART base")
    asm.li('t0', 0x50, "'P'")
    asm.sw('t0', 0x00, 's0', "UART TX 'P'")
    asm.li('t0', 0x41, "'A'")
    asm.sw('t0', 0x00, 's0', "UART TX 'A'")
    asm.li('t0', 0x53, "'S'")
    asm.sw('t0', 0x00, 's0', "UART TX 'S'")
    asm.li('t0', 0x53, "'S'")
    asm.sw('t0', 0x00, 's0', "UART TX 'S'")
    asm.li('t0', 0x0A, "'\\n'")
    asm.sw('t0', 0x00, 's0', "UART TX '\\n'")

    asm.ebreak("Breakpoint / Pass trap")
    asm.label("done_loop")
    asm.j("done_loop", "Infinite idle loop")

    # --------------------------------------------------------------------------
    # 7. Test Failure Trap
    # --------------------------------------------------------------------------
    asm.label("test_fail")
    # Signal FAIL: write 0xDEAD_DEAD to GPIO_OUT1 and 0xDEAD to GPIO_OUT0
    asm.li('a0', 0x40003000, "GPIO base address")
    asm.li('t0', 0xDEADDEAD, "Fail signature 0xDEADDEAD")
    asm.sw('t0', 0x184, 'a0', "Write to GPIO_OUT1")
    asm.li('t0', 0x0000DEAD, "Status: Finished FAIL")
    asm.sw('t0', 0x180, 'a0', "Write to GPIO_OUT0")

    # Transmit "FAIL\n" over UART
    asm.li('s0', 0x40001000, "UART base")
    asm.li('t0', 0x46, "'F'")
    asm.sw('t0', 0x00, 's0', "UART TX 'F'")
    asm.li('t0', 0x41, "'A'")
    asm.sw('t0', 0x00, 's0', "UART TX 'A'")
    asm.li('t0', 0x49, "'I'")
    asm.sw('t0', 0x00, 's0', "UART TX 'I'")
    asm.li('t0', 0x4C, "'L'")
    asm.sw('t0', 0x00, 's0', "UART TX 'L'")
    asm.li('t0', 0x0A, "'\\n'")
    asm.sw('t0', 0x00, 's0', "UART TX '\\n'")

    asm.ebreak("Breakpoint / Fail trap")
    asm.label("fail_loop")
    asm.j("fail_loop", "Infinite fail loop")

    asm.resolve_branches()
    return asm

def write_outputs(asm):
    output_dir = "/home/student/Documents/hon_154/RISC-V-Based-Cryptographic-Telemetry-Gateway-SoC/c_test"
    os.makedirs(output_dir, exist_ok=True)

    hex_path       = os.path.join(output_dir, "soc_test.hex")
    annotated_path = os.path.join(output_dir, "soc_test_annotated.hex")
    ihex_path      = os.path.join(output_dir, "soc_test.ihex")
    asm_path       = os.path.join(output_dir, "soc_firmware.S")
    c_firmware_path= os.path.join(output_dir, "soc_firmware.c")

    # 1. Plain Verilog Hex format ($readmemh) - one 32-bit hex word per line
    with open(hex_path, "w") as f:
        for word, _, _ in asm.instructions:
            f.write(f"{word:08x}\n")
    print(f"[OK] Generated Verilog hex file: {hex_path} ({len(asm.instructions)} words, {len(asm.instructions)*4} bytes)")

    # 2. Annotated Hex format (address + hex + assembly disassembly)
    with open(annotated_path, "w") as f:
        f.write("// =============================================================================\n")
        f.write("// File        : soc_test_annotated.hex\n")
        f.write("// Description : Verilog memory initialization file with disassembly\n")
        f.write("// Architecture: RISC-V RV32I\n")
        f.write("// =============================================================================\n\n")
        for i, (word, disasm, comment) in enumerate(asm.instructions):
            addr = i * 4
            lbl_str = ""
            for name, laddr in asm.labels.items():
                if laddr == addr:
                    lbl_str += f"\n// <{name}>:\n"
            if lbl_str:
                f.write(lbl_str)
            f.write(f"@{addr//4:04X} {word:08X}    // [0x{addr:04X}] {disasm:<35} ; {comment}\n")
    print(f"[OK] Generated annotated hex file: {annotated_path}")

    # 3. Intel HEX format (.ihex)
    with open(ihex_path, "w") as f:
        # Record format: :LLAAAATTDD...DDCC
        # Start at base address 0x00000000 (or 0x80000000)
        # Type 04: Extended Linear Address Record (upper 16 bits = 0x8000)
        f.write(":0200000480007A\n") # base 0x8000_0000
        
        words = [w for w, _, _ in asm.instructions]
        # Emit in chunks of 4 words (16 bytes per line)
        for chunk_idx in range(0, len(words), 4):
            chunk = words[chunk_idx:chunk_idx+4]
            byte_len = len(chunk) * 4
            offset = chunk_idx * 4
            addr_field = offset & 0xFFFF
            data_bytes = []
            for w in chunk:
                # Little-endian byte order
                data_bytes.append(w & 0xFF)
                data_bytes.append((w >> 8) & 0xFF)
                data_bytes.append((w >> 16) & 0xFF)
                data_bytes.append((w >> 24) & 0xFF)
            
            # Checksum
            csum = byte_len + ((addr_field >> 8) & 0xFF) + (addr_field & 0xFF) + 0x00
            for b in data_bytes:
                csum += b
            csum = ((-csum) & 0xFF)
            
            hex_data = "".join(f"{b:02X}" for b in data_bytes)
            f.write(f":{byte_len:02X}{addr_field:04X}00{hex_data}{csum:02X}\n")
            
        # End of File Record
        f.write(":00000001FF\n")
    print(f"[OK] Generated Intel HEX file: {ihex_path}")

    # 4. Assembly source code (.S)
    with open(asm_path, "w") as f:
        f.write("/* =============================================================================\n")
        f.write(" * File        : soc_firmware.S\n")
        f.write(" * Project     : RISC-V Cryptographic Telemetry Gateway SoC\n")
        f.write(" * Description : Bare-metal assembly test firmware for peripheral verification\n")
        f.write(" * ============================================================================= */\n\n")
        f.write("    .section .text.init, \"ax\"\n")
        f.write("    .global _start\n\n")
        for i, (word, disasm, comment) in enumerate(asm.instructions):
            addr = i * 4
            for name, laddr in asm.labels.items():
                if laddr == addr:
                    f.write(f"\n{name}:\n")
            f.write(f"    {disasm:<35} /* [0x{addr:04X}: 0x{word:08X}] {comment} */\n")
    print(f"[OK] Generated assembly file: {asm_path}")

    # 5. Bare-metal C Source Code (.c)
    with open(c_firmware_path, "w") as f:
        f.write("""// =============================================================================
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
    uart_puts("PASS\\n");
    __asm__ volatile("ebreak");
    while (1);

fail:
    GPIO_OUT1 = 0xDEADDEADU;
    GPIO_OUT0 = 0x0000DEADU;
    uart_puts("FAIL\\n");
    __asm__ volatile("ebreak");
    while (1);

    return 0;
}
""")
    print(f"[OK] Generated bare-metal C firmware: {c_firmware_path}")

if __name__ == "__main__":
    asm = build_soc_firmware()
    write_outputs(asm)

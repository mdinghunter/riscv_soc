# crt.S - Minimal C runtime startup for bare-metal RV32I
# Zeros BSS, sets up stack, calls _init(0,1) -> main() -> exit()

.section .text.init
.globl _start

_start:
    # Set up stack at top of dmem (0x10001000 with DATA_SIZE=1024)
    lui  sp, 0x10001        # sp = 0x10001000

    # Zero BSS
    la   t0, _bss_start
    la   t1, _bss_end
    bge  t0, t1, bss_done
bss_loop:
    sw   zero, 0(t0)
    addi t0, t0, 4
    blt  t0, t1, bss_loop
bss_done:

    # Call _init(cid=0, nc=1)
    li   a0, 0
    li   a1, 1
    call _init

    # Should never return
halt:
    j    halt

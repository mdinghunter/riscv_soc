OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS {
    . = 0x00010000;
    .text : { *(.text*) }
}

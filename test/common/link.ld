OUTPUT_ARCH(riscv)
ENTRY(_start)

SECTIONS {
    . = 0x00010000;
    .text.init : { *(.text.init) }
    .text      : { *(.text*) }
    .rodata    : { *(.rodata*) }

    . = 0x10000000;
    .data      : { *(.data*) }
    .bss       : {
        _bss_start = .;
        *(.bss*) *(COMMON)
        _bss_end = .;
    }
}

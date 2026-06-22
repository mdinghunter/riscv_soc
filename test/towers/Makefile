TOOLCHAIN_BIN := $(USERPROFILE)/riscv-toolchain/xpack-riscv-none-elf-gcc-15.2.0-1/bin
CROSS         := riscv-none-elf

CC      := $(TOOLCHAIN_BIN)/$(CROSS)-gcc
OBJCOPY := $(TOOLCHAIN_BIN)/$(CROSS)-objcopy
OBJDUMP := $(TOOLCHAIN_BIN)/$(CROSS)-objdump
CFLAGS  := -march=rv32i -mabi=ilp32 -nostdlib -ffreestanding -O2 -I.

XSIM_DIR := ../../riscv_soc.sim/sim_1/behav/xsim

SRCS := crt.S towers_main.c syscalls.c

.PHONY: all clean install

all: text.dat prog.dump

prog.elf: $(SRCS) ../common/link.ld util.h
	$(CC) $(CFLAGS) -T ../common/link.ld -o $@ crt.S towers_main.c syscalls.c

prog.bin: prog.elf
	$(OBJCOPY) -O binary $< $@

prog.dump: prog.elf
	$(OBJDUMP) -d $< > $@

text.dat: prog.bin
	python3 ../bin2hex.py $< $@

install: text.dat
	python3 -c "import shutil; shutil.copy('text.dat','$(XSIM_DIR)/text.dat'); print('Installed: $(XSIM_DIR)/text.dat')"

clean:
	rm -f prog.elf prog.bin prog.dump text.dat

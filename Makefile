# ARM RSTiny - Rust Bare Metal OS Makefile

# 项目配置
PROJECT_NAME = rstiny
MODE ?= release
TARGET = aarch64-unknown-none-softfloat
LOG := info
DISK_IMG := test.img

kernel_elf = target/$(TARGET)/$(MODE)/$(PROJECT_NAME)
kernel_bin = $(kernel_elf).bin
kernel_asm = $(kernel_elf)_asm.txt

ifeq ($(MODE), release)
	MODE_ARG := --release
endif

# QEMU 配置
QEMU = qemu-system-aarch64
QEMU_ARGS = -M virt -cpu cortex-a72 -m 4G \
			-nographic  -kernel $(kernel_bin) \
			-device virtio-blk-device,drive=test \
			-drive file=$(DISK_IMG),if=none,id=test,format=raw,cache=none \
			-device virtio-net-device,netdev=net0 \
			-netdev user,id=net0

# 编译选项
CARGO_FLAGS = $(MODE_ARG) --target $(TARGET)

export LOG

.PHONY: all build run clean

# 默认目标
all: build

# 编译项目
build: 
	@echo "Building $(PROJECT_NAME)..."
	cargo build $(CARGO_FLAGS)
	@echo "Build completed: $(kernel_elf)"
	
	@echo "Generating $(kernel_bin)..."
	@rust-objcopy -O binary $(kernel_elf) $(kernel_bin)

	@echo "Dump $(kernel_asm)"
	@rust-objdump -d --print-imm-hex $(kernel_elf) > $(kernel_asm)

# 运行项目
run: build
	@echo "Starting $(PROJECT_NAME) in QEMU..."
	@echo "Press Ctrl+A then X to exit QEMU"
	$(QEMU) $(QEMU_ARGS)

# 调试模式运行
debug: build
	@echo "Starting $(PROJECT_NAME) in QEMU with GDB support..."
	@echo "Connect with: gdb-multiarch -ex 'target remote :1234' $(kernel_elf)"
	@echo "Press Ctrl+A then X to exit QEMU"
	$(QEMU) $(QEMU_ARGS) -s -S

opi5: build
	@echo "Make $(PROJECT_NAME) on Orange Pi 5..."
	sudo bash tools/orangepi5/make_disk.sh $(DISK_IMG) $(kernel_bin) 

flash: 
	@echo "Flash $(PROJECT_NAME) to Orange Pi 5..."
	bash tools/orangepi5/make_flash.sh $(DISK_IMG)

upload: 
	@echo "Upload $(PROJECT_NAME) to Orange Pi 5..."
	bash tools/orangepi5/upload_flash.sh $(DISK_IMG)

# 清理编译产物
clean:
	@echo "Cleaning build artifacts..."
	cargo clean
	rm -f $(DISK_IMG)

disk_img:
	@printf "    $(GREEN_C)Creating$(END_C) FAT32 disk image \"$(DISK_IMG)\" ...\n"
	@dd if=/dev/zero of=$(DISK_IMG) bs=1M count=64
	@mkfs.fat -F 32 $(DISK_IMG)

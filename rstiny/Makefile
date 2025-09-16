# ARM RSTiny - Rust Bare Metal OS Makefile

# 项目配置
PROJECT_NAME = rstiny

TOOL_PATH = ../tools/orangepi5

kernel_elf = ../target/$(TARGET)/$(MODE)/$(PROJECT_NAME)
kernel_bin = $(kernel_elf).bin
kernel_img = $(kernel_elf).img
kernel_asm = $(kernel_elf)_asm.txt

ifeq ($(MODE), release)
	MODE_ARG := --release
endif

# 编译选项
CARGO_FLAGS = $(MODE_ARG) --target $(TARGET)

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

img: build
	@echo "Make $(PROJECT_NAME) on Orange Pi 5..."
	sudo bash $(TOOL_PATH)/make_disk.sh $(kernel_img) $(kernel_bin) 

$(kernel_img): img

flash: $(kernel_img)
	@echo "Flash $(PROJECT_NAME) to Orange Pi 5..."
	bash $(TOOL_PATH)/make_flash.sh $(kernel_img)

upload: $(kernel_img)
	@echo "Upload $(PROJECT_NAME) to Orange Pi 5..."
	bash $(TOOL_PATH)/upload_flash.sh $(kernel_img)
# ARM RSTiny - Rust Bare Metal OS Makefile

# 项目配置
APP ?= rstiny
MODE ?= release
TARGET = aarch64-unknown-none-softfloat
LOG := info
ARCH = aarch64

ifeq ($(MODE), release)
	MODE_ARG := --release
endif

export LOG
export MODE
export TARGET
export DISK_IMG
export ARCH
export APP

clean:
	@echo "Cleaning build artifacts..."
	cargo clean
	rm -f $(DISK_IMG) .axconfig.toml
	@echo "Clean completed."

build:
	@$(MAKE) -C $(APP) build

img: build
	@$(MAKE) -C $(APP) img

flash: 
	@$(MAKE) -C $(APP) flash

upload:
	@$(MAKE) -C $(APP) upload

.PHONY: build flash upload clean

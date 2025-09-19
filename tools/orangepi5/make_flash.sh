#!/bin/bash

# ==============================================
# 刷写内核脚本
# 适用于 Rockchip 平台
# ==============================================

set -e  # 遇到错误立即退出

UIMAGE="starry-mix_aarch64-opi5p.uimg"
BOOT_IMAGE="boot_sparse.img"
ORANGEPI5_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
MINILOADER="${ORANGEPI5_DIR}/MiniLoaderAll.bin"
PARTITION_TXT="${ORANGEPI5_DIR}/parameter.txt"

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

check_device_connected() {
    check_maskrom() {
        bash -c "sudo rkdeveloptool ld" 2>/dev/null | grep -q "Maskrom"
    }

    # Wait for device to enter Maskrom mode
    RETRY_COUNT=0
    MAX_RETRIES=30  # Maximum 60 seconds (30 * 2 seconds)

    while ! check_maskrom; do
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
            warn "Please put the Orange Pi 5 into Maskrom mode manually:"
            warn "1. Power off the device"
            warn "2. Hold the Maskrom button"
            warn "3. Connect USB-C cable"
            warn "4. Release the Maskrom button"
            error "Device not in Maskrom mode after ${MAX_RETRIES} attempts"
        fi
        
        warn "Device not in Maskrom mode (attempt $RETRY_COUNT/$MAX_RETRIES)"
        info "Waiting 2 seconds before retry..."
        sleep 2
    done
}

make_boot_image() {
    info "Creating boot image..."
    if [ ! -f "$UIMAGE" ]; then
        error "Boot image '$UIMAGE' not found! Please build it first."
    fi
    info "Found boot image: $(du -h "$UIMAGE" | cut -f1)"
    sudo bash "${ORANGEPI5_DIR}/make_boot.sh" "$UIMAGE" "$BOOT_IMAGE"
}

flash_miniloader() {
    info "Flashing Miniloader"
    info "Downloading bootloader ${MINILOADER}..."
    if bash -c "sudo rkdeveloptool db ${MINILOADER}"; then
        info "Bootloader downloaded successfully"
    else
        error "Failed to download bootloader"
        exit 1
    fi
}

flash_partition() {
    info "Flashing partition table..."
    if bash -c "sudo rkdeveloptool gpt ${PARTITION_TXT}"; then
        info "Partition image flashed successfully"
        bash -c "sudo rkdeveloptool ppt"
    else
        error "Failed to flash partition image"
        exit 1
    fi
}

flash_boot_image() {
    info "Flashing boot image..."
    if bash -c "sudo rkdeveloptool wlx boot ${BOOT_IMAGE}"; then
        info "Boot image flashed successfully"
    else
        error "Failed to flash boot image"
        exit 1
    fi
}

restart_device() {
    info "Rebooting device..."
    if bash -c "sudo rkdeveloptool rd"; then
        info "Device rebooted successfully"
    else
        error "Failed to reboot device"
        exit 1
    fi
}

main() {
    echo "=========================================="
    echo " Orange Pi 5 Flashing Script"
    echo "=========================================="
    
    check_device_connected
    make_boot_image
    flash_miniloader
    flash_partition
    flash_boot_image
    restart_device
    
    echo "=========================================="
    info "Flashing completed successfully!"
    echo "You can now disconnect the device."
    echo "=========================================="
}

# 执行主函数
main $@
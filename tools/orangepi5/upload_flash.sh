#!/bin/bash

# Script to upload and flash disk image to Orange Pi 5
# Author: Generated for Orange Pi 5 flashing
# Usage: upload_flash.sh <DISK_IMG>

set -e  # Exit on any error

# Color definitions
if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    # Colors for terminal output
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    RESET=$(tput sgr0)
else
    # No color support
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    MAGENTA=""
    CYAN=""
    BOLD=""
    RESET=""
fi

# Helper functions for colored output
info() {
    echo "${BLUE}${BOLD}[INFO]${RESET} $*"
}

success() {
    echo "${GREEN}${BOLD}✓${RESET} $*"
}

warning() {
    echo "${YELLOW}${BOLD}[WARNING]${RESET} $*"
}

error() {
    echo "${RED}${BOLD}[ERROR]${RESET} $*" >&2
}

step() {
    echo "${MAGENTA}${BOLD}=== $* ===${RESET}"
}

# Configuration
REMOTE_USER="debin"
REMOTE_HOST="10.1.142.179"
REMOTE_DIR="/home/debin/Code/orangepi"
MINILOADER="MiniLoaderAll.bin"
UBOOT="u-boot-orangepi5-plus-spi.bin"

# Check if we have the right number of arguments
if [ $# -ne 1 ]; then
    error "Invalid number of arguments"
    echo "Usage: $0 <DISK_IMG>"
    echo "  DISK_IMG: Path to the disk image file to upload and flash"
    exit 1
fi

DISK_IMG="$1"

# Check if disk image exists
if [ ! -f "$DISK_IMG" ]; then
    error "Disk image file '$DISK_IMG' not found!"
    exit 1
fi

echo "${GREEN}${BOLD}🚀 Orange Pi 5 Flash Tool 🚀${RESET}"
echo ""
info "Disk image: ${CYAN}$DISK_IMG${RESET}"
info "Remote server: ${CYAN}${REMOTE_USER}@${REMOTE_HOST}${RESET}"
info "Remote directory: ${CYAN}${REMOTE_DIR}${RESET}"
echo ""

# Step 1: Upload disk image
step "Uploading disk image"
info "Uploading ${DISK_IMG} to remote server..."
if scp "$DISK_IMG" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/"; then
    success "Successfully uploaded $(basename $DISK_IMG)"
else
    error "Failed to upload disk image"
    exit 1
fi

# Step 2: Check for Maskrom mode
step "Checking device status"
info "Checking if Orange Pi 5 is in Maskrom mode..."

check_maskrom() {
    ssh "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool ld" 2>/dev/null | grep -q "Maskrom"
}

# Wait for device to enter Maskrom mode
RETRY_COUNT=0
MAX_RETRIES=30  # Maximum 60 seconds (30 * 2 seconds)

while ! check_maskrom; do
    RETRY_COUNT=$((RETRY_COUNT + 1))
    if [ $RETRY_COUNT -gt $MAX_RETRIES ]; then
        error "Device not in Maskrom mode after ${MAX_RETRIES} attempts"
        error "Please put the Orange Pi 5 into Maskrom mode manually:"
        error "1. Power off the device"
        error "2. Hold the Maskrom button"
        error "3. Connect USB-C cable"
        error "4. Release the Maskrom button"
        exit 1
    fi
    
    warning "Device not in Maskrom mode (attempt $RETRY_COUNT/$MAX_RETRIES)"
    info "Waiting 2 seconds before retry..."
    sleep 2
done

success "Device is in Maskrom mode!"

# Show device info
info "Device information:"
ssh "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool ld"

# Step 3: Flash Miniloader
step "Flashing Miniloader"
info "Downloading bootloader ${MINILOADER}..."
if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool db ${MINILOADER}"; then
    success "Bootloader downloaded successfully"
else
    error "Failed to download bootloader"
    exit 1
fi

# # Step 4: Flash U-Boot
# step "Flashing U-Boot"
# info "Switching to SPI Flash (cs 9)..."
# if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool cs 9"; then
#     success "Switched to SPI Flash successfully"
# else
#     error "Failed to switch to SPI Flash"
#     exit 1
# fi

# info "Writing U-Boot ${UBOOT}..."
# if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool wl 0 ${UBOOT}"; then
#     success "U-Boot flashed successfully"
# else
#     error "Failed to flash U-Boot"
#     exit 1
# fi

# Step 5: Flash disk image
step "Flashing disk image"
info "Switching to eMMC (cs 1)..."
if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool cs 1"; then
    success "Switched to SD card successfully"
else
    error "Failed to switch to SD card"
    exit 1
fi

info "Writing disk image $(basename $DISK_IMG)..."
if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool wl 0 $(basename $DISK_IMG)"; then
    success "Disk image flashed successfully"
else
    error "Failed to flash disk image"
    exit 1
fi

# Step 6: Restart device
step "Restarting device"
info "Rebooting Orange Pi 5..."
if ssh -t "${REMOTE_USER}@${REMOTE_HOST}" "cd ${REMOTE_DIR}; sudo rkdeveloptool rd"; then
    success "Device restart command sent"
else
    warning "Failed to send restart command (device may have already rebooted)"
fi

echo ""
echo "${GREEN}${BOLD}🎉 FLASHING COMPLETED! 🎉${RESET}"
echo ""
success "Successfully flashed ${CYAN}$(basename $DISK_IMG)${RESET} to Orange Pi 5"
info "The device should now boot with your custom image"
echo ""
echo "${BOLD}Next steps:${RESET}"
echo "1. ${CYAN}Disconnect USB-C cable${RESET}"
echo "2. ${CYAN}Connect serial console (optional)${RESET}"
echo "3. ${CYAN}Power on the device${RESET}"
echo "4. ${CYAN}Check boot logs${RESET}"
#!/bin/bash

# Script to create a 64MB img file with FAT32 partition
# Author: Generated for creating FAT32 disk image
# Usage: make_disk.sh <IMG_FILE> <KERNEL_BIN>

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

# Check if we have the right number of arguments
if [ $# -ne 2 ]; then
    error "Invalid number of arguments"
    echo "Usage: $0 <IMG_FILE> <KERNEL_BIN>"
    echo "  IMG_FILE:   Name of the disk image file to create"
    echo "  KERNEL_BIN: Path to the kernel binary file to copy"
    exit 1
fi

IMG_FILE="$1"
KERNEL_BIN="$2"

ORANGEPI5_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
BOOT_CMD_FILE="${ORANGEPI5_DIR}/boot.cmd"
IMG_SIZE="64M"
MOUNT_POINT="/tmp/fat32_mount"

# Check if kernel binary exists
if [ ! -f "$KERNEL_BIN" ]; then
    error "Kernel binary file '$KERNEL_BIN' not found!"
    exit 1
fi

step "Creating 64MB disk image"

# Step 1: Create a 64MB image file
info "Creating ${IMG_SIZE} image file: ${IMG_FILE}"
dd if=/dev/zero of="$IMG_FILE" bs=1M count=64
success "Created $IMG_FILE (64MB)"

# Step 2: Create partition table and partition
step "Creating partition table"
# Use fdisk to create MBR partition table
(
echo o      # Create a new empty DOS partition table
echo n      # Add a new partition
echo p      # Primary partition
echo 1      # Partition number
echo        # First sector (Accept default: 2048)
echo        # Last sector (Accept default: varies)
echo t      # Change partition type
echo c      # Set type to W95 FAT32 (LBA)
echo w      # Write changes
) | fdisk "$IMG_FILE"

success "Partition table created"

# Step 3: Setup loop device for the partition
step "Setting up loop device"
LOOP_DEVICE=$(losetup --find --show "$IMG_FILE")
info "Loop device: ${CYAN}$LOOP_DEVICE${RESET}"

# Wait a moment for the loop device to be ready
sleep 1

# Get the partition device
PARTITION_DEVICE="${LOOP_DEVICE}p1"

# Check if partition device exists, if not try alternative naming
if [ ! -e "$PARTITION_DEVICE" ]; then
    # Force kernel to re-read partition table
    partprobe "$LOOP_DEVICE" 2>/dev/null || true
    sleep 1
    
    if [ ! -e "$PARTITION_DEVICE" ]; then
        warning "$PARTITION_DEVICE not found, trying alternative method..."
        # Use kpartx if available
        if command -v kpartx >/dev/null 2>&1; then
            kpartx -av "$LOOP_DEVICE"
            PARTITION_DEVICE="/dev/mapper/$(basename $LOOP_DEVICE)p1"
        else
            error "Cannot access partition device. Please install kpartx or check system setup."
            losetup -d "$LOOP_DEVICE"
            exit 1
        fi
    fi
fi

# Step 4: Format the partition as FAT32
step "Formatting partition"
info "Formatting ${PARTITION_DEVICE} as FAT32..."
mkfs.fat -F 32 -n "DISK64MB" "$PARTITION_DEVICE"
success "Partition formatted as FAT32"

# Step 5: Verify the filesystem
info "Verifying filesystem..."
fsck.fat -v "$PARTITION_DEVICE"

# Step 6: Test mount (optional)
step "Mounting filesystem"
mkdir -p "$MOUNT_POINT"
mount "$PARTITION_DEVICE" "$MOUNT_POINT"
success "Successfully mounted at ${CYAN}$MOUNT_POINT${RESET}"

# Show disk info
echo ""
info "Disk usage:"
df -h "$MOUNT_POINT"
echo ""
info "Disk image details:"
fdisk -l "$IMG_FILE"

# Compile boot.cmd to boot.scr using mkimage
info "Compiling boot.cmd to boot.scr..."
if command -v mkimage >/dev/null 2>&1; then
    mkimage -A arm -T script -C none -n "TF boot" -d "$BOOT_CMD_FILE" boot.scr
    success "Compiled boot.scr from $BOOT_CMD_FILE"
else
    error "mkimage not found. Please install u-boot-tools package."
    echo "On Ubuntu/Debian: sudo apt-get install u-boot-tools"
    exit 1
fi

# Copy files
step "Copying files to image"
info "Copying ${KERNEL_BIN} to kernel.bin..."
sudo cp "$KERNEL_BIN" "$MOUNT_POINT/kernel.bin"
info "Copying boot.scr..."
sudo cp boot.scr "$MOUNT_POINT/boot.scr"
success "Copied $KERNEL_BIN to kernel.bin and boot.scr to the image"

# Cleanup
step "Cleaning up"
info "Unmounting filesystem..."
sudo umount "$MOUNT_POINT"
rmdir "$MOUNT_POINT"

# Clean up kpartx mapping if used
if command -v kpartx >/dev/null 2>&1 && [[ "$PARTITION_DEVICE" =~ /dev/mapper/ ]]; then
    kpartx -dv "$LOOP_DEVICE"
fi

info "Detaching loop device..."
losetup -d "$LOOP_DEVICE"

# Clean up temporary files
info "Removing temporary files..."
rm -f boot.scr
success "Cleaned up temporary files"

echo ""
echo "${GREEN}${BOLD}🎉 SUCCESS! 🎉${RESET}"
success "Successfully created ${CYAN}$IMG_FILE${RESET} with FAT32 partition"
info "Image file size: ${YELLOW}$(du -h $IMG_FILE | cut -f1)${RESET}"
echo ""
echo "${BOLD}To mount the image later:${RESET}"
echo "  ${CYAN}sudo losetup /dev/loop0 $IMG_FILE${RESET}"
echo "  ${CYAN}sudo partprobe /dev/loop0${RESET}"
echo "  ${CYAN}sudo mount /dev/loop0p1 /mnt${RESET}"
echo ""
echo "${BOLD}To unmount:${RESET}"
echo "  ${CYAN}sudo umount /mnt${RESET}"
echo "  ${CYAN}sudo losetup -d /dev/loop0${RESET}"
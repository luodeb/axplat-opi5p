#!/bin/bash

# ==============================================
# 创建 sparse ext4 镜像并刷写内核脚本
# 适用于 Rockchip 平台
# ==============================================

set -e  # 遇到错误立即退出

# 配置参数
IMAGE_SIZE="64M"          # 镜像大小
MOUNT_POINT="/mnt/kernel_img"  # 挂载点
OUTPUT_IMAGE="kernel_sparse.img"  # 输出镜像文件名
KERNEL_SOURCE="starry-mix_aarch64-opi5p.uimg"  # 源内核文件
TARGET_PATH="/kernel.uimg"   # 镜像中的目标路径

# 颜色输出定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

# 检查依赖工具
check_dependencies() {
    local tools=("mkfs.ext4" "e2fsck" "resize2fs" "sudo")
    local missing=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing+=("$tool")
        fi
    done
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "缺少必要的工具: ${missing[*]}"
    fi
    info "所有依赖工具检查通过"
}

# 清理函数
cleanup() {
    if mountpoint -q "$MOUNT_POINT"; then
        info "卸载镜像..."
        sudo umount "$MOUNT_POINT" 2>/dev/null || true
    fi
    
    if [ -d "$MOUNT_POINT" ]; then
        sudo rmdir "$MOUNT_POINT" 2>/dev/null || true
    fi
}

# 注册清理函数
trap cleanup EXIT INT TERM

# 检查源文件是否存在
check_source_file() {
    if [ ! -f "$KERNEL_SOURCE" ]; then
        error "源内核文件 '$KERNEL_SOURCE' 不存在"
    fi
    info "找到内核文件: $(du -h "$KERNEL_SOURCE" | cut -f1)"
}

# 创建 sparse 镜像
create_sparse_image() {
    info "创建 sparse ext4 镜像 (大小: $IMAGE_SIZE)..."
    
    dd if=/dev/zero of="$OUTPUT_IMAGE" bs=1 count=0 seek="$IMAGE_SIZE" status=none
    mkfs.ext4 -F "$OUTPUT_IMAGE" > /dev/null
    info "使用 dd+mkfs.ext4 创建镜像"
    
    if [ ! -f "$OUTPUT_IMAGE" ]; then
        error "创建镜像失败"
    fi
    info "镜像创建成功: $(du -h "$OUTPUT_IMAGE" | cut -f1)"
}

# 挂载并复制文件
mount_and_copy() {
    info "创建挂载点..."
    sudo mkdir -p "$MOUNT_POINT"
    
    info "挂载镜像..."
    sudo mount -o loop "$OUTPUT_IMAGE" "$MOUNT_POINT"
    
    info "复制内核文件到镜像中..."
    sudo cp "$KERNEL_SOURCE" "${MOUNT_POINT}${TARGET_PATH}"

    sudo cp /home/debin/Codes/starry/starry-mix/module-local/axplat-opi5p/tools/orangepi5/rk3588-orangepi-5-plus.dtb "${MOUNT_POINT}/rk3588-orangepi-5-plus.dtb"
    
    # 检查文件是否复制成功
    if sudo [ -f "${MOUNT_POINT}${TARGET_PATH}" ]; then
        copied_size=$(sudo du -h "${MOUNT_POINT}${TARGET_PATH}" | cut -f1)
        info "文件复制成功: ${TARGET_PATH} (${copied_size})"
        sudo ls -al "${MOUNT_POINT}"
    else
        error "文件复制失败"
    fi
    
    info "卸载镜像..."
    sudo umount "$MOUNT_POINT"
    sudo rmdir "$MOUNT_POINT"
}

# 检查并优化镜像
check_and_optimize_image() {
    info "检查文件系统..."
    e2fsck -f -y "$OUTPUT_IMAGE" > /dev/null 2>&1 || warn "文件系统检查发现并修复了一些问题"
    
    info "调整文件系统大小以节省空间..."
    resize2fs -M "$OUTPUT_IMAGE" > /dev/null 2>&1
    
    final_size=$(du -h "$OUTPUT_IMAGE" | cut -f1)
    info "镜像最终大小: $final_size"
}

# 主执行流程
main() {
    echo "=========================================="
    echo "    Sparase Ext4 镜像创建与刷写工具"
    echo "=========================================="
    
    check_dependencies
    check_source_file
    
    # 清理之前的文件
    cleanup
    
    create_sparse_image
    mount_and_copy
    check_and_optimize_image
    
    echo "=========================================="
    echo "镜像准备完成: $OUTPUT_IMAGE"
    echo "包含文件: $TARGET_PATH"
    echo "=========================================="
    
    info "镜像已保存为: $OUTPUT_IMAGE"
    info "您可以使用以下命令手动刷写:"
    info "sudo rkdeveloptool wl $FLASH_OFFSET $OUTPUT_IMAGE"
    info "sudo rkdeveloptool rd"
}

# 执行主函数
main "$@"
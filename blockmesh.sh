#!/bin/bash

# 定义颜色代码和文本样式
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
RESET='\033[0m'  # 重置颜色

# 定义图标
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# 日志文件
LOG_FILE="installation.log"

# 信息显示函数
log_info() {
    echo -e "${BLUE}${INFO_ICON} $1${RESET}"
    echo "[INFO] $1" >> "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}${SUCCESS_ICON} $1${RESET}"
    echo "[SUCCESS] $1" >> "$LOG_FILE"
}

log_warning() {
    echo -e "${YELLOW}${WARNING_ICON} $1${RESET}"
    echo "[WARNING] $1" >> "$LOG_FILE"
}

log_error() {
    echo -e "${RED}${ERROR_ICON} $1${RESET}"
    echo "[ERROR] $1" >> "$LOG_FILE"
}

# 开始安装流程
log_info "显示 子清 logo..."
wget -O loader.sh https://raw.githubusercontent.com/DiscoverMyself/Ramanode-Guides/main/loader.sh && chmod +x loader.sh && ./loader.sh
curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash
sleep 2

log_info "更新系统软件包..."
apt update && apt upgrade -y

log_info "清理旧文件..."
rm -rf blockmesh-cli.tar.gz target

# 检查并安装 Docker
if ! command -v docker &> /dev/null
then
    log_info "Docker 未安装，正在安装 Docker..."
    apt-get install -y ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io
    log_success "Docker 安装成功。"
else
    log_warning "Docker 已安装，跳过安装..."
fi

# 安装 Docker Compose
log_info "安装 Docker Compose..."
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
log_success "Docker Compose 安装成功。"

# 下载并解压 BlockMesh CLI
log_info "下载并解压 BlockMesh CLI..."
curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.325/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
tar -xzf blockmesh-cli.tar.gz
log_success "BlockMesh CLI 下载并解压完成。"

# 用户输入
read -p "请输入您的 BlockMesh 邮箱: " email
read -s -p "请输入您的 BlockMesh 密码(密码不会在终端显示）: " password
echo

# 运行 Docker 容器
log_info "为 BlockMesh CLI 创建 Docker 容器..."
docker run -it --rm \
    --name blockmesh-cli-container \
    -v $(pwd)/target/release:/app \
    -e EMAIL="$email" \
    -e PASSWORD="$password" \
    --workdir /app \
    ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
log_success "BlockMesh CLI Docker 容器创建并运行成功。"

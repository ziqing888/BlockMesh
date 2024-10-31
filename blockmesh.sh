#!/bin/bash

# 自定义颜色和样式变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'  # 还原颜色

# 信息显示函数
log_info() { echo -e "${BLUE}ℹ️ ${1}${NC}"; }
log_success() { echo -e "${GREEN}✅ ${1}${NC}"; }
log_error() { echo -e "${RED}❌ ${1}${NC}"; }

# 初始化所有环境
initialize_environment() {
    clear
    log_info "显示 BlockMesh logo..."
    wget -O loader.sh https://raw.githubusercontent.com/DiscoverMyself/Ramanode-Guides/main/loader.sh && chmod +x loader.sh && ./loader.sh || {
        log_error "Failed to load loader.sh."
    }
    curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash || {
        log_error "Failed to load BlockMesh logo."
    }
    sleep 2

    # 系统更新
    log_info "更新系统..."
    apt update && apt upgrade -y

    # 清理旧文件
    log_info "清理旧文件..."
    rm -rf blockmesh-cli.tar.gz target

    # 安装 Docker
    log_info "检查 Docker 是否已安装..."
    if ! command -v docker &> /dev/null; then
        log_info "安装 Docker..."
        apt-get install -y ca-certificates curl gnupg lsb-release
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io
        log_success "Docker 安装完成。"
    else
        log_success "Docker 已安装，跳过..."
    fi

    # 安装 Docker Compose
    log_info "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose

    # 下载和解压 BlockMesh CLI 到 target/release
    log_info "下载并解压 BlockMesh CLI..."
    mkdir -p target/release
    curl -L https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.316/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -o blockmesh-cli.tar.gz
    tar -xzf blockmesh-cli.tar.gz -C target/release
    rm -f blockmesh-cli.tar.gz
    log_success "BlockMesh CLI 下载并解压完成。"
}

# 用户输入
get_user_credentials() {
    read -p "请输入您的 BlockMesh 邮箱: " email
    echo "请输入您的 BlockMesh 密码（输入时不会显示在终端）:"
    read -s -p "密码: " password
    echo
}

# 运行 Docker 容器
run_docker_container() {
    log_info "为 BlockMesh CLI 创建 Docker 容器..."

    # 检查是否存在同名的正在运行的容器
    if [ "$(docker ps -aq -f name=blockmesh-cli-container)" ]; then
        docker rm -f blockmesh-cli-container
    fi

    # 启动新容器
    docker run -it --rm \
        --name blockmesh-cli-container \
        -v $(pwd)/target/release:/app \
        -e EMAIL="$email" \
        -e PASSWORD="$password" \
        --workdir /app \
        ubuntu:22.04 ./blockmesh-cli --email "$email" --password "$password"
    
    if [ $? -ne 0 ]; then
        log_error "Docker 容器启动失败，请检查 Docker 是否正常运行。"
        exit 1
    fi
    log_success "Docker 容器已成功运行 BlockMesh CLI。"
}

# 主循环显示 BlockMesh logo
show_menu() {
    clear
    # 加载 BlockMesh logo
    curl -s https://raw.githubusercontent.com/ziqing888/logo.sh/refs/heads/main/logo.sh | bash || {
        log_warning "无法加载 BlockMesh Logo，请检查网络连接。"
    }
    echo

    # 显示方框菜单
    echo -e "${YELLOW}${BOLD}╔════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}${BOLD}║           🚀 BlockMesh CLI 菜单        ║${NC}"
    echo -e "${YELLOW}${BOLD}╠════════════════════════════════════════╣${NC}"
    echo -e "${YELLOW}${BOLD}║ ${BLUE}1)${NC}${YELLOW} 初始化环境                        ${YELLOW}║${NC}"
    echo -e "${YELLOW}${BOLD}║ ${BLUE}2)${NC}${YELLOW} 输入登录信息                      ${YELLOW}║${NC}"
    echo -e "${YELLOW}${BOLD}║ ${BLUE}3)${NC}${YELLOW} 启动 BlockMesh                    ${YELLOW}║${NC}"
    echo -e "${YELLOW}${BOLD}║ ${BLUE}4)${NC}${YELLOW} 退出                              ${YELLOW}║${NC}"
    echo -e "${YELLOW}${BOLD}╚════════════════════════════════════════╝${NC}"
}

# 主循环
while true; do
    show_menu
    read -p "请输入您的选择: " choice
    case $choice in
        1) initialize_environment ;;
        2) get_user_credentials ;;
        3) 
            if [[ -z "$email" || -z "$password" ]]; then
                log_error "请先输入登录信息 (选项 2)。"
            else
                run_docker_container
            fi
            ;;
        4) log_info "退出脚本"; break ;;
        *) log_error "无效的选择，请重试。" ;;
    esac
done

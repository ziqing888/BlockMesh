#!/bin/bash

clear  # 清除屏幕

# 颜色代码和文本样式变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
UNDERLINE='\033[4m'
NC='\033[0m'

# 图标定义
INFO_ICON="ℹ️"
SUCCESS_ICON="✅"
WARNING_ICON="⚠️"
ERROR_ICON="❌"

# 信息显示函数
log_info() { echo -e "${BLUE}${INFO_ICON} ${1}${NC}"; }
log_success() { echo -e "${GREEN}${SUCCESS_ICON} ${1}${NC}"; }
log_warning() { echo -e "${YELLOW}${WARNING_ICON} ${1}${NC}"; }
log_error() { echo -e "${RED}${ERROR_ICON} ${1}${NC}"; }

INSTALL_DIR="$HOME/blockmesh"
mkdir -p "$INSTALL_DIR"

initialize_setup() {
    log_info "开始系统更新和依赖安装..."
    sudo apt update && sudo apt upgrade -y
    
    if ! command -v screen &> /dev/null; then
        sudo apt install -y screen
    fi
    log_success "系统更新和依赖安装完成。"

    log_info "下载 Blockmesh CLI..."
    if ! wget -q -O "$INSTALL_DIR/blockmesh-cli.tar.gz" https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz; then
        log_error "下载失败，请检查网络连接。"
        return
    fi

    log_info "解压 Blockmesh CLI..."
    tar -xvzf "$INSTALL_DIR/blockmesh-cli.tar.gz" -C "$INSTALL_DIR"
    rm -f "$INSTALL_DIR/blockmesh-cli.tar.gz"

    log_info "添加 Blockmesh 到 PATH..."
    echo 'export PATH="$PATH:'"$INSTALL_DIR"'/target/release"' >> ~/.bashrc
    source ~/.bashrc
    log_success "初始化完成。"
}

cleanup_existing_sessions() {
    log_info "检查并清理多余的 Blockmesh 会话..."
    # 退出所有名为 "Blockmesh" 的会话
    screen -list | grep "Blockmesh" | awk '{print $1}' | xargs -r -n 1 screen -S {} -X quit
    log_success "已清理所有与 Blockmesh 项目相关的会话。"
}

start_blockmesh_client() {
    cleanup_existing_sessions

    read -p "请输入您的邮箱: " user_email
    if [[ -z "$user_email" ]]; then
        log_error "邮箱不能为空。"
        return
    fi

    read -sp "请输入您的密码: " user_password
    echo
    if [[ -z "$user_password" ]]; then
        log_error "密码不能为空。"
        return
    fi

    screen -dmS Blockmesh blockmesh-cli login --email "$user_email" --password "$user_password"
    sleep 2

    if screen -list | grep -q "Blockmesh"; then
        log_success "Blockmesh 客户端已成功启动并在后台运行。"
    else
        log_error "启动 Blockmesh 客户端失败，请检查邮箱和密码是否正确。"
    fi
}

view_logs_in_screen() {
    sessions=$(screen -list | grep "Blockmesh")
    if [[ -n "$sessions" ]]; then
        log_info "检测到以下 Blockmesh 会话："
        echo "$sessions"
        
        # 自动选择最新的会话
        latest_session=$(echo "$sessions" | awk '{print $1}' | head -n 1)
        read -p "按回车自动进入最新会话 [$latest_session]，或输入其他会话ID以恢复： " session_id
        session_id=${session_id:-$latest_session}  # 如果用户输入为空，则使用最新会话ID

        log_info "进入 Blockmesh 屏幕会话以查看日志。按 CTRL+A 然后 D 来退出会话。"
        screen -r "$session_id"
    else
        log_warning "Blockmesh 客户端未运行，无法查看日志。请先启动客户端。"
    fi
}

while true; do
    echo -e "${BOLD}请选择一个选项：${NC}"
    echo "1) 初始化系统并安装 Blockmesh"
    echo "2) 启动 Blockmesh 客户端"
    echo "3) 进入 Blockmesh 屏幕会话查看日志"
    echo "4) 退出脚本"
    read -p "请输入您的选择: " choice

    case $choice in
        1) initialize_setup ;;
        2) start_blockmesh_client ;;
        3) view_logs_in_screen ;;
        4) log_info "退出脚本"; break ;;
        *) log_warning "无效的选择，请重试。" ;;
    esac
done


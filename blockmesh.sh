#!/bin/bash

# 函数：初始化安装与配置
initialize_setup() {
    echo "开始系统更新和依赖安装..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y screen
    echo "系统更新和依赖安装完成。"

    echo "下载 Blockmesh CLI..."
    wget https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz
    echo "解压 Blockmesh CLI..."
    tar -xvzf blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz

    echo "添加 Blockmesh 到 PATH..."
    echo 'export PATH="$PATH:~/target/release"' >> ~/.bashrc
    source ~/.bashrc
    echo "初始化完成。"
}

# 函数：清理已有的 Blockmesh 会话
cleanup_existing_sessions() {
    echo "检查并清理多余的 Blockmesh 会话..."
    screen -list | grep "Blockmesh" | awk '{print $1}' | xargs -r -n 1 screen -S {} -X quit
    echo "已清理所有多余的 Blockmesh 会话。"
}

# 函数：启动 Blockmesh 客户端
start_blockmesh_client() {
    # 清理之前的会话，确保只有一个会话
    cleanup_existing_sessions

    # 启动新的会话
    read -p "请输入您的邮箱: " user_email
    read -sp "请输入您的密码: " user_password
    echo
    screen -dmS Blockmesh blockmesh-cli login --email "$user_email" --password "$user_password"
    sleep 2  # 等待 2 秒以确保客户端启动

    # 检查是否成功启动
    if screen -list | grep -q "Blockmesh"; then
        echo "Blockmesh 客户端已成功启动并在后台运行。"
    else
        echo "启动 Blockmesh 客户端失败，请检查邮箱和密码是否正确。"
    fi
}

# 显示菜单
while true; do
    echo "请选择一个选项："
    echo "1) 初始化系统并安装 Blockmesh"
    echo "2) 启动 Blockmesh 客户端"
    echo "3) 退出脚本"
    read -p "请输入您的选择: " choice

    case $choice in
        1) initialize_setup ;;
        2) start_blockmesh_client ;;
        3) echo "退出脚本"; break ;;
        *) echo "无效的选择，请重试。" ;;
    esac
done

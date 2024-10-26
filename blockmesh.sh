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

# 函数：启动 Blockmesh 客户端
start_blockmesh_client() {
    read -p "请输入您的邮箱: " user_email
    read -sp "请输入您的密码: " user_password
    echo
    screen -dmS Blockmesh blockmesh-cli login --email "$user_email" --password "$user_password"
    echo "Blockmesh 客户端已在后台运行。"
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

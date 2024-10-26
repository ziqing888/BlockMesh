#!/bin/bash

# 初始化邮箱和密码变量
USER_EMAIL=""
USER_PASSWORD=""

# 定义一个函数，用于输入邮箱和密码
function input_credentials() {
    read -p "请输入您的邮箱: " USER_EMAIL
    read -sp "请输入您的密码 (包含特殊字符): " USER_PASSWORD
    echo
}

# 更新系统
echo "正在更新系统..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt update && sudo apt upgrade -y
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew update && brew upgrade
else
    echo "该脚本仅支持 Linux 和 macOS 系统"
    exit 1
fi

# 安装 screen
echo "正在安装 screen..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sudo apt install -y screen
elif [[ "$OSTYPE" == "darwin"* ]]; then
    brew install screen
fi

# 下载 Blockmesh CLI
echo "正在下载 Blockmesh CLI..."
wget -q https://github.com/block-mesh/block-mesh-monorepo/releases/download/v0.0.307/blockmesh-cli-x86_64-unknown-linux-gnu.tar.gz -O blockmesh-cli.tar.gz

# 解压 Blockmesh CLI
echo "正在解压 Blockmesh CLI..."
tar -xvzf blockmesh-cli.tar.gz -C $HOME
rm blockmesh-cli.tar.gz

# 添加 Blockmesh 路径
echo "正在添加 Blockmesh 路径..."
if [[ "$SHELL" == *"/zsh"* ]]; then
    SHELL_PROFILE="$HOME/.zshrc"
else
    SHELL_PROFILE="$HOME/.bashrc"
fi
echo 'export PATH="$PATH:$HOME/target/release"' >> "$SHELL_PROFILE"
source "$SHELL_PROFILE"

# 创建 Blockmesh screen 会话
echo "正在创建 Blockmesh screen 会话..."
screen -dmS Blockmesh

# 交互菜单
while true; do
    echo
    echo "Blockmesh 配置和管理菜单，请选择一个操作："
    echo "1. 填写或更新登录信息"
    echo "2. 登录 Blockmesh 客户端"
    echo "3. 查看 Blockmesh 日志"
    echo "4. 分离 Blockmesh screen 会话"
    echo "5. 退出脚本"
    read -p "请输入选项编号 (1/2/3/4/5): " choice

    case $choice in
        1)
            echo "填写或更新登录信息..."
            input_credentials
            ;;
        2)
            if [[ -z "$USER_EMAIL" || -z "$USER_PASSWORD" ]]; then
                echo "请先选择选项 1 填写登录信息。"
            else
                echo "正在登录 Blockmesh 客户端..."
                $HOME/target/release/blockmesh-cli login --email "$USER_EMAIL" --password "$USER_PASSWORD" &> login_output.log
                if [[ $? -ne 0 ]]; then
                    echo "登录失败。请检查您的邮箱和密码，或在 https://app.blockmesh.xyz/register 确认账户状态。"
                else
                    clear
                    echo "成功登录！"
                    read -n 1 -s -r -p "按任意键返回主菜单..."
                fi
            fi
            ;;
        3)
            echo "显示 Blockmesh 日志..."
            screen -r Blockmesh
            ;;
        4)
            echo "分离 Blockmesh screen 会话中，请使用 CTRL+A+D 组合键..."
            ;;
        5)
            echo "退出脚本。"
            break
            ;;
        *)
            echo "无效选项，请重新输入。"
            ;;
    esac
done


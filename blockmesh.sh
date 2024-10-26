#!/bin/bash

# 检查是否为 root 用户
if [[ $EUID -ne 0 ]]; then
   echo "请使用 root 权限执行此脚本"
   exit 1
fi

# 提示用户输入邮箱和密码
read -p "请输入您的邮箱: " USER_EMAIL
read -sp "请输入您的密码 (包含特殊字符): " USER_PASSWORD
echo

# 打开注册页面，让用户手动完成注册
echo "正在打开注册页面，请在浏览器中完成注册..."
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    xdg-open "https://app.blockmesh.xyz/register?invite_code=16c1d8f0-5523-40ef-9b0f-6f3bb335d792"
elif [[ "$OSTYPE" == "darwin"* ]]; then
    open "https://app.blockmesh.xyz/register?invite_code=16c1d8f0-5523-40ef-9b0f-6f3bb335d792"
else
    echo "无法自动打开浏览器，请手动访问以下链接完成注册："
    echo "https://app.blockmesh.xyz/register?invite_code=16c1d8f0-5523-40ef-9b0f-6f3bb335d792"
fi

# 等待用户完成注册
read -p "请在浏览器中完成注册，然后按回车键继续..."

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

# 登录 Blockmesh 客户端
echo "正在登录 Blockmesh 客户端..."
$HOME/target/release/blockmesh-cli login --email "$USER_EMAIL" --password "$USER_PASSWORD"
if [[ $? -ne 0 ]]; then
    echo "登录失败。请检查您的邮箱和密码，或在 https://app.blockmesh.xyz/register 确认账户状态。"
    exit 1
fi

echo "Blockmesh 安装与配置完成！您可以使用 'screen -r Blockmesh' 查看日志。"
echo "请确保退出 VPS 前使用 CTRL+A+D 组合键分离屏幕。"

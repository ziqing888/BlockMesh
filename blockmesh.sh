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

# 询问是否有邀请码
read -p "您有邀请码吗？输入 'y' 填写邀请码，或输入 'n' 跳过: " has_invite_code
if [[ "$has_invite_code" == "y" || "$has_invite_code" == "Y" ]]; then
    read -p "请输入邀请码: " INVITE_CODE
else
    INVITE_CODE=""
fi

# 选择注册或登录
read -p "您是新用户吗？输入 'y' 注册新账户，或输入 'n' 直接登录: " is_new_user

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

# 注册或登录
if [[ "$is_new_user" == "y" || "$is_new_user" == "Y" ]]; then
    echo "正在注册新账户..."
    if [[ -n "$INVITE_CODE" ]]; then
        register_output=$($HOME/target/release/blockmesh-cli register --email "$USER_EMAIL" --password "$USER_PASSWORD" --invite "$INVITE_CODE" 2>&1)
    else
        register_output=$($HOME/target/release/blockmesh-cli register --email "$USER_EMAIL" --password "$USER_PASSWORD" 2>&1)
    fi
    if echo "$register_output" | grep -q "User with this email already exists"; then
        echo "用户已存在，跳过注册。"
    elif [[ $? -ne 0 ]]; then
        echo "注册失败，请检查输入信息或尝试直接登录。"
    fi
fi

# 登录 Blockmesh 客户端
echo "正在登录 Blockmesh 客户端..."
$HOME/target/release/blockmesh-cli login --email "$USER_EMAIL" --password "$USER_PASSWORD"
if [[ $? -ne 0 ]]; then
    echo "登录失败。请检查您的邮箱和密码，或在 https://app.blockmesh.xyz/register 确认账户状态。"
    exit 1
fi

echo "Blockmesh 安装与配置完成！您可以使用 'screen -r Blockmesh' 查看日志。"
echo "请确保退出 VPS 前使用 CTRL+A+D 组合键分离屏幕。"


#!/bin/sh

# 无论如何退出，最后都删除自身
trap 'rm -f "$0"' EXIT

# 检测CPU架构
echo "正在检测架构..."
ARCH=$(uname -m)
if echo "$ARCH" | grep -q "aarch64"; then
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
elif echo "$ARCH" | grep -q "armv7\|armv8"; then
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm"
elif echo "$ARCH" | grep -q "x86_64"; then
    URL="https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64"
else
    echo "不支持的架构: $ARCH"
    exit 1
fi

# 下载程序
echo "下载中..."
wget -qO /usr/bin/cloudflared "$URL"
chmod +x /usr/bin/cloudflared

# 输入Token
echo ""
echo "请输入Cloudflare Tunnel Token："
read -r TOKEN
if [ -z "$TOKEN" ]; then
    echo "Token不能为空"
    exit 1
fi

# 生成自启服务
cat > /etc/init.d/cloudflared << EOF
#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1
PROG=/usr/bin/cloudflared

start_service() {
    procd_open_instance
    procd_set_param command \$PROG tunnel run --token $TOKEN
    procd_set_param respawn
    procd_close_instance
}
EOF

chmod +x /etc/init.d/cloudflared
/etc/init.d/cloudflared enable
/etc/init.d/cloudflared start

echo ""
echo "安装完成！状态："
/etc/init.d/cloudflared status

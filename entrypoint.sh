#!/bin/sh
set -e

# ==========================================
# 1. 定义环境变量及默认值
# ==========================================
# 如果运行容器时没有传入这些变量，将使用这里的默认值
# 默认值与你提供的配置文件保持一致
UUID="${UUID:-588db1b3-0b3f-48d9-98a2-c5574415a400}"
PORT="${PORT:-8080}"
WS_PATH="${WS_PATH:-/chat}"
LISTEN_ADDR="${LISTEN_ADDR:-0.0.0.0}"
SNIFF="${SNIFF:-true}"
SNIFF_OVERRIDE="${SNIFF_OVERRIDE:-true}"
LOG_LEVEL="${LOG_LEVEL:-info}"

CONFIG_FILE="/app/config.json"

# ==========================================
# 2. 动态生成配置文件
# ==========================================
echo "[Init] Generating sing-box configuration..."

# 使用 cat 和 heredoc 生成 JSON。
# 注意：JSON 中的布尔值和数字不需要引号，字符串需要引号。
# 我们在 Shell 变量中直接嵌入这些值。
cat > "$CONFIG_FILE" <<EOF
{
  "log": {
    "level": "$LOG_LEVEL",
    "timestamp": true
  },
  "inbounds": [
    {
      "type": "vless",
      "tag": "vless-ws-in",
      "listen": "$LISTEN_ADDR",
      "listen_port": $PORT,
      "sniff": $SNIFF,
      "sniff_override_destination": $SNIFF_OVERRIDE,
      "users": [
        {
          "uuid": "$UUID",
          "name": "user1"
        }
      ],
      "transport": {
        "type": "ws",
        "path": "$WS_PATH",
        "max_early_data": 2048,
        "early_data_header_name": "Sec-WebSocket-Protocol"
      }
    }
  ],
  "outbounds": [
    {
      "type": "direct",
      "tag": "direct"
    }
  ]
}
EOF

# 验证配置文件是否生成成功
if [ ! -f "$CONFIG_FILE" ]; then
    echo "[Error] Failed to create config file at $CONFIG_FILE"
    exit 1
fi

echo "[Init] Config generated successfully. Starting sing-box..."

# ==========================================
# 3. 启动 Sing-box
# ==========================================
# 【关键】使用 exec 替换当前 shell 进程
# 这样 sing-box 就变成了 PID 1，Docker/K8s 可以直接向其发送信号
exec "$@"

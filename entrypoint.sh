#!/bin/sh
set -euo pipefail

# 要下载的 raw 文件 URL（默认指向你的仓库 main 分支）
RAW_URL="${DENOTS_RAW_URL:-https://raw.githubusercontent.com/rakersfu/sing-box/main/config.json}"
# 代理其它网站
#RAW_URL="${DENOTS_RAW_URL:-https://raw.githubusercontent.com/rakersfu/sing-box/main/config_a.json}"
# 可选：传入期望的 sha256 值以防止被意外改动
EXPECTED_SHA256="${DENOTS_SHA256:-}"

TMP="$(mktemp /tmp/config.json.XXXXXX)"
cleanup() { [ -f "$TMP" ] && rm -f "$TMP"; }
trap cleanup EXIT

echo "Downloading deno.ts from: $RAW_URL"
if ! curl -fsSL "$RAW_URL" -o "$TMP"; then
  echo "Failed to download $RAW_URL" >&2
  exit 1
fi

if [ -n "$EXPECTED_SHA256" ]; then
  echo "${EXPECTED_SHA256}  ${TMP}" | sha256sum -c - || {
    echo "sha256 mismatch for downloaded deno.ts" >&2
    exit 1
  }
fi

# 原子替换目标文件
mv "$TMP" /app/config.json
chmod 644 /app/config.json
echo "Updated /app/config.json"

# 最后 exec 启动 sing-box
exec sing-box run -c config.json

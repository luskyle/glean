#!/usr/bin/env bash
# 拾忆 Linux 桌面快速启动（debug 版）
# 使用前需先构建：flutter build linux --debug
# 构建产物落在 build/ 下（不入库），首次启动需完成后台组装步骤。
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST="$ROOT/build/linux/x64/debug/dist"

if [ ! -x "$DIST/shiyi" ]; then
  echo "未找到构建产物，请先执行："
  echo "  cd $ROOT"
  echo "  flutter build linux --debug"
  echo "  然后 cmake --install 到 $DIST（或参考 README）"
  exit 1
fi

export DISPLAY="${DISPLAY:-:0}"
# 无 GPU/vsync 会话下强制软件渲染，避免 EGL 初始化警告
export LIBGL_ALWAYS_SOFTWARE=1
cd "$DIST"
exec ./shiyi "$@"
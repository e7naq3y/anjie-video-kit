#!/bin/bash
# 安杰视频工具包 · Mac 一键安装
#
# 适用于全新的空白 Mac：不需要 Homebrew、不需要 git、不需要 Xcode、不需要管理员密码。
# 所有软件都以独立程序的形式装进 ~/.video-kit/，不改动系统目录；可以反复运行，已装好的会跳过。
# AI 工具执行命令时没有可以输入密码的终端，所以这里刻意避开一切需要 sudo 的安装方式。
#
# 用法：bash bootstrap-mac.sh
# 兼容 macOS 自带的 bash 3.2，不要使用 bash 4 以上的语法。

set -u
KIT="$HOME/.video-kit"
BIN="$KIT/bin"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$BIN"
export PATH="$BIN:$KIT/npm-global/bin:$KIT/node/bin:$PATH"

# 与 Meet U 视频工作室锁定的 HyperFrames 版本保持一致
HF_RELEASE=https://github.com/e7naq3y/meetu-video-studio/releases/download/v0.8.137-meetu.2
HF_PKG="$HF_RELEASE/meetu-hyperframes-0.8.137-meetu.2.tgz"
FF_RELEASE=https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1
CHROME_VERSION=152.0.7977.30

FAILED=0
step() { printf '\n▶ %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
bad() { printf '  ✗ %s\n' "$*"; FAILED=1; }
dl() { curl -fL --retry 3 --connect-timeout 20 --max-time 1800 -s -S -o "$2" "$1"; }

echo "🎬 安杰视频工具包 · Mac 一键安装（安杰出品）"

ARCH=$(uname -m)                                   # arm64 = M 系列芯片，x86_64 = Intel
OS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
if [ "$ARCH" = "arm64" ]; then NODE_ARCH=arm64; FF_ARCH=arm64; CR_PLAT=mac-arm64; else NODE_ARCH=x64; FF_ARCH=x64; CR_PLAT=mac-x64; fi
if [ "$OS_MAJOR" -lt 11 ]; then
  echo "  ✗ 这台 Mac 的系统是 macOS $(sw_vers -productVersion)，太旧了（至少需要 macOS 11）。请先升级系统。"
  exit 1
fi
# macOS 12 跑不了新版 Chrome，HyperFrames 对它固定用 150 版
if [ "$OS_MAJOR" -le 12 ]; then CHROME_VERSION=150.0.7871.124; fi

# ---------- Node.js ----------
step "Node.js（运行 HyperFrames 需要）"
node_ok() { command -v node >/dev/null 2>&1 && [ "$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)" -ge 22 ]; }
if node_ok; then
  ok "已就绪：$(node -v)"
else
  NV=$(curl -s --max-time 30 https://nodejs.org/dist/index.json | grep -o '"version":"v22\.[0-9.]*"' | head -1 | cut -d'"' -f4)
  [ -z "$NV" ] && NV=v22.23.3
  if dl "https://nodejs.org/dist/$NV/node-$NV-darwin-$NODE_ARCH.tar.gz" "$KIT/node.tgz"; then
    rm -rf "$KIT/node" && mkdir -p "$KIT/node" && tar xzf "$KIT/node.tgz" -C "$KIT/node" --strip-components 1 && rm -f "$KIT/node.tgz"
    if node_ok; then ok "已安装：$(node -v)"; else bad "Node.js 解压后无法运行"; fi
  else
    bad "Node.js 下载失败"
  fi
fi

# ---------- FFmpeg ----------
step "FFmpeg（视频编码需要）"
for tool in ffmpeg ffprobe; do
  if command -v "$tool" >/dev/null 2>&1 && "$tool" -version >/dev/null 2>&1; then
    ok "$tool 已就绪"
    continue
  fi
  if dl "$FF_RELEASE/$tool-darwin-$FF_ARCH.gz" "$BIN/$tool.gz"; then
    gunzip -f "$BIN/$tool.gz" && chmod +x "$BIN/$tool"
    if "$BIN/$tool" -version >/dev/null 2>&1; then ok "$tool 已安装"; else bad "$tool 无法运行"; fi
  else
    bad "$tool 下载失败"
  fi
done

# ---------- uv（用来装 Python 和配音组件，它自己不需要 Python） ----------
step "uv（Python 环境管理）"
if command -v uv >/dev/null 2>&1; then
  ok "已就绪：$(uv --version)"
else
  curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR="$BIN" UV_NO_MODIFY_PATH=1 sh >/dev/null 2>&1
  if command -v uv >/dev/null 2>&1; then ok "已安装：$(uv --version)"; else bad "uv 安装失败"; fi
fi

# ---------- Python + edge-tts 中文配音 ----------
step "中文 AI 配音（edge-tts）"
VENV_PY="$KIT/venv/bin/python"
if [ -x "$VENV_PY" ] && "$VENV_PY" -c "import edge_tts" >/dev/null 2>&1; then
  ok "已就绪"
elif command -v uv >/dev/null 2>&1; then
  export UV_PYTHON_INSTALL_DIR="$KIT/python"
  # only-managed：不用系统自带的 python3（空白 Mac 上它是占位程序，一运行就弹窗要求装 Xcode 命令行工具）
  uv venv "$KIT/venv" --python 3.12 --python-preference only-managed --clear >/dev/null 2>&1
  uv pip install --python "$VENV_PY" edge-tts >/dev/null 2>&1
  if "$VENV_PY" -c "import edge_tts" >/dev/null 2>&1; then ok "已安装"; else bad "edge-tts 安装失败"; fi
else
  bad "缺少 uv，无法安装配音组件"
fi

# ---------- 渲染用的无头 Chrome ----------
step "渲染用浏览器（Chrome Headless Shell）"
CR_EXE="$KIT/chrome/$CHROME_VERSION/chrome-headless-shell-$CR_PLAT/chrome-headless-shell"
if [ -x "$CR_EXE" ]; then
  ok "已就绪"
elif dl "https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION/$CR_PLAT/chrome-headless-shell-$CR_PLAT.zip" "$KIT/chrome.zip"; then
  mkdir -p "$KIT/chrome/$CHROME_VERSION" && unzip -q -o "$KIT/chrome.zip" -d "$KIT/chrome/$CHROME_VERSION" && rm -f "$KIT/chrome.zip"
  if [ -x "$CR_EXE" ]; then ok "已安装"; else bad "浏览器解压后找不到程序"; fi
else
  bad "浏览器下载失败"
fi
# hf.mjs 读这个文件，通过 HYPERFRAMES_BROWSER_PATH 让 HyperFrames 直接用它
[ -x "$CR_EXE" ] && printf '%s' "$CR_EXE" > "$KIT/chrome-path.txt"

# ---------- HyperFrames skills ----------
# 官方的 `hyperframes skills` 依赖 git，空白 Mac 没有 git，所以直接下载打包好的 skills 解压。
# Claude Code 读 ~/.claude/skills，Codex 读 ~/.agents/skills，两处都装，换工具也能用。
step "HyperFrames skills（给 AI 用的视频制作说明）"
if dl "$HF_RELEASE/hyperframes-skills-0.8.137.zip" "$KIT/hf-skills.zip"; then
  rm -rf "$KIT/hf-skills" && mkdir -p "$KIT/hf-skills" && unzip -q -o "$KIT/hf-skills.zip" -d "$KIT/hf-skills" && rm -f "$KIT/hf-skills.zip"
  for dest in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
    mkdir -p "$dest"
    for s in "$KIT/hf-skills"/*/; do
      name=$(basename "$s")
      rm -rf "$dest/$name" && cp -R "$s" "$dest/$name"
    done
  done
  COUNT=$(ls -d "$HOME/.claude/skills"/*/SKILL.md 2>/dev/null | wc -l | tr -d ' ')
  if [ -f "$HOME/.claude/skills/hyperframes/SKILL.md" ] && [ -f "$HOME/.agents/skills/hyperframes/SKILL.md" ]; then
    ok "已安装到 Claude 和 Codex（共 $(ls "$KIT/hf-skills" | grep -vc LICENSE) 个）"
  else
    bad "解压后找不到 skills"
  fi
else
  bad "skills 下载失败"
fi

# ---------- Meet U 视频工作室：装成本机的 hyperframes 命令 ----------
# 装成全局命令后，不管是 AI 照 HyperFrames 文档运行 `hyperframes ...`，还是项目里的 npm run dev，
# 打开的都是汉化版。--prefix 装在用户目录，不需要管理员权限。
step "Meet U 视频工作室（中文编辑器）"
NPMG="$KIT/npm-global"
if [ -f "$NPMG/lib/node_modules/hyperframes/NOTICE-MEETU.md" ] && grep -q '"0.8.137-meetu.2"' "$NPMG/lib/node_modules/hyperframes/package.json" 2>/dev/null; then
  ok "已就绪"
elif command -v npm >/dev/null 2>&1; then
  npm install -g --prefix "$NPMG" "$HF_PKG" > "$KIT/meetu-install.log" 2>&1
  if [ -x "$NPMG/bin/hyperframes" ] && [ -f "$NPMG/lib/node_modules/hyperframes/NOTICE-MEETU.md" ]; then
    ok "已安装为 hyperframes 命令"
  else
    bad "安装失败，日志：$KIT/meetu-install.log"
  fi
else
  bad "缺少 Node.js，无法安装"
fi

# ---------- 写入 PATH，以后新开的终端和 AI 工具都能直接找到 ----------
step "配置环境变量"
MARK="# >>> 安杰视频工具包 >>>"
for rc in "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.bash_profile"; do
  touch "$rc"
  if ! grep -q "$MARK" "$rc"; then
    printf '\n%s\nexport PATH="$HOME/.video-kit/bin:$HOME/.video-kit/npm-global/bin:$HOME/.video-kit/node/bin:$PATH"\n# <<< 安杰视频工具包 <<<\n' "$MARK" >> "$rc"
  fi
done
ok "已写入 ~/.zprofile、~/.zshrc、~/.bash_profile"

# ---------- 体检 ----------
step "最终体检"
if command -v node >/dev/null 2>&1; then
  node "$SKILL_DIR/scripts/check_env.mjs" || FAILED=1
fi

echo
if [ $FAILED = 0 ]; then
  echo "✅ 安装完成！请完全退出 Claude / Codex 再重新打开，然后就可以开始做视频了。"
else
  echo "⚠️ 有项目没装好，请看上面带 ✗ 的行。多数是网络波动，重新运行本脚本即可（已装好的会自动跳过）。"
  exit 1
fi

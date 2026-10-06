# 安装排查手册

正常情况下，按 `INSTALL.md` 运行一键安装脚本就够了（Mac：`scripts/bootstrap-mac.sh`，Windows：`scripts/bootstrap-windows.ps1`）。这份手册只在脚本某一项反复失败时查阅。

## 总体原则

- 所有组件都装在用户目录 `~/.video-kit/` 下（Windows 是 `%USERPROFILE%\.video-kit\`），**不需要管理员密码**。
- 不要改用 Homebrew、winget、`sudo`、"以管理员身份运行"：AI 执行命令时没有地方输入密码或确认弹窗，一定会卡住。
- 在空白 Mac 上**不要运行** `git`、`python3`、`clang` 等命令：系统自带的这些只是占位程序，一运行就会弹窗要求安装 Xcode 命令行工具，而安装需要密码。
- 脚本可以反复运行，已经装好的会跳过。所以排查完一项，直接重新运行整个脚本最省事。

## 各组件说明

| 组件 | 安装位置 | 下载来源 | 怎么确认装好了 |
|---|---|---|---|
| Node.js 22 | `.video-kit/node/` | nodejs.org 官方压缩包 | `node -v` 输出 v22 及以上 |
| FFmpeg / FFprobe | `.video-kit/bin/` | GitHub：eugeneware/ffmpeg-static 的 b6.1.1 版本（单文件程序） | `ffmpeg -version` |
| uv | `.video-kit/bin/` | astral.sh 官方安装程序 | `uv --version` |
| Python 3.12 + edge-tts | `.video-kit/python/` 和 `.video-kit/venv/` | 由 uv 下载独立版 Python，再从 PyPI 装 edge-tts | `.video-kit/venv/bin/python -c "import edge_tts"`（Windows 是 `venv\Scripts\python.exe`） |
| 渲染用 Chrome | `.video-kit/chrome/<版本>/` | Google 官方 Chrome for Testing | `.video-kit/chrome-path.txt` 里写的路径存在 |
| HyperFrames skills | `~/.claude/skills/` 和 `~/.agents/skills/` | meetu-video-studio 的 Release 附件 `hyperframes-skills-0.8.137.zip` | 两处都有 `hyperframes/SKILL.md` |
| Meet U 视频工作室 | `.video-kit/npm-global/`，装成本机的 `hyperframes` 命令 | meetu-video-studio 的 Release 附件（`npm install -g --prefix`，不需要管理员权限） | `hyperframes --version` 能运行，且 `npm-global` 里的 hyperframes 包带有 `NOTICE-MEETU.md` |

## 常见失败

**下载失败（curl 报错、超时）**
网络波动居多，重新运行脚本即可。如果公司网络需要代理，请同事先打开代理软件。

**Mac 上提示"无法打开，因为无法验证开发者"**
用 curl 下载的文件一般不会触发这个提示。万一触发了，对相应文件运行 `xattr -d com.apple.quarantine <文件路径>`（不需要密码）。

**Mac 系统版本太旧**
需要 macOS 11 及以上。macOS 11、12 能用，脚本会自动给 macOS 12 及以下的系统换成兼容的 Chrome 150 版。macOS 10.x 请先升级系统。

**Windows 上 PowerShell 报"禁止运行脚本"**
确认命令里带了 `-ExecutionPolicy Bypass`。它只对这一次运行放行，不需要管理员权限。

**Windows 上中文显示成乱码**
不影响安装结果，看体检那几行的 ✓/✗ 判断即可。脚本本身是带 BOM 的 UTF-8，如果被编辑器另存为其他编码，可能导致运行出错，重新下载工具包即可恢复。

**Windows ARM 电脑（比如部分 Surface）**
Node.js 用 ARM 原生版；FFmpeg 和 Chrome 只有 x64 版，靠系统自带的转译功能运行，速度稍慢，但可以正常使用。

**装完了，但 AI 说找不到 node / ffmpeg**
新写入的 PATH 要重启 AI 工具才会生效。重启之前，工具包里的脚本（`hf.mjs`、`check_env.mjs`、`tts_zh.py`）会自己去 `.video-kit/` 里找程序，不受影响。

## 可选组件

- **逐词识别同事自己录的音频**（`transcribe`）：需要 whisper-cpp，一键脚本不装它。用到时，运行 `node scripts/hf.mjs doctor`，按提示安装。
- **HyperFrames 桌面 App**：已在 Meet U 视频工作室里移除了入口，不需要安装。

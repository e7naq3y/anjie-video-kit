# 安装指南（由 AI 执行，同事只在需要密码或点"允许"时动手）

需要装 4 样东西：Node.js 22 以上、Python 3、FFmpeg、edge-tts 配音。装好后再装 HyperFrames skills。每装完一项都跑一次 `check_env.mjs` 确认。

开始前先判断系统：Mac 用下面"Mac"一节；Windows 用"Windows"一节，命令在 PowerShell 里执行。

## Mac

1. **Homebrew**（Mac 上的软件安装器）。先运行 `brew --version` 看有没有。没有的话：

   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

   安装过程中会要求输入开机密码。告诉同事："终端里会提示输入密码，输入时屏幕上不显示字符，这是正常的，输完按回车。"装完后按提示把 brew 加入 PATH：Apple 芯片的机器是 `eval "$(/opt/homebrew/bin/brew shellenv)"`，并写进 `~/.zprofile`。

   如果 GitHub 访问不了，改用国内镜像安装脚本（中科大或清华的 Homebrew 镜像），或者请同事连上公司代理。

2. **Node、Python、FFmpeg**：

   ```bash
   brew install node python ffmpeg
   ```

   装完确认 `node -v` 大于等于 22。版本太老就运行 `brew upgrade node`。

## Windows

用 PowerShell 执行（开始菜单搜索 "PowerShell"）。winget 是 Windows 10 和 11 自带的安装器。

```powershell
winget install -e --id OpenJS.NodeJS.LTS
winget install -e --id Python.Python.3.12
winget install -e --id Gyan.FFmpeg
```

装完必须**关掉 PowerShell 重新打开**（Claude 或 Codex 也要重启），新装的命令才能用。确认 `node -v` 大于等于 22，`py --version` 和 `ffmpeg -version` 都有输出。

如果 winget 提示要同意协议，告诉同事输入 `Y` 回车。公司电脑如果禁用了 winget，就让同事从官网下载安装包：nodejs.org 的 LTS 版、python.org（安装时勾选 "Add python.exe to PATH"）。FFmpeg 可以从 gyan.dev 下载 release essentials 版。

## edge-tts 中文配音（两个系统都要装）

装进一个单独的 Python 虚拟环境，这样不会和系统的 Python 冲突。新版 Mac 上直接 `pip install` 会报 "externally-managed-environment"，就是因为这个：

Mac：
```bash
python3 -m venv ~/.video-kit/venv
~/.video-kit/venv/bin/pip install edge-tts
```

Windows：
```powershell
py -m venv $HOME\.video-kit\venv
& $HOME\.video-kit\venv\Scripts\pip.exe install edge-tts
```

以后运行 `tts_zh.py` 都用这个环境里的 Python：Mac 是 `~/.video-kit/venv/bin/python`，Windows 是 `$HOME\.video-kit\venv\Scripts\python.exe`。

edge-tts 调用的是微软的在线语音服务，所以需要联网，但不需要账号或 key。

## HyperFrames skills（Claude Code 和 Codex 一条命令全装）

```bash
npx --yes hyperframes@latest skills
```

这条命令会把 HyperFrames 全部 21 个 skill 同时装进 `~/.claude/skills`（Claude Code 读取）和 `~/.agents/skills`（Codex 读取）。**装完让同事重启 AI 工具**，在 Claude 里输入 `/hyperframes`、在 Codex 里输入 `$hyperframes`，能看到这个 skill 就说明装好了。

如果这台电脑之前用 `claude plugin install hyperframes@hyperframes` 装过插件版，两种装法并存不影响使用，但 Claude 里会出现两套同名的 skill。选一种就够，推荐上面这条独立安装命令。插件版锁定的 CLI 版本有时比 npm 上发布的还新，会导致下载失败。

## 渲染用的浏览器

HyperFrames 渲染时要用一个无头 Chrome，第一次渲染会自动下载。可以提前下好：

```bash
node <本skill目录>/scripts/hf.mjs browser ensure
```

如果下载失败（国内网络常见），先请同事连上公司代理再试。实在下不了的话，电脑上装了 Google Chrome 也可以用，`hf.mjs doctor` 会显示它找到了哪个浏览器。

## 可选组件

- **逐词识别同事自己录的音频**（`transcribe`）：Mac 运行 `brew install whisper-cpp`；Windows 按 `hf.mjs doctor` 给出的提示安装。
- **HyperFrames 桌面 App**（用聊天的方式改视频）：https://hyperframes.dev/studio/download ，不装也能正常做视频。

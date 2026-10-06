# 安杰视频工具包 · AI 安装指令

> 这份文件是写给 AI 助手（Claude Code / Codex）看的。同事只需要对你说"按这个文件帮我安装"，剩下的全部由你来完成。
>
> **假设这是一台全新的空白电脑**：没有 Homebrew、没有 git、没有 Node、没有 Python，什么都没装。下面的步骤只用到系统自带的工具（Mac 的 `curl`、`unzip`；Windows 的 PowerShell），并且**全程不需要管理员密码**。
>
> 不要自作主张改用 Homebrew、winget、`sudo` 或"以管理员身份运行"：你执行命令时没有可以输入密码或确认弹窗的终端，这些方式一定会卡住。

开始时先对同事说：

> 🎬 正在为你安装安杰视频工具包 —— 安杰出品，专业出片。全程自动，大约 2 到 5 分钟，不需要你输入密码。

## 第 1 步：判断操作系统

- Mac：运行 `uname -s`，输出 `Darwin`
- Windows：PowerShell 里 `$env:OS` 是 `Windows_NT`；如果你是在 Git Bash 里执行命令，`uname -s` 会输出 `MINGW64_NT...` 之类

## 第 2 步：下载工具包

工具包同时放进两个 skill 目录：Claude Code 读 `~/.claude/skills/`，Codex 读 `~/.agents/skills/`。两处都放，同事以后换工具也能直接用。

**Mac**（在终端里执行，不需要 git）：

```bash
set -e
cd "$(mktemp -d)"
curl -fL --retry 3 -o kit.zip https://github.com/e7naq3y/anjie-video-kit/archive/refs/heads/main.zip
unzip -q kit.zip
for d in "$HOME/.claude/skills" "$HOME/.agents/skills"; do
  mkdir -p "$d" && rm -rf "$d/anjie-video-kit" && cp -R anjie-video-kit-main "$d/anjie-video-kit"
done
ls "$HOME/.claude/skills/anjie-video-kit/SKILL.md"
```

**Windows**（PowerShell）：

```powershell
$ProgressPreference = "SilentlyContinue"
$tmp = Join-Path $env:TEMP "anjie-kit"; Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue; New-Item -ItemType Directory $tmp | Out-Null
Invoke-WebRequest https://github.com/e7naq3y/anjie-video-kit/archive/refs/heads/main.zip -OutFile "$tmp\kit.zip" -UseBasicParsing
Expand-Archive "$tmp\kit.zip" -DestinationPath $tmp -Force
foreach ($d in @("$HOME\.claude\skills", "$HOME\.agents\skills")) {
  New-Item -ItemType Directory -Force $d | Out-Null
  Remove-Item -Recurse -Force "$d\anjie-video-kit" -ErrorAction SilentlyContinue
  Copy-Item -Recurse "$tmp\anjie-video-kit-main" "$d\anjie-video-kit"
}
Test-Path "$HOME\.claude\skills\anjie-video-kit\SKILL.md"
```

如果你是在 Git Bash 里执行命令，就用 `powershell.exe -NoProfile -Command "..."` 把上面的内容包起来执行，或者直接用 Mac 那段（Git Bash 自带 curl 和 unzip）。

## 第 3 步：运行一键安装脚本

脚本会把 Node.js、FFmpeg、Python（配音用）、渲染用浏览器、HyperFrames skills 全部装进 `~/.video-kit/`，最后自动体检。可以反复运行，已经装好的会跳过。

**下载量约 300MB，网速一般时需要几分钟。执行时把命令超时设到 15 分钟**，或者放到后台运行、再查看输出。默认 2 分钟的超时不够用，会被中途打断。

**Mac**：

```bash
bash "$HOME/.claude/skills/anjie-video-kit/scripts/bootstrap-mac.sh"
```

**Windows**，你在 PowerShell 里执行命令时：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME\.claude\skills\anjie-video-kit\scripts\bootstrap-windows.ps1"
```

你在 Git Bash 里执行命令时：

```bash
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$USERPROFILE\\.claude\\skills\\anjie-video-kit\\scripts\\bootstrap-windows.ps1"
```

`-ExecutionPolicy Bypass` 只对这一次运行放行，不改系统设置，也不需要管理员权限。

看到"✅ 安装完成"就是成功了。有带 ✗ 的行：

1. 先**原样重新运行一次**脚本。多数是网络波动，已经装好的会跳过，很快。
2. 还是失败，看 `anjie-video-kit/references/install.md` 里对应组件的说明手动处理。
3. 实在装不上，用一句话告诉同事卡在哪一项、可能的原因，建议他找谁。

## 第 4 步：请同事重启 AI 工具

对同事说：

> ✅ 安杰视频工具包安装完成！请**完全退出**现在这个 AI 工具再重新打开（这样新装的功能才会生效）。
> 打开后，直接跟我说想做什么视频就行，比如"帮我做个 30 秒的产品介绍视频，发抖音用"。
> 我会先问你几个选择题，做出来以后，你还可以在「Meet U 视频工作室」里自己点一点、拖一拖，调整文字和时间。

## 之后怎么干活

重启后，同事一提到做视频，`anjie-video-kit` 这个 skill 就会自动启用。完整流程写在它的 `SKILL.md` 里。

## 更新工具包

重新执行第 2 步和第 3 步即可，两步都会覆盖成最新版。

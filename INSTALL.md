# 安杰视频工具包 · AI 安装指令

> 这份文件是写给 AI 助手（Claude Code / Codex）看的。同事只需要对你说"按这个文件帮我安装"，剩下的全部由你来完成。
> 整个过程中用大白话和同事交流，不要把命令和报错原样甩给对方。

安装开始时，先对同事说：

> 🎬 正在为你安装安杰视频工具包 —— 安杰出品，专业出片。大约需要 10 分钟，中间可能要你输一次电脑密码，或者点几次"允许"。

## 第 1 步：判断环境

1. **操作系统**：Mac 还是 Windows。
2. **你自己是哪个 AI 工具**，由此决定 skill 装在哪里：

| 你是 | skill 目录（Mac） | skill 目录（Windows） |
|---|---|---|
| Claude Code / Claude 桌面 App | `~/.claude/skills/` | `$HOME\.claude\skills\` |
| Codex | `~/.agents/skills/` | `$HOME\.agents\skills\` |

判断不了自己是哪个，就两个目录都装。

## 第 2 步：下载工具包到 skill 目录

仓库根目录就是 skill 本身，最终路径应该是 `<skill目录>/anjie-video-kit/SKILL.md`。

**电脑上有 git 时**（先运行 `git --version` 看看）：

```bash
git clone --depth 1 https://github.com/e7naq3y/anjie-video-kit.git <skill目录>/anjie-video-kit
```

**没有 git 时**，Mac：

```bash
mkdir -p <skill目录> && cd <skill目录>
curl -L -o anjie-video-kit.zip https://github.com/e7naq3y/anjie-video-kit/archive/refs/heads/main.zip
unzip -q anjie-video-kit.zip && rm anjie-video-kit.zip && mv anjie-video-kit-main anjie-video-kit
```

**没有 git 时**，Windows（PowerShell）：

```powershell
New-Item -ItemType Directory -Force <skill目录> | Out-Null; Set-Location <skill目录>
Invoke-WebRequest https://github.com/e7naq3y/anjie-video-kit/archive/refs/heads/main.zip -OutFile anjie-video-kit.zip
Expand-Archive anjie-video-kit.zip -DestinationPath . ; Remove-Item anjie-video-kit.zip; Rename-Item anjie-video-kit-main anjie-video-kit
```

工具包里自带两个中文字体（约 42MB），下载要一点时间。GitHub 访问不了的话，请同事连上公司代理再试。

**已经装过、要更新时**：用 git 装的，在目录里运行 `git pull`；用 zip 装的，删掉旧目录重新下载。

## 第 3 步：装做视频需要的软件

读刚下载的 `anjie-video-kit/references/install.md`，按同事的系统装好：Node.js 22 以上、Python 3、FFmpeg、edge-tts 配音、HyperFrames skills。每装完一项就运行一次环境体检：

```bash
node <skill目录>/anjie-video-kit/scripts/check_env.mjs
```

如果连 `node` 都运行不了，说明 Node 还没装，先按 install.md 装 Node，再回来跑体检。一直装到体检显示"全部就绪"为止。

## 第 4 步：完成，请同事重启

对同事说：

> ✅ 安杰视频工具包安装完成！请**完全退出**现在这个 AI 工具再重新打开（这样新装的功能才会生效）。
> 打开后，直接跟我说想做什么视频就行，比如"帮我做个 30 秒的产品介绍视频，发抖音用"。
> 我会先问你几个选择题，做出来以后，你还可以在浏览器里自己点一点、拖一拖，调整文字和时间。

## 之后怎么干活

重启后，同事一提到做视频，`anjie-video-kit` 这个 skill 就会自动启用。完整流程写在它的 `SKILL.md` 里：检查环境 → 问清需求 → 写稿和配音 → 交给 HyperFrames 制作 → 自查 → 同事在浏览器里调细节 → 渲染交付。

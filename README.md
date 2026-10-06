# 🎬 安杰视频工具包 · Anjie Video Kit

**安杰出品。** 让不懂技术的同事，也能和 AI 聊着天做出专业视频。

基于 HeyGen 开源的 [HyperFrames](https://github.com/heygen-com/hyperframes)（写 HTML、渲染 MP4）。在它之上，补齐了国内团队实际做视频时缺的那几块：

- **一句话安装**：AI 读一遍安装说明，就能自己把所有软件装好，Mac 和 Windows 都支持
- **大白话需求问答**：一轮选择题问清楚平台、时长、声音、风格，不会写需求的同事也能用
- **中文 AI 配音**：微软神经网络语音，四种常用声音可以先试听再选；同时输出逐词时间，字幕和画面精确对齐
- **自带中文字体**：思源黑体和思源宋体（可变字重，免费商用），换任何电脑渲染，效果都一样
- **Meet U 视频工作室**：安杰基于开源 HyperFrames 改造的全中文编辑器（[e7naq3y/meetu-video-studio](https://github.com/e7naq3y/meetu-video-studio)），成片前在浏览器里点一点、拖一拖，就能改文字、颜色、时间
- **踩坑手册**：实际出片时遇到的问题和解决办法都整理进去了，AI 会提前避开
- **交付标准**：成片统一调到 -15 LUFS（短视频平台常用的响度标准），并写入出品信息

支持 **Claude Code / Claude 桌面 App** 和 **Codex（ChatGPT 账号登录）**。网页版的 ChatGPT 和 Claude 不能在电脑上执行命令，用不了。

---

## 安装（复制一句话给 AI 就行）

打开 Claude 桌面 App 的 Code 页，或者打开 Codex，把下面这句话发给它：

```
请读取 https://raw.githubusercontent.com/e7naq3y/anjie-video-kit/main/INSTALL.md ，严格按照里面的步骤帮我安装安杰视频工具包。
```

安装过程中：
- **要输电脑密码**（Mac）：直接输入后按回车。屏幕上不显示字符，这是正常的。
- **弹窗问要不要允许运行命令**：点"允许"。
- **装完让你重启 AI 工具**：完全退出再打开。

## 使用

重启后，直接说想做什么视频：

> 帮我做个 30 秒的产品介绍视频，发抖音用

> 我有一份稿子（贴上稿子），做成 1 分钟的讲解视频

> 给这段视频加上字幕（把视频文件拖进对话框）

AI 会先问你几个选择题，一题回一个字母就行，不确定的回"你定"。做好以后会在浏览器里打开，你可以：

- **点画面上的文字**：在右侧「设计」面板改内容、字体、大小、颜色
- **拖下面时间线上的色条**：调整每个元素出现的时间和长短
- 改好了回去跟 AI 说"改好了"，它会检查一遍，然后出成片

改不动的地方（换风格、加动画、换配音），直接跟 AI 说想要什么效果。

## 常见问题

| 问题 | 怎么办 |
|---|---|
| 网络连不上，或者下载失败 | 连上公司代理，跟 AI 说"再试一次" |
| 配音里有字读错了 | 告诉 AI 哪个字、应该怎么读 |
| 视频太大，微信发不出去 | 跟 AI 说"压缩到 25MB 以内" |
| 想更新到最新版 | 跟 AI 说"按 INSTALL.md 更新安杰视频工具包" |

## 目录结构

```
SKILL.md              主流程（AI 读）
INSTALL.md            安装指令（AI 读）
references/           安装细节、需求问答清单、踩坑手册
scripts/              环境体检、中文配音、HyperFrames 启动器
assets/fonts/         思源黑体、思源宋体（SIL OFL 1.1）
```

## 致谢与许可

- 视频引擎：[HyperFrames](https://github.com/heygen-com/hyperframes)（Apache-2.0）；中文编辑器为其修改版，修改声明见 meetu-video-studio 仓库
- 中文配音：[edge-tts](https://github.com/rany2/edge-tts)
- 字体：Noto Sans SC / Noto Serif SC，SIL Open Font License 1.1，许可证见 `assets/fonts/OFL.txt`

---

**安杰视频工具包** · 设计与开发：安杰

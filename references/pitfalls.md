# 踩过的坑（写 HTML 前先读一遍）

全部是实际做视频时遇到过的问题，按出现的先后顺序排列。

## 1. CLI 版本在 npm 上找不到（ETARGET）

现象：`npm error notarget No matching version found for hyperframes@0.8.xxx`。

原因：插件版（`claude plugin install`）锁定的 CLI 版本，有时比 npm 上正式发布的还新一个版本。

解决：所有命令都通过 `scripts/hf.mjs` 运行，它会自动退回到 npm 上存在的版本。项目 `package.json` 里锁定的版本如果也下载不了，用 `hf.mjs upgrade --project .` 改成能下载的版本，再跑一次 `check` 确认没问题。

## 2. 中文字体

lint 报 `font_family_without_font_face`，或者渲染出来的中文字体不对。

HyperFrames 预装的字体里只有日文的 Noto Sans JP，没有简体中文字体。有两种办法：

**办法 A（推荐，换电脑渲染效果也一致）**：用工具包自带的思源黑体和思源宋体（`assets/fonts/`，SIL OFL 许可，免费商用）。两个都是可变字重，一个文件里包含所有粗细。先复制到项目的 `assets/fonts/`，再这样声明（已实测，lint 通过，渲染正常）：

```css
@font-face { font-family: "NotoSansSC"; font-weight: 100 900; src: url("assets/fonts/NotoSansSC-VF.ttf"); }
@font-face { font-family: "NotoSerifSC"; font-weight: 200 900; src: url("assets/fonts/NotoSerifSC-VF.ttf"); }
/* 用的时候直接写字重：标题 font-family: "NotoSerifSC"; font-weight: 900; 正文 font-family: "NotoSansSC"; font-weight: 400; */
```

**办法 B（快，但只能在当前电脑上渲染）**：用系统自带的字体，通过 `local()` 声明：

| 系统 | 黑体（正文、字幕） | 宋体或衬线（标题） |
|---|---|---|
| Mac | `PingFang SC`、`Hiragino Sans GB` | `Songti SC`（有 Black 粗体） |
| Windows | `Microsoft YaHei`（微软雅黑） | `SimSun`（没有粗体，做大标题偏弱，建议用办法 A） |

```css
@font-face { font-family: "Songti SC"; font-weight: 900; src: local("Songti SC Black"), local("Songti SC"); }
```

## 3. lint 常见报错

- `template_literal_selector`：`querySelector` 里不能用模板字符串，比如 `` `#cap${k}` ``，打包器解析不了。改成 `document.getElementById("cap" + k)`，或者先把元素存进变量再用。GSAP 的选择器字符串也一样处理。
- `nested_structure_needs_subcomposition`（警告）：单场景的短片不需要外面再包一层 `class="clip"` 的容器，去掉就行。多场景的片子按它的建议，把每个场景拆成单独的子合成文件。
- `gsap_css_transform_conflict`：CSS 里写了 `transform`，GSAP 又在同一个元素上做动画。把初始状态写进 `gsap.fromTo` 里，不要写在 CSS 里。

## 4. SVG 线条渲染成黑色色块

SVG 的 `<path>` 默认是黑色填充。画波浪线、曲线时，所有 path 都要设 `fill: none`。CSS 选择器要覆盖到每一组 SVG，别只写了一组。

## 5. 配乐盖过人声

按 HyperFrames 的流程，用 `hyperframes-audio` 的 `carve.mjs` 处理：它只在人声占用的频段把配乐压低。这个脚本依赖 `@hyperframes/core`，要先在项目里装上，版本和 CLI 保持一致：

```bash
npm i -D @hyperframes/core@<和 package.json 里 hyperframes 相同的版本>
node <hyperframes-audio skill 目录>/scripts/carve.mjs --comp index.html
```

## 6. 成片音量偏小

HyperFrames 直接出的片子大约 -22 LUFS，手机外放会明显偏小。交付前统一调到 -15 LUFS，命令见 SKILL.md 第 6 步。

## 7. 字幕和声音对不上

不要按字数估算时间。用 `tts_zh.py` 输出的 `timeline.json`：每句有 `start`/`end`，每个词有 `[开始, 结束, 文字]`，单位是秒，从配音开头算起。如果视频开头还有一段片头，记得把片头的时长加上去。

逐词高亮字幕用 HyperFrames 的 `asr-keyword-glow` 规则（卡拉 OK 风格）。另外两处要注意：
- 念过的词保持点亮，不要念完又变暗，否则整句看起来是灰的。
- 放大的倍数控制在 1.1 以内，每个词左右留 2 到 3px 间距，否则放大的字会压到旁边的字。

## 8. 多音字

edge-tts 偶尔会读错多音字。比如单独一个"行"字（衣食住"行"），可能被读成 háng。遇到这种情况，用 `tts_zh.py` 的 `|` 语法：字幕显示原文，配音念替换后的文字，比如 `“行”，我们要的是……|出行，我们要的是……`。这类问题要请同事听一遍配音，你自己没法核对。

## 9. 路径和系统差异

- 项目路径用英文，不带空格（Windows 上中文路径偶尔会让 FFmpeg 或 Chrome 出错）。
- Windows 上刚装完的软件，要重开终端或 AI 工具才能找到命令。
- 在 Mac 的 zsh 里，`HF="node xxx.mjs"; $HF args` 这种写法跑不起来（zsh 不按空格拆分变量）。直接写完整的命令，或者用函数。

## 10. 长视频

超过 3 分钟的视频走 `general-video` 工作流，每个场景拆成一个子合成文件。超过 1 分钟的，先渲染开头 15 秒给同事确认风格，再出整片，免得整片返工。`render` 没有时间范围参数。出样片的办法是：临时把 `index.html` 根节点的 `data-duration` 改成 15，渲染到 `成片/样片.mp4`，然后**马上改回原值**（根节点的时长是编译时读取的，所以这样改是有效的）。

## 11. 浏览器里改不了文字

现象：同事在 Studio 里点中文字，右侧"Design"面板的内容框是空的。

原因：文字是用 JS 生成的。Studio 只能编辑写在 HTML 里的静态文字。

解决：文字全部直接写进 HTML。逐字动画的 `<span>` 也直接写在 HTML 里，再用 GSAP 选中做动画。

## 12. 打开的编辑器是英文的，还弹出 "Meet Framey" 广告

原因：运行了 `npx hyperframes ...`。npx 会去下载官方英文版，而不是使用本机装好的 Meet U 视频工作室。

解决：先关掉这个预览（`hyperframes preview <项目路径> --stop`），再用 `hyperframes preview --background` 重新打开。以后都直接用 `hyperframes` 命令。如果 `hyperframes` 命令也打开了英文版，说明汉化版没装好，重新运行一键安装脚本。

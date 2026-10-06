#!/usr/bin/env node
// 安杰视频工具包 · 做视频前的环境体检：逐项报告是否就绪，缺什么就给出对应系统的安装命令。
// 退出码 0 = 全部就绪，1 = 有缺项。
import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const isWin = process.platform === "win32";
const home = homedir();
const sh = (cmd, args) => {
  const r = spawnSync(cmd, args, { encoding: "utf8", shell: isWin });
  return r.status === 0 ? (r.stdout || r.stderr || "").trim() : null;
};

const results = [];
const check = (name, ok, detail, fix) => results.push({ name, ok, detail, fix });

// Node
const nodeMajor = Number(process.versions.node.split(".")[0]);
check("Node.js ≥ 22", nodeMajor >= 22, `当前 ${process.versions.node}`,
  isWin ? "winget install -e --id OpenJS.NodeJS.LTS（装完重开终端）" : "brew install node 或 brew upgrade node");

// Python
const py = sh(isWin ? "py" : "python3", ["--version"]);
check("Python 3", !!py, py || "未找到",
  isWin ? "winget install -e --id Python.Python.3.12（装完重开终端）" : "brew install python");

// FFmpeg / FFprobe
const ff = sh("ffmpeg", ["-version"]);
check("FFmpeg", !!ff, ff ? ff.split("\n")[0] : "未找到",
  isWin ? "winget install -e --id Gyan.FFmpeg（装完重开终端）" : "brew install ffmpeg");
check("FFprobe", !!sh("ffprobe", ["-version"]), "", "随 FFmpeg 一起安装");

// edge-tts 虚拟环境
const venvPy = isWin ? join(home, ".video-kit", "venv", "Scripts", "python.exe") : join(home, ".video-kit", "venv", "bin", "python");
const edge = existsSync(venvPy) ? sh(venvPy, ["-c", "import edge_tts;print(edge_tts.__version__)"]) : null;
check("edge-tts 中文配音", !!edge, edge ? `版本 ${edge}，Python: ${venvPy}` : "未安装",
  isWin
    ? "py -m venv $HOME\\.video-kit\\venv; & $HOME\\.video-kit\\venv\\Scripts\\pip.exe install edge-tts"
    : "python3 -m venv ~/.video-kit/venv && ~/.video-kit/venv/bin/pip install edge-tts");

// HyperFrames skills：独立安装（Claude / Codex）或插件版，任一存在即可
const skillDirs = [
  [join(home, ".claude", "skills", "hyperframes", "SKILL.md"), "Claude Code"],
  [join(home, ".agents", "skills", "hyperframes", "SKILL.md"), "Codex"],
  [join(home, ".claude", "plugins", "cache", "hyperframes"), "Claude 插件版"],
];
const found = skillDirs.filter(([p]) => existsSync(p)).map(([, n]) => n);
check("HyperFrames skills", found.length > 0, found.length ? `已装在：${found.join("、")}` : "未安装",
  "npx --yes hyperframes@latest skills（装完重启 Claude / Codex）");

// npm 可访问（拉取 hyperframes CLI 需要）
const npmV = sh("npm", ["view", "hyperframes", "version"]);
check("能访问 npm", !!npmV, npmV ? `hyperframes 最新版 ${npmV}` : "访问失败", "检查网络，或请同事连公司代理");

console.log("🎬 安杰视频工具包 · 环境体检\n");
let allOk = true;
for (const r of results) {
  allOk &&= r.ok;
  console.log(`${r.ok ? "✓" : "✗"} ${r.name}${r.detail ? "  —  " + r.detail : ""}`);
  if (!r.ok) console.log(`    安装：${r.fix}`);
}
console.log(allOk ? "\n全部就绪，可以开始做视频。" : "\n有缺项，按上面的命令安装后再运行本检查。详细步骤见 references/install.md");
process.exit(allOk ? 0 : 1);

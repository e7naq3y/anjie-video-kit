#!/usr/bin/env node
// 安杰视频工具包 · HyperFrames CLI 启动器：用法与 `npx hyperframes <命令>` 完全相同，例如
//   node hf.mjs check
//   node hf.mjs render -o 成片/demo.mp4
//
// 为什么不直接 npx：插件版或项目 package.json 锁定的版本，有时在 npm 上还没发布（ETARGET），
// 这里先确认版本存在，不存在就退回 npm 上的最新正式版，避免整个流程卡在下载这一步。
// 想强制指定版本：设环境变量 HF_VERSION=0.8.136
import { spawnSync } from "node:child_process";
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

const isWin = process.platform === "win32";
const run = (cmd, args, opts = {}) => spawnSync(cmd, args, { encoding: "utf8", shell: isWin, ...opts });

function exists(version) {
  const r = run("npm", ["view", `hyperframes@${version}`, "version"]);
  return r.status === 0 && r.stdout.trim() === version;
}

function latest() {
  const r = run("npm", ["view", "hyperframes", "version"]);
  if (r.status !== 0) {
    console.error("[hf] 无法访问 npm（检查网络或代理）：\n" + (r.stderr || "").slice(0, 400));
    process.exit(1);
  }
  return r.stdout.trim();
}

// 项目里锁定的版本：保证同一个项目重复渲染结果一致
function projectPin() {
  const pkg = join(process.cwd(), "package.json");
  if (!existsSync(pkg)) return null;
  try {
    const scripts = JSON.parse(readFileSync(pkg, "utf8")).scripts || {};
    for (const v of Object.values(scripts)) {
      const m = /hyperframes@(\d+\.\d+\.\d+[^\s"]*)/.exec(v);
      if (m) return m[1];
    }
  } catch {}
  return null;
}

// Meet U 视频工作室（安杰开发）：汉化版编辑器，Meet U 公司内部使用。设 HF_OFFICIAL=1 可改用官方英文版。
const MEETU_PKG =
  "https://github.com/e7naq3y/meetu-video-studio/releases/download/v0.8.137-meetu.1/meetu-hyperframes-0.8.137-meetu.1.tgz";
const useMeetU = !process.env.HF_OFFICIAL && !process.env.HF_VERSION;

let version = useMeetU ? null : process.env.HF_VERSION || projectPin();
if (version && !exists(version)) {
  const fallback = latest();
  console.error(`[hf] hyperframes@${version} 在 npm 上不存在，改用最新正式版 ${fallback}`);
  version = fallback;
}
version = version || "latest";
const pkgArgs = useMeetU ? ["--yes", `--package=${MEETU_PKG}`, "hyperframes"] : ["--yes", `hyperframes@${version}`];

const args = process.argv.slice(2);
if (args.length === 0) {
  console.error("用法: node hf.mjs <hyperframes 命令> [参数]，例如 node hf.mjs check");
  process.exit(2);
}

// Windows 上调用 npx.cmd 必须经过 shell，而 shell 不会自动给参数加引号，所以带空格的参数要手动包一层
const quote = (s) => (isWin && /[\s&|<>^]/.test(s) ? `"${s.replace(/"/g, '\\"')}"` : s);
const r = spawnSync("npx", [...pkgArgs, ...args].map(quote), {
  stdio: "inherit",
  shell: isWin,
  // 公司内部使用：关闭向上游发送的使用统计
  env: { ...process.env, HYPERFRAMES_NO_UPDATE_CHECK: "1", HYPERFRAMES_NO_TELEMETRY: "1" },
});
process.exit(r.status ?? 1);

# 安杰视频工具包 · Windows 一键安装
#
# 适用于全新的空白 Windows 10/11：不需要 winget、不需要 git、不需要管理员权限。
# 所有软件都以独立程序的形式装进 %USERPROFILE%\.video-kit\，可以反复运行（已装好的会跳过）。
# AI 工具执行命令时没有可以确认 UAC 弹窗的界面，所以这里刻意避开一切需要管理员权限的安装方式。
#
# 用法（PowerShell 或 Git Bash 里都可以）：
#   powershell -NoProfile -ExecutionPolicy Bypass -File bootstrap-windows.ps1
#
# 注意：本文件必须保存为"带 BOM 的 UTF-8"，否则 Windows PowerShell 5.1 会把中文读成乱码。

$ErrorActionPreference = "Continue"
$ProgressPreference = "SilentlyContinue"   # 关掉进度条，Invoke-WebRequest 能快几十倍
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$KIT = Join-Path $HOME ".video-kit"
$BIN = Join-Path $KIT "bin"
$SKILL_DIR = Split-Path -Parent $PSScriptRoot
New-Item -ItemType Directory -Force -Path $BIN | Out-Null
$env:Path = "$BIN;$KIT\node;$env:Path"

$HF_RELEASE = "https://github.com/e7naq3y/meetu-video-studio/releases/download/v0.8.137-meetu.1"
$FF_RELEASE = "https://github.com/eugeneware/ffmpeg-static/releases/download/b6.1.1"
$CHROME_VERSION = "152.0.7977.30"

$script:FAILED = $false
function Step($t) { Write-Host ""; Write-Host "▶ $t" }
function Ok($t) { Write-Host "  ✓ $t" }
function Bad($t) { Write-Host "  ✗ $t"; $script:FAILED = $true }

# 优先用 Windows 10 1803 起自带的 curl.exe（更快更稳），没有再用 Invoke-WebRequest
function Download($url, $out) {
  if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
    & curl.exe -fL --retry 3 --connect-timeout 20 --max-time 1800 -s -S -o $out $url
    return ($LASTEXITCODE -eq 0 -and (Test-Path $out))
  }
  try { Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing; return (Test-Path $out) } catch { return $false }
}

# 优先用系统自带的 tar.exe 解压 zip（比 Expand-Archive 快很多）
function Unzip($zip, $dest) {
  New-Item -ItemType Directory -Force -Path $dest | Out-Null
  if (Get-Command tar.exe -ErrorAction SilentlyContinue) {
    & tar.exe -xf $zip -C $dest
    if ($LASTEXITCODE -eq 0) { return $true }
  }
  try { Expand-Archive -Path $zip -DestinationPath $dest -Force; return $true } catch { return $false }
}

function Gunzip($gz, $out) {
  $in = [System.IO.File]::OpenRead($gz)
  $o = [System.IO.File]::Create($out)
  $z = New-Object System.IO.Compression.GZipStream($in, [System.IO.Compression.CompressionMode]::Decompress)
  $z.CopyTo($o); $z.Close(); $o.Close(); $in.Close()
  Remove-Item $gz -Force
}

function Works($exe, $argList) {
  try { & $exe @argList *> $null; return ($LASTEXITCODE -eq 0) } catch { return $false }
}

Write-Host "🎬 安杰视频工具包 · Windows 一键安装（安杰出品）"

$isArm = ($env:PROCESSOR_ARCHITECTURE -eq "ARM64")
$nodeArch = if ($isArm) { "arm64" } else { "x64" }   # FFmpeg 和 Chrome 只有 x64 版，ARM 电脑上会自动转译运行

# ---------- Node.js ----------
Step "Node.js（运行 HyperFrames 需要）"
function NodeOk {
  if (-not (Get-Command node -ErrorAction SilentlyContinue)) { return $false }
  try { return ([int](& node -p "process.versions.node.split('.')[0]") -ge 22) } catch { return $false }
}
if (NodeOk) {
  Ok "已就绪：$(& node -v)"
} else {
  $nv = "v22.23.3"
  try {
    $idx = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.json" -UseBasicParsing
    $latest = $idx | Where-Object { $_.version -like "v22.*" } | Select-Object -First 1
    if ($latest) { $nv = $latest.version }
  } catch {}
  $zip = Join-Path $KIT "node.zip"
  if (Download "https://nodejs.org/dist/$nv/node-$nv-win-$nodeArch.zip" $zip) {
    $tmp = Join-Path $KIT "node-tmp"
    Remove-Item -Recurse -Force $tmp, (Join-Path $KIT "node") -ErrorAction SilentlyContinue
    if (Unzip $zip $tmp) {
      Move-Item (Get-ChildItem $tmp -Directory | Select-Object -First 1).FullName (Join-Path $KIT "node")
      Remove-Item -Recurse -Force $tmp, $zip -ErrorAction SilentlyContinue
    }
    if (NodeOk) { Ok "已安装：$(& node -v)" } else { Bad "Node.js 解压后无法运行" }
  } else { Bad "Node.js 下载失败" }
}

# ---------- FFmpeg ----------
Step "FFmpeg（视频编码需要）"
foreach ($tool in @("ffmpeg", "ffprobe")) {
  if ((Get-Command $tool -ErrorAction SilentlyContinue) -and (Works $tool @("-version"))) { Ok "$tool 已就绪"; continue }
  $exe = Join-Path $BIN "$tool.exe"
  if (Download "$FF_RELEASE/$tool-win32-x64.gz" "$exe.gz") {
    Gunzip "$exe.gz" $exe
    if (Works $exe @("-version")) { Ok "$tool 已安装" } else { Bad "$tool 无法运行" }
  } else { Bad "$tool 下载失败" }
}

# ---------- uv（用来装 Python 和配音组件，它自己不需要 Python） ----------
Step "uv（Python 环境管理）"
if (Get-Command uv -ErrorAction SilentlyContinue) {
  Ok "已就绪：$(& uv --version)"
} else {
  $env:UV_INSTALL_DIR = $BIN
  $env:UV_NO_MODIFY_PATH = "1"
  # 必须放在子进程里跑：uv 官方安装程序内部会调用 exit，在当前进程里执行会把整个安装脚本一起结束
  $ps = (Get-Process -Id $PID).Path
  & $ps -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex" *> $null
  if (Get-Command uv -ErrorAction SilentlyContinue) { Ok "已安装：$(& uv --version)" } else { Bad "uv 安装失败" }
}

# ---------- Python + edge-tts 中文配音 ----------
Step "中文 AI 配音（edge-tts）"
$venvPy = Join-Path $KIT "venv\Scripts\python.exe"
if ((Test-Path $venvPy) -and (Works $venvPy @("-c", "import edge_tts"))) {
  Ok "已就绪"
} elseif (Get-Command uv -ErrorAction SilentlyContinue) {
  $env:UV_PYTHON_INSTALL_DIR = Join-Path $KIT "python"
  # only-managed：不碰系统里的 python（Windows 自带的 python.exe 只是应用商店的跳转入口）
  & uv venv (Join-Path $KIT "venv") --python 3.12 --python-preference only-managed --clear *> $null
  & uv pip install --python $venvPy edge-tts *> $null
  if (Works $venvPy @("-c", "import edge_tts")) { Ok "已安装" } else { Bad "edge-tts 安装失败" }
} else { Bad "缺少 uv，无法安装配音组件" }

# ---------- 渲染用的无头 Chrome ----------
Step "渲染用浏览器（Chrome Headless Shell）"
$crDir = Join-Path $KIT "chrome\$CHROME_VERSION"
$crExe = Join-Path $crDir "chrome-headless-shell-win64\chrome-headless-shell.exe"
if (Test-Path $crExe) {
  Ok "已就绪"
} else {
  $zip = Join-Path $KIT "chrome.zip"
  if (Download "https://storage.googleapis.com/chrome-for-testing-public/$CHROME_VERSION/win64/chrome-headless-shell-win64.zip" $zip) {
    Unzip $zip $crDir | Out-Null
    Remove-Item $zip -Force -ErrorAction SilentlyContinue
    if (Test-Path $crExe) { Ok "已安装" } else { Bad "浏览器解压后找不到程序" }
  } else { Bad "浏览器下载失败" }
}
# hf.mjs 读这个文件，通过 HYPERFRAMES_BROWSER_PATH 让 HyperFrames 直接用它
if (Test-Path $crExe) { [System.IO.File]::WriteAllText((Join-Path $KIT "chrome-path.txt"), $crExe) }

# ---------- HyperFrames skills ----------
# 官方的 `hyperframes skills` 依赖 git，空白电脑没有 git，所以直接下载打包好的 skills 解压。
# Claude Code 读 ~\.claude\skills，Codex 读 ~\.agents\skills，两处都装，换工具也能用。
Step "HyperFrames skills（给 AI 用的视频制作说明）"
$zip = Join-Path $KIT "hf-skills.zip"
$skillsTmp = Join-Path $KIT "hf-skills"
if (Download "$HF_RELEASE/hyperframes-skills-0.8.137.zip" $zip) {
  Remove-Item -Recurse -Force $skillsTmp -ErrorAction SilentlyContinue
  Unzip $zip $skillsTmp | Out-Null
  Remove-Item $zip -Force -ErrorAction SilentlyContinue
  foreach ($dest in @((Join-Path $HOME ".claude\skills"), (Join-Path $HOME ".agents\skills"))) {
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    foreach ($s in Get-ChildItem $skillsTmp -Directory) {
      $target = Join-Path $dest $s.Name
      Remove-Item -Recurse -Force $target -ErrorAction SilentlyContinue
      Copy-Item -Recurse $s.FullName $target
    }
  }
  if ((Test-Path (Join-Path $HOME ".claude\skills\hyperframes\SKILL.md")) -and (Test-Path (Join-Path $HOME ".agents\skills\hyperframes\SKILL.md"))) {
    Ok "已安装到 Claude 和 Codex（共 $((Get-ChildItem $skillsTmp -Directory).Count) 个）"
  } else { Bad "解压后找不到 skills" }
} else { Bad "skills 下载失败" }

# ---------- 预先下载 Meet U 视频工作室 ----------
Step "Meet U 视频工作室（中文编辑器）"
if ((Get-Command node -ErrorAction SilentlyContinue) -and (Works node @((Join-Path $SKILL_DIR "scripts\hf.mjs"), "--version"))) {
  Ok "已就绪"
} else { Bad "下载失败" }

# ---------- 写入当前用户的 PATH（不需要管理员权限） ----------
Step "配置环境变量"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if (-not $userPath) { $userPath = "" }
$changed = $false
foreach ($p in @($BIN, (Join-Path $KIT "node"))) {
  if (($userPath -split ";") -notcontains $p) { $userPath = "$p;$userPath"; $changed = $true }
}
if ($changed) { [Environment]::SetEnvironmentVariable("Path", $userPath.TrimEnd(";"), "User") }
Ok "已写入当前用户的 PATH"

# ---------- 体检 ----------
Step "最终体检"
if (Get-Command node -ErrorAction SilentlyContinue) {
  & node (Join-Path $SKILL_DIR "scripts\check_env.mjs")
  if ($LASTEXITCODE -ne 0) { $script:FAILED = $true }
}

Write-Host ""
if (-not $script:FAILED) {
  Write-Host "✅ 安装完成！请完全退出 Claude / Codex 再重新打开，然后就可以开始做视频了。"
  exit 0
} else {
  Write-Host "⚠️ 有项目没装好，请看上面带 ✗ 的行。多数是网络波动，重新运行本脚本即可（已装好的会自动跳过）。"
  exit 1
}

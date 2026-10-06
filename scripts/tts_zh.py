"""安杰视频工具包 · 中文 AI 配音（edge-tts），同时输出逐词时间，用于字幕和画面对齐。

用法（用 ~/.video-kit/venv 里的 Python 运行）：
  python tts_zh.py 稿子.txt --out assets [--voice zh-CN-YunyangNeural] [--rate +0%]
  python tts_zh.py --sample "试音用的一句话" --out 试音     # 四个常用声音各生成一段，给同事挑

稿子格式（UTF-8 纯文本）：
  - 一行一句，每句单独合成，句间自动留停顿
  - 空行表示段落或场景切换，停顿更长
  - 某句要让字幕和配音不一样（多音字、念法），写成 “字幕原文|配音念的文字”

输出：
  <out>/voice.wav       整条配音（44.1kHz 单声道）
  <out>/timeline.json   {total, lines:[{index, para, sub, start, end, words:[[开始,结束,词]]}]}，单位秒
  <out>/tts_cache/      每句的中间文件，改稿后只重新合成改动的句子
"""
import argparse
import asyncio
import hashlib
import json
import os
import subprocess
import sys

import edge_tts

# 一键安装脚本把 FFmpeg 装在 ~/.video-kit/bin，这里主动加进 PATH，免得终端没重启时找不到
os.environ["PATH"] = os.pathsep.join([os.path.join(os.path.expanduser("~"), ".video-kit", "bin"), os.environ.get("PATH", "")])

SAMPLE_VOICES = {
    "zh-CN-YunyangNeural": "稳重男声（播音腔）",
    "zh-CN-YunjianNeural": "激昂男声",
    "zh-CN-YunxiNeural": "年轻男声",
    "zh-CN-XiaoxiaoNeural": "温暖女声",
}


def parse_script(path):
    lines, para = [], 0
    for raw in open(path, encoding="utf-8-sig").read().splitlines():
        s = raw.strip()
        if not s:
            if lines and lines[-1]["para"] == para:
                para += 1
            continue
        sub, _, tts = s.partition("|")
        lines.append({"para": para, "sub": sub.strip(), "tts": (tts or sub).strip()})
    return lines


async def synth(text, voice, rate, mp3, sem):
    async with sem:
        if os.path.exists(mp3) and os.path.exists(mp3 + ".json"):
            return json.load(open(mp3 + ".json", encoding="utf-8"))
        for attempt in range(4):
            try:
                c = edge_tts.Communicate(text, voice, rate=rate, boundary="WordBoundary")
                audio, words = bytearray(), []
                async for ch in c.stream():
                    if ch["type"] == "audio":
                        audio += ch["data"]
                    elif ch["type"] == "WordBoundary":
                        words.append([ch["offset"] / 1e7, (ch["offset"] + ch["duration"]) / 1e7, ch["text"]])
                if not audio:
                    raise RuntimeError("没有收到音频")
                open(mp3, "wb").write(audio)
                json.dump(words, open(mp3 + ".json", "w", encoding="utf-8"), ensure_ascii=False)
                return words
            except Exception as e:  # 网络抖动时重试；连续失败多半是网络或代理问题
                print(f"  重试 {attempt + 1}/4：{text[:12]}… {e}", file=sys.stderr)
                await asyncio.sleep(2 + attempt * 2)
        raise RuntimeError(f"配音失败（检查网络）：{text}")


def duration(path):
    out = subprocess.check_output(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", path])
    return float(out.strip())


def concat(parts, out_wav, workdir):
    # 静音和配音片段统一重采样后拼接；用滤镜脚本文件，避免 Windows 命令行过长
    inputs, filt = [], []
    for k, (kind, v) in enumerate(parts):
        inputs += ["-f", "lavfi", "-i", f"anullsrc=r=44100:cl=mono:d={v:.3f}"] if kind == "sil" else ["-i", v]
        filt.append(f"[{k}:a]aresample=44100,aformat=channel_layouts=mono[a{k}]")
    fc = ";".join(filt) + ";" + "".join(f"[a{k}]" for k in range(len(parts))) + f"concat=n={len(parts)}:v=0:a=1[out]"
    script = os.path.join(workdir, "concat_filter.txt")
    open(script, "w", encoding="utf-8").write(fc)
    subprocess.check_call(["ffmpeg", "-y", "-v", "error", *inputs, "-filter_complex_script", script, "-map", "[out]", out_wav])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("script", nargs="?")
    ap.add_argument("--out", default="assets")
    ap.add_argument("--voice", default="zh-CN-YunyangNeural")
    ap.add_argument("--rate", default="+0%", help="语速，例如 -8%（慢一点）或 +10%")
    ap.add_argument("--gap", type=float, default=0.35, help="句间停顿（秒）")
    ap.add_argument("--para-gap", type=float, default=0.8, help="段落间停顿（秒）")
    ap.add_argument("--lead", type=float, default=0.5, help="开头留白（秒）")
    ap.add_argument("--tail", type=float, default=1.5, help="结尾留白（秒）")
    ap.add_argument("--sample", help="试音模式：用这句话把常用声音各生成一段")
    a = ap.parse_args()
    os.makedirs(a.out, exist_ok=True)
    sem = asyncio.Semaphore(6)

    if a.sample:
        async def run_samples():
            for v, desc in SAMPLE_VOICES.items():
                mp3 = os.path.join(a.out, f"{desc}_{v}.mp3")
                for f in (mp3, mp3 + ".json"):
                    if os.path.exists(f):
                        os.remove(f)
                await synth(a.sample, v, a.rate, mp3, sem)
                os.remove(mp3 + ".json")
                print("试音：", mp3)
        asyncio.run(run_samples())
        return

    if not a.script:
        ap.error("需要稿子文件，或使用 --sample")
    lines = parse_script(a.script)
    if not lines:
        sys.exit("稿子是空的")
    cache = os.path.join(a.out, "tts_cache")
    os.makedirs(cache, exist_ok=True)
    for ln in lines:
        key = hashlib.md5(f"{a.voice}|{a.rate}|{ln['tts']}".encode()).hexdigest()[:12]
        ln["mp3"] = os.path.join(cache, key + ".mp3")

    async def run_all():
        return await asyncio.gather(*(synth(ln["tts"], a.voice, a.rate, ln["mp3"], sem) for ln in lines))

    print(f"合成 {len(lines)} 句，声音 {a.voice} …")
    all_words = asyncio.run(run_all())

    t, parts, out_lines = a.lead, [("sil", a.lead)], []
    for i, (ln, words) in enumerate(zip(lines, all_words)):
        if i:
            g = a.para_gap if ln["para"] != lines[i - 1]["para"] else a.gap
            parts.append(("sil", g))
            t += g
        d = duration(ln["mp3"])
        out_lines.append({
            "index": i, "para": ln["para"], "sub": ln["sub"],
            "start": round(t, 3), "end": round(t + d, 3),
            "words": [[round(t + s, 3), round(t + e, 3), w] for s, e, w in words],
        })
        parts.append(("file", ln["mp3"]))
        t += d
    parts.append(("sil", a.tail))
    t += a.tail

    wav = os.path.join(a.out, "voice.wav")
    concat(parts, wav, cache)
    json.dump({"total": round(t, 3), "voice": a.voice, "lines": out_lines},
              open(os.path.join(a.out, "timeline.json"), "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"完成：{wav}，总长 {t:.1f} 秒；逐词时间见 timeline.json")


if __name__ == "__main__":
    main()

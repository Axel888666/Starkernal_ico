#!/usr/bin/env bash
set -euo pipefail

VARIANTS=("starkernal-flat-transparent.svg" "starkernal-horizontal-transparent.svg" "starkernal-monochrome-transparent.svg")
OUTDIR="exported_icons"
SIZES=(16 32 48 64 96 120 128 152 167 180 192 256 384 512 1024)

# 确保运行目录为脚本所在目录
cd "$(dirname "$0")"

mkdir -p "$OUTDIR"

# 安装/检测（在 GitHub Actions 中我们会 apt-get 安装）
# 判断使用 rsvg-convert（librsvg）或 inkscape；这里按 rsvg-convert 优先
RENDERER="rsvg"
for svg in "${VARIANTS[@]}"; do
  if [ ! -f "$svg" ]; then
    echo "错误：找不到 SVG 文件 $svg"
    exit 1
  fi
done

for svg in "${VARIANTS[@]}"; do
  base=$(basename "$svg" .svg)
  mkdir -p "$OUTDIR/$base"
  echo "处理 $svg -> $OUTDIR/$base"
  for size in "${SIZES[@]}"; do
    out="$OUTDIR/$base/${base}_${size}x${size}.png"
    if command -v rsvg-convert >/dev/null 2>&1; then
      rsvg-convert -w "$size" -h "$size" -f png -o "$out" "$svg"
    elif command -v inkscape >/dev/null 2>&1; then
      inkscape "$svg" --export-type=png --export-filename="$out" --export-width="$size" --export-height="$size" >/dev/null 2>&1
    else
      echo "错误：既没有 rsvg-convert 也没有 inkscape。请先安装 librsvg 或 inkscape。"
      exit 1
    fi
  done

  cp "$OUTDIR/$base/${base}_16x16.png" "$OUTDIR/$base/favicon-16.png"
  cp "$OUTDIR/$base/${base}_32x32.png" "$OUTDIR/$base/favicon-32.png"
  cp "$OUTDIR/$base/${base}_48x48.png" "$OUTDIR/$base/favicon-48.png"

  # 生成 .ico，包含 16/32/48
  convert "$OUTDIR/$base/favicon-16.png" "$OUTDIR/$base/favicon-32.png" "$OUTDIR/$base/favicon-48.png" -colors 256 "$OUTDIR/$base/${base}_favicon.ico"
done

ZIPNAME="starkernal-icons.zip"
rm -f "$ZIPNAME"
zip -r "$ZIPNAME" "$OUTDIR" >/dev/null
echo "生成完成：$ZIPNAME"

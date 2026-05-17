#!/bin/bash
set -u
export PATH="/opt/homebrew/bin:/opt/homebrew/Caskroom/miniforge/base/bin:$PATH"

TS=$(date +%Y%m%d_%H%M%S)
OUT="$HOME/Downloads/daglo_live_${TS}.aac"
LOG="$HOME/Downloads/daglo_live_${TS}.log"
URL="https://www.youtube.com/watch?v=xRA3-DfYzPI"

echo "OUTPUT_FILE=$OUT"
echo "LOG_FILE=$LOG"
echo "START=$(date '+%Y-%m-%d %H:%M:%S')"

yt-dlp --remote-components ejs:github -f 93 -o - "$URL" 2>"$LOG" \
  | ffmpeg -y -i - -vn -c:a copy "$OUT"

echo "END=$(date '+%Y-%m-%d %H:%M:%S') EXIT=$?"
ls -la "$OUT"

#!/usr/bin/env bash
set -u

status=0

if command -v pkg-config >/dev/null 2>&1 \
  && pkg-config --exists SDL2_mixer; then
  echo "[OK] SDL2_mixer development package"
else
  echo "[MISSING] SDL2_mixer development package"
  echo "          Ubuntu/Kubuntu: sudo apt install libsdl2-mixer-dev"
  status=1
fi

if [[ -f assets/levels/stage01.map.editor ]]; then
  count=$(awk '$1 == "PATH_COUNT" && $2 >= 2 {count++} END {print count + 0}' \
    assets/levels/stage01.map.editor)
  echo "[OK] editor path metadata: $count object path(s)"
else
  echo "[MISSING] assets/levels/stage01.map.editor"
  status=1
fi

music=$(awk '/^MUSIC / {sub(/^MUSIC /, ""); print; exit}' \
  assets/levels/stage01.map 2>/dev/null || true)

if [[ -n "$music" && -f "$music" ]]; then
  echo "[OK] level music: $music"
elif [[ -n "$music" ]]; then
  echo "[MISSING] level music: $music"
  status=1
else
  echo "[MISSING] MUSIC field in assets/levels/stage01.map"
  status=1
fi

exit "$status"

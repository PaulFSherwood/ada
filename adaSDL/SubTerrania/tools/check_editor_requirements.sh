#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

failed=0

if command -v alr >/dev/null 2>&1; then
  echo "[OK] alr: $(command -v alr)"
else
  echo "[MISSING] Alire (alr)"
  failed=1
fi

if command -v pkg-config >/dev/null 2>&1 \
   && pkg-config --exists gtk+-3.0; then
  echo "[OK] GTK3 development files"
else
  echo "[MISSING] GTK3 development files"
  echo "          sudo apt install libgtk-3-dev"
  failed=1
fi

for path in \
  assets/ui/subterrania_editor.ui \
  assets/levels/stage01.map \
  src/editor/subterrania_editor.adb \
  subterrania_editor.gpr
 do
  if [[ -e "$path" ]]; then
    echo "[OK] $path"
  else
    echo "[MISSING] $path"
    failed=1
  fi
 done

exit "$failed"

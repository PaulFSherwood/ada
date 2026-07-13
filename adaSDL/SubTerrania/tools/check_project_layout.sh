#!/usr/bin/env bash
set -euo pipefail

echo "== Asset layout =="
find assets -maxdepth 3 -type d | sort

echo
if [[ -f assets/levels/stage01.map ]]; then
  echo "OK: assets/levels/stage01.map exists"
else
  echo "MISSING: assets/levels/stage01.map"
fi

echo
if [[ -d images ]]; then
  echo "WARNING: top-level images/ still exists. It should normally be under assets/images/."
else
  echo "OK: no top-level images/ directory"
fi

echo
if [[ -f level01.map ]]; then
  echo "WARNING: root level01.map still exists. Current default should be assets/levels/stage01.map."
else
  echo "OK: no root level01.map"
fi

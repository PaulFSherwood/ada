#!/usr/bin/env bash
set -euo pipefail

mkdir -p assets/levels assets/images/maps assets/images/sprites

if [[ -f level01.map && ! -f assets/levels/stage01.map ]]; then
  cp level01.map assets/levels/stage01.map
fi

if [[ -d images/maps ]]; then
  cp -n images/maps/* assets/images/maps/ 2>/dev/null || true
fi

if [[ -d images/sprites ]]; then
  cp -n images/sprites/* assets/images/sprites/ 2>/dev/null || true
fi

printf 'Phase 10 layout migration complete.\n'
printf 'Default level: assets/levels/stage01.map\n'
printf 'Old images/ and level01.map are left in place so nothing is lost.\n'

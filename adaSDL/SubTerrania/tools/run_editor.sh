#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ ! -x bin/subterrania_editor ]]; then
  tools/build_editor.sh
fi
GTK_THEME="${GTK_THEME:-Adwaita:dark}" alr exec -- ./bin/subterrania_editor

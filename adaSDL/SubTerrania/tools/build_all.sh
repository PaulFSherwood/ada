#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
alr build
tools/build_editor.sh

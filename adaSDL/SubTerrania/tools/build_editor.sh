#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
alr exec -- gprbuild -p -P subterrania_editor.gpr

#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK_PATH="${PLAYDATE_SDK_PATH:-$ROOT/PlaydateSDK}"

if [[ ! -x "$SDK_PATH/bin/pdc" ]]; then
  echo "Playdate SDK not found at: $SDK_PATH"
  echo "Set PLAYDATE_SDK_PATH or run ./install-sdk-ubuntu.sh"
  exit 1
fi

export PLAYDATE_SDK_PATH="$SDK_PATH"

# Deterministic pack → imagetable import (fails if packs missing; no fallback art)
python3 "$ROOT/tools/import_packs.py"

OUT="$ROOT/ZnomeKop.pdx"
rm -rf "$OUT"
"$SDK_PATH/bin/pdc" -sdkpath "$SDK_PATH" "$ROOT/source" "$OUT"
echo "Built $OUT"

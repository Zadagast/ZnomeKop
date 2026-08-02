#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
SDK_PATH="${PLAYDATE_SDK_PATH:-$ROOT/PlaydateSDK}"

if [[ ! -x "$SDK_PATH/bin/pdc" ]]; then
  echo "Playdate SDK not found at: $SDK_PATH"
  echo "Set PLAYDATE_SDK_PATH or place the SDK at ./PlaydateSDK"
  exit 1
fi

export PLAYDATE_SDK_PATH="$SDK_PATH"

# Regenerate 1-bit assets when the generator or outputs change
python3 "$ROOT/tools/generate_assets.py"

OUT="$ROOT/ZnomeKop.pdx"
rm -rf "$OUT"
"$SDK_PATH/bin/pdc" -sdkpath "$SDK_PATH" "$ROOT/source" "$OUT"
echo "Built $OUT"

#!/usr/bin/env bash
# Open the prebuilt game in Playdate Simulator (Ubuntu / Linux / macOS).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PDX="$ROOT/ZnomeKop.pdx"

if [[ ! -d "$PDX" ]]; then
  echo "Missing $PDX"
  echo "Pull latest, or run ./build.sh first."
  exit 1
fi

SDK_PATH="${PLAYDATE_SDK_PATH:-}"
if [[ -z "$SDK_PATH" ]]; then
  for candidate in \
    "$ROOT/PlaydateSDK" \
    "$HOME/PlaydateSDK" \
    "$HOME/Documents/PlaydateSDK" \
    "$HOME/Developer/PlaydateSDK"
  do
    if [[ -x "$candidate/bin/PlaydateSimulator" ]]; then
      SDK_PATH="$candidate"
      break
    fi
  done
fi

SIM=""
if [[ -n "$SDK_PATH" && -x "$SDK_PATH/bin/PlaydateSimulator" ]]; then
  SIM="$SDK_PATH/bin/PlaydateSimulator"
elif command -v PlaydateSimulator >/dev/null 2>&1; then
  SIM="$(command -v PlaydateSimulator)"
fi

if [[ -z "$SIM" ]]; then
  echo "Playdate Simulator not found."
  echo "Install the SDK from https://play.date/dev/ then either:"
  echo "  export PLAYDATE_SDK_PATH=/path/to/PlaydateSDK"
  echo "  ./run-local.sh"
  echo
  echo "Or open this folder manually in the Simulator:"
  echo "  $PDX"
  exit 1
fi

echo "Launching: $SIM"
echo "Game:      $PDX"
echo "Controls:  Arrows=D-pad   S=A   A=B"
exec "$SIM" "$PDX"

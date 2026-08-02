#!/usr/bin/env bash
# Open the prebuilt game in Playdate Simulator (Ubuntu / Linux / macOS).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
PDX="$ROOT/ZnomeKop.pdx"

if [[ ! -d "$PDX" ]]; then
  echo "Missing $PDX"
  echo "Pull latest, or unzip ZnomeKop.pdx.zip first."
  exit 1
fi

find_simulator() {
  local candidate

  # 1) Explicit env var
  if [[ -n "${PLAYDATE_SDK_PATH:-}" ]]; then
    candidate="$PLAYDATE_SDK_PATH/bin/PlaydateSimulator"
    if [[ -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  # 2) Common install locations
  local paths=(
    "$ROOT/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/Documents/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/Developer/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/Downloads/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/Downloads/PlaydateSDK-"*/bin/PlaydateSimulator
    "$HOME/playdate/PlaydateSDK/bin/PlaydateSimulator"
    "$HOME/.local/share/PlaydateSDK/bin/PlaydateSimulator"
    "/opt/PlaydateSDK/bin/PlaydateSimulator"
    "/usr/local/PlaydateSDK/bin/PlaydateSimulator"
  )
  for candidate in "${paths[@]}"; do
    # Expand globs safely
    for expanded in $candidate; do
      if [[ -x "$expanded" ]]; then
        echo "$expanded"
        return 0
      fi
    done
  done

  # 3) On PATH
  if command -v PlaydateSimulator >/dev/null 2>&1; then
    command -v PlaydateSimulator
    return 0
  fi

  # 4) Desktop / menu entry
  local desktop
  for desktop in \
    "$HOME/.local/share/applications/"*laydate*.desktop \
    "/usr/share/applications/"*laydate*.desktop
  do
    if [[ -f "$desktop" ]]; then
      local exec_line
      exec_line="$(grep -E '^Exec=' "$desktop" | head -1 | sed 's/^Exec=//' | awk '{print $1}')"
      if [[ -n "$exec_line" && -x "$exec_line" ]]; then
        echo "$exec_line"
        return 0
      fi
    fi
  done

  # 5) Last-resort locate (fast paths only)
  if command -v locate >/dev/null 2>&1; then
    candidate="$(locate -b '\PlaydateSimulator' 2>/dev/null | head -1 || true)"
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      echo "$candidate"
      return 0
    fi
  fi

  return 1
}

SIM="$(find_simulator || true)"

if [[ -z "$SIM" ]]; then
  cat <<EOF
Playdate Simulator not found automatically.

Your game file is ready here:
  $PDX

EASIEST if Simulator is already open:
  File → Open… → select the ZnomeKop.pdx folder
  (or drag ZnomeKop.pdx onto the Simulator window)

Find your SDK install, then rerun:
  find ~ -type f -name PlaydateSimulator 2>/dev/null

Then:
  export PLAYDATE_SDK_PATH="/path/to/PlaydateSDK"
  ./run-local.sh

Tip: add that export line to ~/.bashrc so it sticks.
EOF
  exit 1
fi

echo "Launching: $SIM"
echo "Game:      $PDX"
echo "Controls:  Arrows=D-pad   S=A   A=B"
exec "$SIM" "$PDX"

#!/usr/bin/env bash
# Download + install Playdate SDK for Ubuntu into ~/PlaydateSDK
# (We cannot ship the SDK in this repo — Panic's license forbids redistribution.)
set -euo pipefail

SDK_HOME="${PLAYDATE_SDK_PATH:-$HOME/PlaydateSDK}"
TMP_TGZ="/tmp/PlaydateSDK-latest.tar.gz"
URL="https://download.panic.com/playdate_sdk/Linux/PlaydateSDK-latest.tar.gz"

cat <<EOF
Playdate SDK installer for Ubuntu
=================================
This downloads Panic's SDK to:
  $SDK_HOME

Panic's license does NOT allow redistributing the SDK with games.
You must agree to their license at https://play.date/dev/

EOF

read -r -p "Type YES to download and install the SDK: " answer
if [[ "$answer" != "YES" ]]; then
  echo "Cancelled."
  exit 1
fi

echo "Downloading..."
wget -O "$TMP_TGZ" "$URL"

echo "Extracting..."
TMP_DIR="$(mktemp -d)"
tar xf "$TMP_TGZ" -C "$TMP_DIR"
EXTRACTED="$(find "$TMP_DIR" -maxdepth 1 -type d -name 'PlaydateSDK*' | head -1)"
if [[ -z "$EXTRACTED" ]]; then
  echo "Could not find extracted SDK folder."
  exit 1
fi

rm -rf "$SDK_HOME"
mkdir -p "$(dirname "$SDK_HOME")"
mv "$EXTRACTED" "$SDK_HOME"
rm -rf "$TMP_DIR" "$TMP_TGZ"

if [[ -x "$SDK_HOME/setup.sh" ]]; then
  echo "Running setup.sh (may ask for sudo)..."
  (cd "$SDK_HOME" && sudo ./setup.sh) || echo "setup.sh skipped/failed (often fine for Simulator-only use)"
fi

# Persist env for bash users
if ! grep -q 'PLAYDATE_SDK_PATH' "$HOME/.bashrc" 2>/dev/null; then
  {
    echo ''
    echo '# Playdate SDK'
    echo "export PLAYDATE_SDK_PATH=\"$SDK_HOME\""
    echo 'export PATH="$PLAYDATE_SDK_PATH/bin:$PATH"'
  } >> "$HOME/.bashrc"
fi

export PLAYDATE_SDK_PATH="$SDK_HOME"
export PATH="$PLAYDATE_SDK_PATH/bin:$PATH"

echo
echo "Installed."
echo "  PLAYDATE_SDK_PATH=$PLAYDATE_SDK_PATH"
echo "  Simulator: $PLAYDATE_SDK_PATH/bin/PlaydateSimulator"
echo
echo "Run in THIS terminal (or open a new one):"
echo "  source ~/.bashrc"
echo "  cd ~/Desktop/ZnomeKop   # or wherever you cloned it"
echo "  ./run-local.sh"

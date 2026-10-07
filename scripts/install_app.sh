#!/bin/bash
set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
"$DIR/scripts/package_app.sh"
APP_NAME="VisualBarTimer"
BUNDLE_DIR="$DIR/build/$APP_NAME.app"

# /Applications への配置
TARGET_APP="/Applications/$APP_NAME.app"
USER_APP="$HOME/Applications/$APP_NAME.app"

echo "==> Installing to Applications folder..."
if rm -rf "$TARGET_APP" 2>/dev/null && cp -R "$BUNDLE_DIR" "$TARGET_APP" 2>/dev/null; then
    echo " Successfully installed to $TARGET_APP"
else
    echo "==> Falling back to $USER_APP..."
    mkdir -p "$HOME/Applications"
    rm -rf "$USER_APP"
    cp -R "$BUNDLE_DIR" "$USER_APP"
    echo " Successfully installed to $USER_APP"
fi

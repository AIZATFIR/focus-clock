#!/usr/bin/env bash
# Focus Clock Desktop Launcher Installer
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
EXEC_PATH="$DIR/build/linux/x64/release/bundle/focus_clock"
ICON_PATH="$DIR/assets/app_icon.png"
LAUNCHER_PATH="$HOME/.local/share/applications/focus-clock.desktop"

echo "▶ Setting up Focus Clock desktop launcher..."

if [ ! -f "$EXEC_PATH" ]; then
  echo "⚠️ Warning: Release binary not found at $EXEC_PATH."
  echo "Please make sure 'flutter build linux' completes successfully first."
fi

cat <<EOF > "$LAUNCHER_PATH"
[Desktop Entry]
Version=1.0
Type=Application
Name=Focus Clock
Comment=Time-blocking app with analog clock workspace
Exec="$EXEC_PATH"
Icon=$ICON_PATH
Terminal=false
Categories=Utility;Productivity;
EOF

chmod +x "$LAUNCHER_PATH"
echo "✅ Desktop launcher installed successfully at $LAUNCHER_PATH!"
echo "You can now launch Focus Clock from your applications menu/launcher."

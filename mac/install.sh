#!/bin/bash
# Install the agent and start it at login.
set -euo pipefail
cd "$(dirname "$0")"

LABEL="com.therockware.agent"
DEST_DIR="$HOME/Library/Application Support/TheRockWare"
DEST="$DEST_DIR/therockware"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

[ -x build/therockware ] || ./build.sh

# Stop any running copy before overwriting it.
launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -f "$DEST" 2>/dev/null || true

# Clear out the pre-rename install (the-rock-click), if one is lying around.
LEGACY_LABEL="com.therockclick.agent"
LEGACY_DIR="$HOME/Library/Application Support/TheRockClick"
launchctl bootout "gui/$(id -u)/$LEGACY_LABEL" 2>/dev/null || true
pkill -f "$LEGACY_DIR/the-rock-click" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LEGACY_LABEL.plist" "/tmp/$LEGACY_LABEL.log"
rm -rf "$LEGACY_DIR"

mkdir -p "$DEST_DIR" "$HOME/Library/LaunchAgents"
cp build/therockware "$DEST"
codesign --force --sign - "$DEST"

cat > "$PLIST" <<PLISTEOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>              <string>$LABEL</string>
  <key>ProgramArguments</key>   <array><string>$DEST</string></array>
  <key>RunAtLoad</key>          <true/>
  <key>KeepAlive</key>          <false/>
  <key>StandardOutPath</key>    <string>/tmp/$LABEL.log</string>
  <key>StandardErrorPath</key>  <string>/tmp/$LABEL.log</string>
</dict>
</plist>
PLISTEOF

launchctl bootstrap "gui/$(id -u)" "$PLIST"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

cat <<MSG

Installed: $DEST
Login item: $PLIST
Log:        /tmp/$LABEL.log

One-time setup: grant Accessibility so it can see clicks.
  System Settings > Privacy & Security > Accessibility > + > add
    $DEST
  (a prompt should have just appeared; the 🪨 menu bar icon shows ⚠️ until
   permission lands, then it goes live on its own -- no restart needed)

Menu bar 🪨: Pause / Test Pop / Quit.  Remove with ./uninstall.sh

Renamed from the-rock-click? The old install is gone, but its stale
Accessibility entry is not -- drop it from that same list.
MSG

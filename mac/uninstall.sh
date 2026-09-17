#!/bin/bash
# Remove the agent completely.
set -euo pipefail

LABEL="com.therockware.agent"
DEST_DIR="$HOME/Library/Application Support/TheRockWare"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"

launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
pkill -f "$DEST_DIR/therockware" 2>/dev/null || true
rm -f "$PLIST"
rm -rf "$DEST_DIR"
rm -f "/tmp/$LABEL.log"

# Clear out the pre-rename install (the-rock-click), if one is lying around.
LEGACY_LABEL="com.therockclick.agent"
LEGACY_DIR="$HOME/Library/Application Support/TheRockClick"
launchctl bootout "gui/$(id -u)/$LEGACY_LABEL" 2>/dev/null || true
pkill -f "$LEGACY_DIR/the-rock-click" 2>/dev/null || true
rm -f "$HOME/Library/LaunchAgents/$LEGACY_LABEL.plist" "/tmp/$LEGACY_LABEL.log"
rm -rf "$LEGACY_DIR"


echo "Uninstalled. Drop the stale entry from System Settings > Privacy &"
echo "Security > Accessibility if you want it fully gone."

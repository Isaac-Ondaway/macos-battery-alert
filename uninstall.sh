#!/bin/bash
set -eu

INSTALL_DIR="${BATTERY_ALERT_INSTALL_DIR:-${HOME}/.local/share/macos-battery-alert}"
LABEL="com.user.macos-battery-alert"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

if command -v launchctl >/dev/null 2>&1 && [ -f "$PLIST" ]; then
    launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
fi
rm -f "$PLIST"
rm -rf "$INSTALL_DIR"
echo "Removed ${LABEL} and its installed script. Your config and alert state were kept."

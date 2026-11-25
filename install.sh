#!/bin/bash
set -eu

PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
INSTALL_DIR="${BATTERY_ALERT_INSTALL_DIR:-${HOME}/.local/share/macos-battery-alert}"
AGENT_DIR="${HOME}/Library/LaunchAgents"
LABEL="com.user.macos-battery-alert"
PLIST="${AGENT_DIR}/${LABEL}.plist"

case "$(uname -s)" in
    Darwin) ;;
    *) echo "This project requires macOS." >&2; exit 1 ;;
esac

mkdir -p "$INSTALL_DIR" "$AGENT_DIR" "${HOME}/.config/macos-battery-alert"
install -m 755 "${PROJECT_DIR}/battery-alert.sh" "${INSTALL_DIR}/battery-alert.sh"

if [ ! -f "${HOME}/.config/macos-battery-alert/config" ]; then
    cat > "${HOME}/.config/macos-battery-alert/config" <<'CONFIG'
# Alert at or below this percentage while running on battery power.
ALERT_THRESHOLD=40
# Re-arm the alert after charging above this percentage.
RESET_THRESHOLD=45
# Use an empty value for no sound. Example: NOTIFICATION_SOUND=Glass
NOTIFICATION_SOUND=Glass
CONFIG
fi

# XML-escape the paths inserted into the plist.
PLIST_SCRIPT=$(printf '%s' "${INSTALL_DIR}/battery-alert.sh" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'"'"'/\&apos;/g')
cat > "$PLIST" <<PLIST_CONTENT
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${PLIST_SCRIPT}</string>
    </array>
    <key>StartInterval</key>
    <integer>300</integer>
    <key>RunAtLoad</key>
    <true/>
</dict>
</plist>
PLIST_CONTENT

if command -v launchctl >/dev/null 2>&1; then
    launchctl bootout "gui/$(id -u)" "$PLIST" >/dev/null 2>&1 || true
    launchctl bootstrap "gui/$(id -u)" "$PLIST"
fi

echo "Installed and loaded ${LABEL}. It checks every 5 minutes."
echo "Edit ${HOME}/.config/macos-battery-alert/config to change thresholds."

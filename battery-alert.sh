#!/bin/bash
# Notify once when a portable Mac's battery reaches the alert threshold.
# Compatible with the Bash 3.2 shipped with macOS.

set -u

CONFIG_FILE="${BATTERY_ALERT_CONFIG:-${HOME}/.config/macos-battery-alert/config}"
ALERT_THRESHOLD=40
RESET_THRESHOLD=45
NOTIFICATION_SOUND=Glass

if [ -r "$CONFIG_FILE" ]; then
    while IFS='=' read -r key value || [ -n "${key:-}" ]; do
        case "$key" in
            ''|'#'*) continue ;;
            ALERT_THRESHOLD) ALERT_THRESHOLD=$value ;;
            RESET_THRESHOLD) RESET_THRESHOLD=$value ;;
            NOTIFICATION_SOUND) NOTIFICATION_SOUND=$value ;;
        esac
    done < "$CONFIG_FILE"
fi

# Environment variables take precedence over the optional config file.
ALERT_THRESHOLD=${BATTERY_ALERT_THRESHOLD:-$ALERT_THRESHOLD}
RESET_THRESHOLD=${BATTERY_RESET_THRESHOLD:-$RESET_THRESHOLD}
NOTIFICATION_SOUND=${BATTERY_ALERT_SOUND:-$NOTIFICATION_SOUND}
STATE_FILE=${BATTERY_ALERT_STATE_FILE:-"${HOME}/.battery-alert-sent"}

case "$ALERT_THRESHOLD:$RESET_THRESHOLD" in
    *[!0-9:]*|:*|*:) echo "Battery thresholds must be whole numbers." >&2; exit 2 ;;
esac
if [ "$ALERT_THRESHOLD" -lt 0 ] || [ "$ALERT_THRESHOLD" -gt 100 ] || \
   [ "$RESET_THRESHOLD" -lt 0 ] || [ "$RESET_THRESHOLD" -gt 100 ] || \
   [ "$RESET_THRESHOLD" -le "$ALERT_THRESHOLD" ]; then
    echo "Thresholds must be 0–100, and reset must be greater than alert." >&2
    exit 2
fi

if ! command -v pmset >/dev/null 2>&1; then
    echo "pmset was not found; this script requires macOS." >&2
    exit 1
fi

BATT_OUTPUT=$(pmset -g batt 2>/dev/null) || exit 1
BATTERY=$(printf '%s\n' "$BATT_OUTPUT" | sed -n 's/.*[^0-9]\([0-9][0-9]*\)%.*/\1/p' | head -n 1)
POWER=$(printf '%s\n' "$BATT_OUTPUT" | head -n 1)

# Desktop Macs and systems that do not report an internal battery are ignored.
case "$BATTERY" in
    ''|*[!0-9]*) exit 0 ;;
esac

# Keep the original hysteresis: re-arm only after charging above 45% by default.
if [ "$BATTERY" -gt "$RESET_THRESHOLD" ]; then
    rm -f "$STATE_FILE"
    exit 0
fi

if [[ "$POWER" == *"Battery Power"* ]] && [ "$BATTERY" -le "$ALERT_THRESHOLD" ] && [ ! -f "$STATE_FILE" ]; then
    if [ -n "$NOTIFICATION_SOUND" ]; then
        osascript -e "display notification \"Battery is at ${BATTERY}% (alert threshold: ${ALERT_THRESHOLD}%). Time to charge!\" with title \"Mac Low Battery\" sound name \"${NOTIFICATION_SOUND}\""
    else
        osascript -e "display notification \"Battery is at ${BATTERY}% (alert threshold: ${ALERT_THRESHOLD}%). Time to charge!\" with title \"Mac Low Battery\""
    fi
    touch "$STATE_FILE"
fi

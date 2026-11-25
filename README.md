# macOS Battery Alert

A small Bash utility that sends a native macOS notification when a portable Mac is running on battery power and reaches a configurable low-battery threshold. It uses macOS `pmset`, `osascript`, and `launchd`; it has no third-party dependencies.

## Defaults

- Alert once at **40% or below** while on battery power.
- Re-arm after the battery rises **above 45%**.
- Check every **5 minutes** when installed as a LaunchAgent.
- Ignore Macs that do not report a battery.

This preserves the behavior of the original personal script. Its state file is `~/.battery-alert-sent`.

## Install

Download or clone this repository, then run:

```sh
chmod +x install.sh
./install.sh
```

The installer copies the monitor to `~/.local/share/macos-battery-alert/`, creates a per-user LaunchAgent, and loads it for the current login session. No administrator password is needed. macOS may require notification permission for the process that runs `osascript`; notification presentation can vary by macOS version and user settings.

## Configure

Edit `~/.config/macos-battery-alert/config`:

```sh
ALERT_THRESHOLD=40
RESET_THRESHOLD=45
NOTIFICATION_SOUND=Glass
```

The alert threshold must be from 0 to 100, and the reset threshold must be greater than the alert threshold and no more than 100. Set `NOTIFICATION_SOUND=` to disable the sound. Changes take effect on the next check. For a one-off run, environment variables `BATTERY_ALERT_THRESHOLD`, `BATTERY_RESET_THRESHOLD`, `BATTERY_ALERT_SOUND`, `BATTERY_ALERT_CONFIG`, and `BATTERY_ALERT_STATE_FILE` can override the settings.

## Uninstall

Run `./uninstall.sh` from the project directory. This unloads and removes the LaunchAgent and installed script. It keeps your config and alert state.

## Compatibility and limitations

- Requires macOS and a Mac that reports an internal battery. Intel and Apple silicon MacBook Air and MacBook Pro models are expected to work; desktop Macs are ignored.
- Uses the Bash 3.2 supplied with macOS and built-in command-line tools. Tested behavior can still differ across macOS releases, especially notification permissions and `launchd` behavior.
- Runs as your logged-in user, not as a daemon. Checks pause while logged out or asleep and resume when launchd runs the job again.
- Notifications are evaluated only every five minutes, so the alert may arrive after crossing the threshold.
- It does not change charging behavior or manage battery health.

## License

MIT. See [LICENSE](LICENSE).

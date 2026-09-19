# Kanata

This module provides an optional Kanata version of the current Karabiner keyboard mapping. Only one remapper should be active at a time.

## Mapping

- Tap Caps Lock: Escape.
- Hold Caps Lock: left Control.
- Double-tap and hold Caps Lock: Hyper (left Control + Option + Command + Shift).
- While Hyper is held, H/J/K/L send Left/Down/Up/Right.
- Tap/hold thresholds: 150 ms; double-tap window: 300 ms, matching the current Karabiner window.
- Escape is suppressed when the second tap becomes a held Hyper press. A lone Caps Lock tap may wait for the double-tap window; pressing another key can resolve the tap sooner.

## Prerequisites

Kanata uses the Karabiner VirtualHIDDevice driver on macOS and must run as root. This machine already has Karabiner-Elements and its driver installed. The current Kanata main branch requires a compatible v8-or-newer VirtualHIDDevice driver; do not replace or uninstall the existing driver without checking compatibility first. Kanata also needs Input Monitoring and Accessibility permissions in System Settings.

Build/install Kanata from the current source with Homebrew:

```sh
brew install --HEAD kanata
```

Open the Kanata binary once or add it manually in System Settings if macOS does not prompt for permissions. Kanata's [macOS setup guide](https://github.com/jtroo/kanata/blob/main/docs/setup-macos.md) has current driver and permission details.

## Daemon and switching

Install the LaunchDaemon in a disabled state; this requires an administrator password and does not enable Kanata:

```sh
make kanata-service-install
```

Switch the active mapping, or switch back to Karabiner:

```sh
make keyboard-kanata
make keyboard-karabiner
```

Manual lifecycle and refresh commands:

```sh
make kanata-start
make kanata-stop
make kanata-restart       # reload the Kanata config
make kanata-status
make karabiner-refresh
make kanata-service-uninstall
```

Switching to Kanata disables and stops Karabiner's Core Service first, then removes only this repository's config symlink (the tracked JSON stays in the repo) and starts Kanata. Switching back stops and disables Kanata for the next boot, restores the Karabiner symlink, re-enables/restarts its Core Service, and refreshes the config watcher. If Kanata cannot start, the switch script attempts to restore Karabiner automatically. The switch helper uses the existing symlink manager and macOS `launchctl`; it does not use `karabiner_cli`.

Use the `keyboard-kanata` and `keyboard-karabiner` targets for normal switching. The individual service and Core Service targets are low-level controls and do not change the other remapper's state or config link.

The LaunchDaemon is installed but disabled until explicitly started. Kanata is configured to start at boot only while its service is enabled. `make kanata-stop` disables it across reboots; `make kanata-service-uninstall` also removes only the module's LaunchDaemon plist. These commands do not uninstall the Homebrew package or the shared Karabiner driver.

Before uninstalling the service while Kanata is active, run `make keyboard-karabiner` first so the Karabiner config link and Core Service are restored.

For a first test, install the service and use `make keyboard-kanata`; this starts Kanata only after disabling Karabiner and is easy to reverse with `make keyboard-karabiner`. If key input is disrupted, use Kanata's emergency chord (left Control + Space + Escape) or switch back with `make keyboard-karabiner` from another working keyboard/input method.

# Kanata

This module provides an optional Kanata version of the current Karabiner keyboard mapping. Only one remapper should be active at a time.

## Mapping

- Tap Caps Lock: Escape.
- Hold Caps Lock: left Control.
- Double-tap and hold Caps Lock: Hyper (left Control + Option + Command + Shift).
- While Hyper is held, H/J/K/L send plain Left/Down/Up/Right. These actions temporarily release the Hyper modifiers with `unmod`, then restore them when the navigation key is released; other Hyper shortcuts retain the modifiers.
- Hold threshold: 150 ms; double-tap window: 100 ms after the first tap is released. Pressing another key while Caps Lock is held activates its modifier sooner.
- Escape is suppressed when the second press becomes a held Hyper press. A lone Caps Lock tap waits up to 100 ms after release; pressing another key can resolve the tap sooner. Two quick taps produce one Escape.

The first press resolves as a tap or Control hold before double-tap detection begins. This gives the second press the full 100 ms after release and keeps the first hold responsive at 150 ms. Both tap-repress timeouts are zero so a rapid subsequent hold can activate its modifier.

## Mouse isolation

The MX Master 2S also appears in Kanata's keyboard-device list. The config excludes it with `macos-dev-names-exclude` so Kanata does not capture that device. Other keyboards remain automatically detected, keeping the config usable across machines without a keyboard allowlist.

If another mouse is affected, run `kanata --list` and add its exact reported name to the exclusion list. Kanata's [macOS device-filter documentation](https://github.com/jtroo/kanata/blob/main/docs/config.adoc#macos-only-macos-dev-names-exclude) describes this option.

Device-filter changes require a full restart, not a live config reload. If Karabiner is active, use `make keyboard-kanata`; if Kanata is already active, use `make kanata-restart`. Test pointer movement, scrolling, and buttons after switching. Use `make keyboard-karabiner` if the mouse still misbehaves.

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

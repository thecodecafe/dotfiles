# Karabiner Elements

This module configures Karabiner Elements so Caps Lock acts as Escape when tapped, Control when held, and Hyper when double-tapped and held.

## Dependencies

- [Karabiner Elements](https://karabiner-elements.pqrs.org/) installed on macOS.
- A macOS user account allowed to grant Karabiner its required Input Monitoring permissions.

## Key behavior

- Tap `Caps Lock`: Escape.
- Hold `Caps Lock`: left Control.
- Double-tap and hold `Caps Lock`: `Control + Option + Command + Shift` (Hyper).
- While Hyper is held, `h/j/k/l`: Left/Down/Up/Right arrow.
- Tap-versus-hold timeout and held-down threshold: 150 ms.
- Double-tap detection window: 300 ms.

## Install

```sh
make karabiner
```

This links `karabiner/karabiner.json` to `~/.config/karabiner/karabiner.json`. If a real destination exists, the link manager asks for confirmation and creates a timestamped sibling backup before replacing it. Unrelated symlinks are never replaced.

After linking, restart Karabiner Elements or reload its configuration from the Karabiner menu so the profile is applied.

Remove only the repository-owned link with:

```sh
make unlink-karabiner
```

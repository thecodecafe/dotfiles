# WezTerm

This module mirrors the Ghostty font and core colors, with a subtly lighter active tab (`#1A1A1A`) against the black terminal background.

## Install

```sh
make wezterm
```

This links `wezterm/wezterm.lua` to `~/.config/wezterm/wezterm.lua`. Existing files are handled by the repository's safe link manager, which asks before replacing a real file and keeps a backup.

Remove only the repository-owned link with:

```sh
make unlink-wezterm
```

The WezTerm config reloads automatically when saved. You can also force a reload with `Ctrl+Shift+R`.

# AeroSpace

This module manages the AeroSpace window-manager configuration imported from the existing local setup. The initial `aerospace.toml` is preserved verbatim as the starting point for repository-managed customization.

## Dependencies

- AeroSpace installed and available on the machine.

## Install

```sh
make aerospace
```

This creates `~/.config/aerospace/aerospace.toml` (or the matching `$XDG_CONFIG_HOME` path when using the link manager directly) as a symlink to this module's configuration file. Existing unrelated destinations are never overwritten.

Remove only the repository-owned link with:

```sh
make unlink-aerospace
```

The destination can be overridden with `AEROSPACE_CONFIG_FILE=/path/to/aerospace.toml make aerospace`.

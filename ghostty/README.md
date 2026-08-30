# Ghostty

This module configures Ghostty's visual defaults: CommitMono Nerd Font Mono at 12pt, Gruvbox-inspired dark colors, opaque background, and orange cursor/selection accents.

## Dependencies

- Ghostty installed and available on the machine.
- `CommitMono Nerd Font Mono` installed for the configured font family.

## Install

```sh
make ghostty
```

This creates `~/.config/ghostty/config` (or `$XDG_CONFIG_HOME/ghostty/config`) as a symlink to this module's `config` file. Existing unrelated symlinks are never overwritten. If a real file is present, linking asks for confirmation and backs it up beside the destination before replacing it.

Remove only the repository-owned link with:

```sh
make unlink-ghostty
```

Validate the configuration with `make test` when Ghostty is installed.

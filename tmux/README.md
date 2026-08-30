# tmux

The tmux configuration keeps `Ctrl-b` as the prefix, enables true-color-related terminal overrides, mouse support, and vi copy mode, and provides keyboard-driven pane management. It also integrates tmux with Neovim and preserves sessions through tmux-resurrect and tmux-continuum.

## Key behavior

- `Ctrl-b`, then `\`: horizontal split; `Ctrl-b`, then `-`: vertical split.
- `Ctrl-b`, then `h/j/k/l`: resize the active pane.
- `Ctrl-b`, then `m`: zoom/unzoom the active pane.
- `Ctrl-b`, then `r`: reload `~/.config/tmux/tmux.conf`.
- `Ctrl-b`, then `M-c`: attach/create a session from the active pane's directory.
- Mouse and vi copy mode are enabled; use `v` to select and `y` to copy.
- `Ctrl-b`, then `d`: detach from the current session (tmux's standard binding).

## Dependencies

- `tmux`.
- Git and network access for the first TPM installation.
- TPM at `~/.tmux/plugins/tpm`.
- Declared TPM plugins: `vim-tmux-navigator`, `tmux-power`, `tmux-resurrect`, and `tmux-continuum`.

## Install

```sh
make tmux
make tmux-tpm
```

`make tmux` links `tmux/tmux.conf` to `~/.config/tmux/tmux.conf`. `make tmux-tpm` safely installs TPM if needed, reloads an available tmux server, and runs TPM's plugin installer. It is intentionally separate from `make all` because it uses the network. Afterward, TPM's standard update/install workflow is `Ctrl-b`, then `I`.

Remove only the repository-owned configuration link with:

```sh
make unlink-tmux
```

Use `make test` to validate bindings and configuration in an isolated tmux server.


# Dotfiles

Personal development-machine configuration for AeroSpace, Ghostty, tmux, Neovim, and reusable agent skills. The repository keeps configuration in version control and uses safe symlink managers to install it into standard user locations.

## Modules

| Module | Purpose | Guide |
| --- | --- | --- |
| Ghostty | Terminal appearance and behavior | [ghostty/README.md](ghostty/README.md) |
| AeroSpace | macOS window management and workspace bindings | [aerospace/README.md](aerospace/README.md) |
| Karabiner Elements | Keyboard remapping and Hyper-key navigation | [karabiner/README.md](karabiner/README.md) |
| tmux | Multiplexing, panes, persistence, and terminal integration | [tmux/README.md](tmux/README.md) |
| Neovim | Lazy.nvim-based editor configuration | [nvim/README.md](nvim/README.md) |
| Skills | Shared `aidlc`, `commit`, and `maprepo` workflows | [skills/README.md](skills/README.md) |
| Key repeat | macOS keyboard repetition and press-and-hold settings | [key-repeat/README.md](key-repeat/README.md) |

## Prerequisites

- macOS or another Unix-like system with a POSIX shell, `make`, and `git`.
- [Ghostty](https://ghostty.org/) and the `CommitMono Nerd Font Mono` font for the terminal module.
- [AeroSpace](https://github.com/nikitabobko/AeroSpace) for the window-management module.
- [Karabiner Elements](https://karabiner-elements.pqrs.org/) for the keyboard-remapping module.
- `tmux` for the tmux module. TPM and its plugins are installed separately over the network.
- Neovim with Git. Neovim also expects a Go installation for `gopls`; the editor installs configured language servers through Mason.
- `python3`, a C compiler (`cc`), and `make` if installing Neovim's Lua 5.1/LuaRocks environment with `make nvim-luarocks`.
- macOS is required for the optional `make key-repeat` target; it uses the built-in `defaults` command.

## Setup

From the repository root:

```sh
make all                 # link skills, AeroSpace, Ghostty, Karabiner, Neovim, and tmux
make karabiner          # link the Karabiner Elements configuration
make nvim-luarocks       # optional, enables Lua 5.1/LuaRocks support
make tmux-tpm            # explicit networked TPM/plugin installation
make key-repeat          # optional macOS-wide keyboard settings
make reset-key-repeat    # remove key-repeat overrides
make test                # run configuration and installer tests
```

`make all` does not install networked dependencies. On first Neovim launch, lazy.nvim bootstraps itself and installs the declared plugins. Mason manages the configured language servers. TPM installs tmux plugins only when `make tmux-tpm` is run (or through TPM's normal `Ctrl-b`, then `I` workflow).

Each link target protects unrelated symlinks. When a real file or directory already exists, it asks for confirmation before moving it to a sibling `<name>-backup-<unix timestamp>` path and creating the repository link. Unlink targets remove only links owned by this repository:

```sh
make unlink-all
```

Destination paths can be overridden on the command line; see the module guides and `make help` for variable names.

## Repository structure

- `aerospace/`, `ghostty/`, `karabiner/`, `tmux/`, and `nvim/` contain source configurations.
- `skills/` contains the reusable skill definitions.
- `key-repeat/` contains the macOS keyboard repetition script.
- `scripts/` contains safe link and dependency installers.
- `tests/` contains offline-friendly shell tests for the managers and configurations.

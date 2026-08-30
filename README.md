# Dotfiles

Personal development-machine configuration for Ghostty, tmux, Neovim, and reusable agent skills. The repository keeps configuration in version control and uses safe symlink managers to install it into standard user locations.

## Modules

| Module | Purpose | Guide |
| --- | --- | --- |
| Ghostty | Terminal appearance and behavior | [ghostty/README.md](ghostty/README.md) |
| tmux | Multiplexing, panes, persistence, and terminal integration | [tmux/README.md](tmux/README.md) |
| Neovim | Lazy.nvim-based editor configuration | [nvim/README.md](nvim/README.md) |
| Skills | Shared `aidlc`, `commit`, and `maprepo` workflows | [skills/README.md](skills/README.md) |

## Prerequisites

- macOS or another Unix-like system with a POSIX shell, `make`, and `git`.
- [Ghostty](https://ghostty.org/) and the `CommitMono Nerd Font Mono` font for the terminal module.
- `tmux` for the tmux module. TPM and its plugins are installed separately over the network.
- Neovim with Git. Neovim also expects a Go installation for `gopls`; the editor installs configured language servers through Mason.
- `python3`, a C compiler (`cc`), and `make` if installing Neovim's Lua 5.1/LuaRocks environment with `make nvim-luarocks`.

## Setup

From the repository root:

```sh
make all                 # link skills, Ghostty, Neovim, and tmux
make nvim-luarocks       # optional, enables Lua 5.1/LuaRocks support
make tmux-tpm            # explicit networked TPM/plugin installation
make test                # run configuration and installer tests
```

`make all` does not install networked dependencies. On first Neovim launch, lazy.nvim bootstraps itself and installs the declared plugins. Mason manages the configured language servers. TPM installs tmux plugins only when `make tmux-tpm` is run (or through TPM's normal `Ctrl-b`, then `I` workflow).

Each link target refuses to replace an existing unrelated file, directory, or symlink. Unlink targets remove only links owned by this repository:

```sh
make unlink-all
```

Destination paths can be overridden on the command line; see the module guides and `make help` for variable names.

## Repository structure

- `ghostty/`, `tmux/`, and `nvim/` contain source configurations.
- `skills/` contains the reusable skill definitions.
- `scripts/` contains safe link and dependency installers.
- `tests/` contains offline-friendly shell tests for the managers and configurations.


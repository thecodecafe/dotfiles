# Neovim

This is a modular Neovim configuration bootstrapped from [lazy.nvim](https://github.com/folke/lazy.nvim). `init.lua` loads options, keymaps, diagnostics, formatting, and the lazy.nvim setup; plugin specifications live under `lua/plugins/`.

## Features

- Dark Gruvbox with soft contrast, Oil file browsing, and a Lualine statusline.
- Telescope project-file search (`ff`), open-buffer search (`fr`), and workspace-symbol search (`fs`).
- Completion through nvim-cmp and LuaSnip.
- LSP diagnostics, details popups, rename with `F2`, definition/reference navigation (`gd`), rich hover details (`gh`), and code actions (`<leader>.`).
- Relative and absolute line numbers; `<leader>w` saves the current buffer; `jj` or `kk` exits insert mode.
- Yanked text is briefly highlighted, while search highlighting is transient and clears after searching or leaving Normal mode.
- Format-on-save for Go, JSON, Lua, and YAML when the matching formatter-capable LSP is attached.
- Neogit on `<leader>gg`, Diffview close on `<leader>dq`, and seamless tmux/editor navigation with `Ctrl-h/j/k/l/\`.

## Configured language servers

Mason is configured to manage `gopls`, `lua_ls`, `ts_ls`, `cssls`, `html`, `somesass_ls`, `jsonls`, and `yamlls`. This covers Go, Lua, TypeScript/JavaScript/TSX/JSX, CSS/SCSS/Sass, HTML, JSON, YAML, and related project files supported by those servers.

`gopls` is enabled only when the `go` executable is available. JSON and YAML schemas come from SchemaStore.nvim.

## Dependencies

- Neovim and Git. lazy.nvim clones itself into Neovim's data directory on first launch.
- Go for `gopls` and Go formatting.
- Network access on first launch for lazy.nvim and plugin downloads; Mason uses the network to install language servers.
- Lua 5.1 and LuaRocks support for plugins that need Lua rocks. The repository can build an isolated environment with `make nvim-luarocks`; that installer requires `python3`, `cc`, `make`, Git, and a trusted CA bundle.

## Install

```sh
make nvim
make nvim-luarocks   # optional but recommended when using Lua-rock-dependent plugins
```

`make nvim` links this directory to `~/.config/nvim` (or `$XDG_CONFIG_HOME/nvim`) and reports if the LuaRocks environment is missing. It does not clone the Neovim source repository. Remove only the repository-owned link with `make unlink-nvim`.

The first launch may download lazy.nvim and plugins. Open `:Lazy` to inspect plugin state and `:Mason` to inspect language-server installations. The committed `lazy-lock.json` records plugin revisions for repeatable updates.

## Testing

Run `make test` from the repository root. The Neovim test uses an isolated temporary data directory and a stub lazy.nvim module, so it does not need to modify the live editor installation.

# Neovim

This is a modular Neovim configuration bootstrapped from [lazy.nvim](https://github.com/folke/lazy.nvim). `init.lua` loads options, keymaps, diagnostics, formatting, and the lazy.nvim setup; plugin specifications live under `lua/plugins/`.

## Features

- Gruvbox, Kanagawa Dragon, darker Rosé Pine Main, and Catppuccin Mocha themes; Oil file browsing and a colorscheme-aware Lualine statusline.
- Telescope project-file search (`ff`), open-buffer search (`fr`), and workspace-symbol search (`fs`).
- Completion through nvim-cmp and LuaSnip.
- Generic syntax highlighting for extensionless files named `config`, covering common key/value entries, values, and `#` / `;` comment lines.
- DBML filetype detection and syntax highlighting.
- LSP diagnostics, details popups, rename with `F2`, definition/reference navigation (`gd`), rich hover details (`gh`), and floating code actions (`<leader>.`) navigated with `Tab` / `Shift-Tab` and confirmed with `Enter`.
- Relative and absolute line numbers; `<leader>w` saves the current buffer, `<leader>bd` deletes the current buffer, and `<leader>q` asks for confirmation before quitting (unsaved changes still trigger Neovim's normal warning); `jj` or `kk` exits insert mode.
- Yanked text is briefly highlighted, while search highlighting is transient and clears after searching or leaving Normal mode.
- Format-on-save for Go, JSON, Lua, and YAML when the matching formatter-capable LSP is attached; PostgreSQL SQL uses pgFormatter, and DBML uses conservative indentation.
- The top winbar shows the current buffer's path relative to the nearest project root, while lualine shows the shorter filename in its bottom statusline.
- Neogit on `<leader>gg`, Diffview close on `<leader>dq`, and seamless tmux/editor navigation with `Ctrl-h/j/k/l/\`.
- Text objects for the whole buffer (`yae`, `vae`) and indentation scopes (`yii`, `yai`, `vii`, `vai`). The matching scope-delete forms are `dii` and `dai`; `x` retains Neovim's default character-delete behavior.

## Configured language servers

Mason is configured to manage `gopls`, `lua_ls`, `ts_ls`, `cssls`, `html`, `somesass_ls`, `jsonls`, `yamlls`, and `postgres_lsp`. This covers Go, Lua, TypeScript/JavaScript/TSX/JSX, CSS/SCSS/Sass, HTML, JSON, YAML, PostgreSQL SQL, and related project files supported by those servers.

`gopls` is enabled only when the `go` executable is available. JSON and YAML schemas come from SchemaStore.nvim.

## Dependencies

- Neovim and Git. lazy.nvim clones itself into Neovim's data directory on first launch.
- Go for `gopls` and Go formatting.
- PostgreSQL SQL language support is installed by Mason. Without a project database connection, the Postgres Language Server provides basic linting; schema-aware completion and type checking require project-specific connection settings. SQL format-on-save requires pgFormatter: install it on macOS with `brew install pgformatter` (the executable is `pg_format`). Comments are retained, though formatting may adjust their placement or layout.
- Network access on first launch for lazy.nvim and plugin downloads; Mason uses the network to install language servers.
- Treesitter parsers for syntax-aware scopes are installed automatically on first use for the configured languages. Parser compilation requires the `tree-sitter-cli` executable and a C compiler. On macOS with a compatible Homebrew bottle, install the CLI with `brew install tree-sitter-cli`; the separate `tree-sitter` formula installs only the library. Intel macOS may fall back to compiling LLVM and the CLI from source, which can make a `cmake --build .` step take an unusually long time. In that case, download `tree-sitter-cli-macos-x64.zip` from the [official Tree-sitter releases](https://github.com/tree-sitter/tree-sitter/releases), extract `tree-sitter` to `/usr/local/bin`, and run `chmod +x /usr/local/bin/tree-sitter`. If macOS blocks the trusted release binary, remove its quarantine attribute with `xattr -d com.apple.quarantine /usr/local/bin/tree-sitter`, then verify it with `tree-sitter --version`. Restart Neovim and run `:TSUpdate`. The first launch may also require network access, `curl`, and `tar`; use `:TSInstall <language>` for additional languages outside the default list.
- Lua 5.1 and LuaRocks support for plugins that need Lua rocks. The repository can build an isolated environment with `make nvim-luarocks`; that installer requires `python3`, `cc`, `make`, Git, and a trusted CA bundle.

## Install

```sh
make nvim
make nvim-luarocks   # optional but recommended when using Lua-rock-dependent plugins
```

Choose the Neovim theme by changing `active` in `lua/config/theme.lua` to `gruvbox`, `kanagawa`, `rose-pine`, or `catppuccin`, then restart Neovim. These select Gruvbox, Kanagawa Dragon, Rosé Pine Main (the darker Rosé Pine variant), and Catppuccin Mocha respectively. Lazy.nvim installs the theme plugins on launch.

`make nvim` links this directory to `~/.config/nvim` (or `$XDG_CONFIG_HOME/nvim`) and reports if the LuaRocks environment is missing. If a real configuration directory exists, linking asks for confirmation and backs it up beside the destination before replacing it. Unrelated symlinks are never replaced. It does not clone the Neovim source repository. Remove only the repository-owned link with `make unlink-nvim`.

The first launch may download lazy.nvim and plugins. Open `:Lazy` to inspect plugin state and `:Mason` to inspect language-server installations. The committed `lazy-lock.json` records plugin revisions for repeatable updates.

## Testing

Run `make test` from the repository root. The Neovim test uses an isolated temporary data directory and a stub lazy.nvim module, so it does not need to modify the live editor installation.

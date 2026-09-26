#!/bin/sh

set -eu

if ! command -v nvim >/dev/null 2>&1; then
    printf '%s\n' 'Neovim is unavailable; skipping configuration test.'
    exit 0
fi

project_root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd -P)
config_directory=$project_root/nvim
lazy_config=$config_directory/lua/config/lazy.lua
lazy_lock=$config_directory/lazy-lock.json
test_root=$(mktemp -d "${TMPDIR:-/tmp}/nvim-config.XXXXXX")
test_root=$(CDPATH= cd -- "$test_root" && pwd -P)
trap 'rm -rf "$test_root"' EXIT HUP INT TERM

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    exit 1
}

mkdir -p "$test_root/config" "$test_root/data/nvim/lazy/lazy.nvim/lua/lazy" "$test_root/state" "$test_root/cache"
ln -s "$config_directory" "$test_root/config/nvim"

printf '%s\n' \
    'local M = {}' \
    'function M.setup(options)' \
    '  assert(options.spec[1].import == "plugins")' \
    '  assert(options.rocks.enabled == true)' \
    '  assert(options.rocks.hererocks == true)' \
    '  local plugins = require("plugins")' \
    '  assert(type(plugins) == "table" and #plugins == 0)' \
    '  local gruvbox = require("plugins.gruvbox")' \
    '  assert(gruvbox[1] == "ellisonleao/gruvbox.nvim")' \
    '  assert(gruvbox.lazy == false)' \
    '  assert(gruvbox.priority == 1000)' \
    '  assert(gruvbox.opts.contrast == "hard")' \
    '  assert(vim.tbl_contains(gruvbox.dependencies, "rebelot/kanagawa.nvim"))' \
    '  assert(gruvbox.dependencies[2][1] == "rose-pine/neovim")' \
    '  assert(gruvbox.dependencies[3][1] == "catppuccin/nvim")' \
    '  assert(vim.tbl_contains(gruvbox.dependencies, "ydkulks/cursor-dark.nvim"))' \
    '  assert(vim.tbl_contains(gruvbox.dependencies, "tiesen243/vercel.nvim"))' \
    '  assert(vim.tbl_contains(gruvbox.dependencies, "thecodecafe/terminal-theme.nvim"))' \
    '  assert(type(gruvbox.config) == "function")' \
    '  local theme = require("config.theme")' \
    '  assert(theme.colorschemes[theme.active] ~= nil)' \
    '  local expected_themes = { gruvbox = "gruvbox", kanagawa = "kanagawa-dragon", ["rose-pine"] = "rose-pine-main", catppuccin = "catppuccin-mocha", ["cursor-dark"] = "cursor-dark", vercel = "vercel", terminal = "terminal-theme" }' \
    '  local original_colorscheme = vim.cmd.colorscheme' \
    '  local original_highlight = vim.cmd.highlight' \
    '  local original_get_hl, original_set_hl = vim.api.nvim_get_hl, vim.api.nvim_set_hl' \
    '  local original_catppuccin = package.loaded.catppuccin' \
    '  local original_cursor_dark, original_vercel = package.loaded["cursor-dark"], package.loaded.vercel' \
    '  package.loaded.catppuccin = { setup = function(opts) vim.g.catppuccin_test_flavour = opts.flavour end }' \
    '  package.loaded["cursor-dark"] = { setup = function(opts) vim.g.cursor_dark_test_style = opts.style end }' \
    '  package.loaded.vercel = { setup = function(opts) vim.g.vercel_test_theme = opts.theme end }' \
    '  vim.cmd.colorscheme = function(name) vim.g.test_colorscheme = name end' \
    '  local background_overrides = {}' \
    '  vim.cmd.highlight = function(spec) table.insert(background_overrides, spec) end' \
    '  local highlight_groups = {' \
    '    Normal = { fg = 0xD8DEE9, bg = 0x111111 },' \
    '    WinBar = { fg = 0x000000, bg = 0x222222, bold = true },' \
    '    WinBarNC = { fg = 0x000000, bg = 0x333333, italic = true },' \
    '  }' \
    '  local set_highlight_calls = {}' \
    '  vim.api.nvim_get_hl = function(_, opts) return vim.deepcopy(highlight_groups[opts.name]) end' \
    '  vim.api.nvim_set_hl = function(_, name, highlights)' \
    '    highlight_groups[name] = vim.deepcopy(highlights)' \
    '    table.insert(set_highlight_calls, name)' \
    '  end' \
    '  for name, expected in pairs(expected_themes) do' \
    '    local previous_override_count = #background_overrides' \
    '    local previous_set_highlight_count = #set_highlight_calls' \
    '    theme.apply(name)' \
    '    assert(vim.g.test_colorscheme == expected)' \
    '    if name == "cursor-dark" then' \
    '      assert(#background_overrides == previous_override_count + 2)' \
    '      assert(background_overrides[#background_overrides - 1] == "Normal guibg=#000000")' \
    '      assert(background_overrides[#background_overrides] == "NormalNC guibg=#000000")' \
    '      assert(#set_highlight_calls == previous_set_highlight_count + 2)' \
    '      assert(set_highlight_calls[#set_highlight_calls - 1] == "WinBar" and set_highlight_calls[#set_highlight_calls] == "WinBarNC")' \
    '      assert(highlight_groups.WinBar.fg == highlight_groups.Normal.fg and highlight_groups.WinBar.bg == "#000000" and highlight_groups.WinBar.bold)' \
    '      assert(highlight_groups.WinBarNC.fg == highlight_groups.Normal.fg and highlight_groups.WinBarNC.bg == "#000000" and highlight_groups.WinBarNC.italic)' \
    '    else' \
    '      assert(#background_overrides == previous_override_count)' \
    '      assert(#set_highlight_calls == previous_set_highlight_count)' \
    '    end' \
    '  end' \
    '  assert(vim.g.catppuccin_test_flavour == "mocha")' \
    '  assert(vim.g.cursor_dark_test_style == "dark" and vim.g.vercel_test_theme == "dark")' \
    '  package.loaded.catppuccin = original_catppuccin' \
    '  package.loaded["cursor-dark"], package.loaded.vercel = original_cursor_dark, original_vercel' \
    '  vim.cmd.highlight = original_highlight' \
    '  vim.api.nvim_get_hl, vim.api.nvim_set_hl = original_get_hl, original_set_hl' \
    '  assert(#theme.choices == 7 and theme.choices[1].label == "Gruvbox" and theme.choices[2].label == "Kanagawa Dragon" and theme.choices[3].label == "Rosé Pine Main" and theme.choices[4].label == "Catppuccin Mocha" and theme.choices[5].label == "Cursor Dark" and theme.choices[6].label == "Vercel Dark" and theme.choices[7].label == "Terminal Theme")' \
    '  local kanagawa = require("plugins.kanagawa")' \
    '  assert(kanagawa[1] == "rebelot/kanagawa.nvim" and kanagawa.lazy == false)' \
    '  local rose_pine = require("plugins.rose_pine")' \
    '  assert(rose_pine[1] == "rose-pine/neovim" and rose_pine.name == "rose-pine" and rose_pine.lazy == false)' \
    '  local catppuccin = require("plugins.catppuccin")' \
    '  assert(catppuccin[1] == "catppuccin/nvim" and catppuccin.name == "catppuccin" and catppuccin.lazy == false)' \
    '  local cursor_dark = require("plugins.cursor_dark")' \
    '  assert(cursor_dark[1] == "ydkulks/cursor-dark.nvim" and cursor_dark.lazy == false)' \
    '  local vercel = require("plugins.vercel")' \
    '  assert(vercel[1] == "tiesen243/vercel.nvim" and vercel.lazy == false)' \
    '  local terminal_theme = require("plugins.terminal_theme")' \
    '  assert(terminal_theme[1] == "thecodecafe/terminal-theme.nvim" and terminal_theme.lazy == false)' \
    '  local oil = require("plugins.oil")' \
    '  assert(oil[1] == "stevearc/oil.nvim")' \
    '  assert(oil.lazy == false)' \
    '  assert(oil.opts.default_file_explorer == true)' \
    '  assert(oil.opts.keymaps["<C-h>"] == false)' \
    '  assert(oil.opts.keymaps["<C-l>"] == false)' \
    '  assert(oil.opts.keymaps["<Esc>"] == "actions.close")' \
    '  assert(oil.opts.keymaps.gR == "actions.refresh")' \
    '  assert(oil.keys[1][1] == "-")' \
    '  assert(oil.keys[1][2] == "<CMD>Oil<CR>")' \
    '  local textobjects = require("plugins.textobjects")' \
    '  assert(textobjects[1][1] == "nvim-treesitter/nvim-treesitter")' \
    '  assert(textobjects[1].branch == "main")' \
    '  assert(textobjects[1].build == ":TSUpdate")' \
    '  local textobject_config = require("config.textobjects")' \
    '  local expected_parsers = { "bash", "css", "go", "html", "javascript", "json", "lua", "markdown", "scss", "tsx", "typescript", "vim", "vimdoc", "yaml" }' \
    '  assert(vim.deep_equal(textobject_config.treesitter_parsers, expected_parsers))' \
    '  assert(textobjects[2][1] == "nvim-mini/mini.ai")' \
    '  assert(textobjects[2].opts.custom_textobjects.e ~= nil)' \
    '  assert(textobjects[2].opts.custom_textobjects.s == nil)' \
    '  assert(textobjects[3][1] == "nvim-mini/mini.indentscope")' \
    '  assert(textobjects[3].opts.mappings.object_scope == "ii")' \
    '  assert(textobjects[3].opts.mappings.object_scope_with_border == "ai")' \
    '  local whole_buffer = textobject_config.whole_buffer()' \
    '  assert(whole_buffer.from.line == 1 and whole_buffer.from.col == 1)' \
    '  assert(whole_buffer.to.line == vim.api.nvim_buf_line_count(0) and whole_buffer.vis_mode == "V")' \
    '  assert(vim.fn.maparg("xii", "n") == "")' \
    '  assert(vim.fn.maparg("xai", "n") == "")' \
    '  assert(vim.fn.maparg("xis", "n") == "")' \
    '  assert(vim.fn.maparg("xas", "n") == "")' \
    '  local neogit = require("plugins.neogit")' \
    '  assert(neogit[1][1] == "NeogitOrg/neogit")' \
    '  assert(neogit[1].cmd == "Neogit")' \
    '  assert(vim.tbl_contains(neogit[1].dependencies, "nvim-telescope/telescope.nvim"))' \
    '  assert(vim.tbl_contains(neogit[1].dependencies, "sindrets/diffview.nvim"))' \
    '  assert(vim.tbl_contains(neogit[1].dependencies, "m00qek/baleia.nvim"))' \
    '  assert(neogit[1].keys[1][1] == "<leader>gg")' \
    '  assert(neogit[1].keys[1][2] == "<cmd>Neogit kind=vsplit<cr>")' \
    '  assert(neogit[1].keys[1].desc == "Open Neogit")' \
    '  assert(neogit[1].opts.integrations.telescope == true)' \
    '  local diffview = require("plugins.diffview")' \
    '  assert(diffview[1][1] == "sindrets/diffview.nvim")' \
    '  local diffview_contexts = { "view", "file_panel", "file_history_panel", "option_panel", "help_panel" }' \
    '  for _, context in ipairs(diffview_contexts) do' \
    '    local mapping = diffview[1].opts.keymaps[context][1]' \
    '    assert(mapping[1] == "n" and mapping[2] == "<leader>dq")' \
    '    assert(mapping[3] == "<cmd>DiffviewClose<cr>")' \
    '    assert(mapping[4].desc == "Close Diffview")' \
    '  end' \
    '  assert(vim.fn.maparg("<leader>dq", "n") == "")' \
    '  assert(vim.g.mapleader == " ")' \
    '  assert(vim.o.number == true)' \
    '  assert(vim.o.relativenumber == true)' \
    '  assert(vim.o.signcolumn == "yes")' \
    '  assert(vim.o.cmdheight == 0)' \
    '  assert(vim.o.showcmd == true)' \
    '  assert(vim.o.showcmdloc == "statusline")' \
    '  assert(vim.o.showmode == false)' \
    '  assert(vim.o.winbar == "%{%v:lua.require('"'"'config.statusline'"'"').project_path()%}")' \
    '  assert(vim.filetype.match({ filename = "/tmp/some-app/config" }) == "genericconfig")' \
    '  assert(vim.filetype.match({ filename = "/tmp/unrelated/config" }) == "genericconfig")' \
    '  assert(vim.filetype.match({ filename = "/tmp/unrelated/config.ini" }) ~= "genericconfig")' \
    '  assert(vim.g.syntax_on == 1)' \
    '  local syntax_buf = vim.api.nvim_create_buf(true, false)' \
    '  vim.api.nvim_set_current_buf(syntax_buf)' \
    '  vim.api.nvim_buf_set_name(syntax_buf, "/tmp/unrelated/config")' \
    '  vim.api.nvim_buf_set_lines(syntax_buf, 0, -1, false, { "# comment", "font-family = \"Example Font\"", "enabled = true", "port = 42", "mode: production" })' \
    '  vim.bo[syntax_buf].modified = false' \
    '  vim.api.nvim_buf_call(syntax_buf, function() vim.bo.filetype = "genericconfig"; vim.cmd("syntax sync fromstart") end)' \
    '  local function syntax_group(line, col)' \
    '    return vim.fn.synIDattr(vim.fn.synID(line, col, 1), "name")' \
    '  end' \
    '  assert(syntax_group(1, 1) == "GenericConfigComment", syntax_group(1, 1))' \
    '  assert(syntax_group(2, 1) == "GenericConfigKey", syntax_group(2, 1))' \
    '  assert(syntax_group(2, 13) == "GenericConfigSeparator", syntax_group(2, 13))' \
    '  assert(syntax_group(2, 15) == "GenericConfigString", syntax_group(2, 15))' \
    '  assert(syntax_group(3, 12) == "GenericConfigBoolean", syntax_group(3, 12))' \
    '  assert(syntax_group(4, 8) == "GenericConfigNumber", syntax_group(4, 8))' \
    '  assert(syntax_group(5, 1) == "GenericConfigKey", syntax_group(5, 1))' \
    '  assert(syntax_group(5, 5) == "GenericConfigSeparator", syntax_group(5, 5))' \
    '  assert(syntax_group(5, 7) == "GenericConfigValue", syntax_group(5, 7))' \
    '  assert(vim.o.incsearch == true)' \
    '  assert(vim.o.hlsearch == false)' \
    '  local feedback_autocmds = vim.api.nvim_get_autocmds({ group = "nvim-editor-feedback" })' \
    '  assert(#feedback_autocmds == 8)' \
    '  local feedback_events = {}' \
    '  for _, autocmd in ipairs(feedback_autocmds) do feedback_events[autocmd.event] = true end' \
    '  assert(feedback_events.TextYankPost and feedback_events.CmdlineEnter and feedback_events.CmdlineLeave and feedback_events.BufLeave and feedback_events.ModeChanged)' \
    '  assert(vim.o.timeoutlen == 300)' \
    '  assert(vim.fn.maparg("<leader>w", "n"):match("write"))' \
    '  assert(vim.fn.maparg("<leader>bd", "n") == "<Cmd>bdelete<CR>")' \
    '  assert(vim.fn.maparg("<leader>bn", "n") == "<Cmd>bnext<CR>")' \
    '  assert(vim.fn.maparg("<leader>bp", "n") == "<Cmd>bprevious<CR>")' \
    '  assert(vim.fn.maparg("<leader>bl", "n") == "<Cmd>buffer #<CR>")' \
    '  local quit_mapping = vim.fn.maparg("<leader>q", "n", false, true)' \
    '  assert(type(quit_mapping.callback) == "function")' \
    '  assert(quit_mapping.desc == "Confirm before quitting Neovim")' \
    '  local original_confirm, original_cmd = vim.fn.confirm, vim.cmd' \
    '  local confirmation, quit_command' \
    '  vim.fn.confirm = function(prompt, choices, default)' \
    '    assert(prompt == "Quit Neovim?" and choices == "&Yes\n&No" and default == 2)' \
    '    return confirmation' \
    '  end' \
    '  vim.cmd = function(command) quit_command = command end' \
    '  confirmation = 2; quit_mapping.callback(); assert(quit_command == nil)' \
    '  confirmation = 0; quit_mapping.callback(); assert(quit_command == nil)' \
    '  confirmation = 1; quit_mapping.callback(); assert(quit_command == "q")' \
    '  vim.fn.confirm, vim.cmd = original_confirm, original_cmd' \
    '  vim.cmd("setfiletype dbml")' \
    '  assert(vim.bo.filetype == "dbml")' \
    '  assert(vim.fn.maparg("<leader>dp", "n") == "")' \
    '  vim.cmd("enew")' \
    '  vim.cmd("setfiletype text")' \
    '  assert(vim.fn.maparg("<leader>dp", "n") == "")' \
    '  assert(vim.fn.maparg("jj", "i") == "<Esc>")' \
    '  assert(vim.fn.maparg("kk", "i") == "<Esc>")' \
    '  assert(vim.fn.maparg("[d", "n") ~= "")' \
    '  assert(vim.fn.maparg("]d", "n") ~= "")' \
    '  assert(vim.fn.maparg("<Esc>", "n") ~= "")' \
    '  local diagnostics = vim.diagnostic.config()' \
    '  assert(diagnostics.signs == true)' \
    '  assert(diagnostics.underline == true)' \
    '  assert(diagnostics.virtual_text == false)' \
    '  assert(diagnostics.virtual_lines == false)' \
    '  assert(diagnostics.jump.wrap == true)' \
    '  local diagnostic_namespace = vim.api.nvim_create_namespace("nvim-config-test")' \
    '  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "first", "second" })' \
    '  vim.bo.modified = false' \
    '  vim.diagnostic.set(diagnostic_namespace, 0, { {' \
    '    lnum = 0, col = 0, severity = vim.diagnostic.severity.WARN,' \
    '    message = "Starting diagnostic", source = "config-test",' \
    '  }, {' \
    '    lnum = 1, col = 0, severity = vim.diagnostic.severity.ERROR,' \
    '    message = "Expanded diagnostic details", source = "config-test",' \
    '  } })' \
    '  local function find_normal_map(lhs)' \
    '    for _, mapping in ipairs(vim.api.nvim_get_keymap("n")) do' \
    '      if mapping.lhs == lhs then return mapping end' \
    '    end' \
    '  end' \
    '  local next_diagnostic = find_normal_map("]d")' \
    '  assert(next_diagnostic and type(next_diagnostic.callback) == "function")' \
    '  next_diagnostic.callback()' \
    '  assert(vim.wait(1000, function() return #vim.api.nvim_list_wins() > 1 end))' \
    '  local diagnostic_float' \
    '  for _, winid in ipairs(vim.api.nvim_list_wins()) do' \
    '    if vim.api.nvim_win_get_config(winid).relative ~= "" then diagnostic_float = winid end' \
    '  end' \
    '  assert(diagnostic_float and vim.api.nvim_win_is_valid(diagnostic_float))' \
    '  local float_lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(diagnostic_float), 0, -1, false)' \
    '  local float_text = table.concat(float_lines, " ")' \
    '  assert(float_text:match("Expanded diagnostic details"), float_text)' \
    '  assert(float_text:match("config%-test"), float_text)' \
    '  assert(vim.api.nvim_get_current_win() ~= diagnostic_float)' \
    '  local previous_diagnostic = find_normal_map("[d")' \
    '  assert(previous_diagnostic and type(previous_diagnostic.callback) == "function")' \
    '  previous_diagnostic.callback()' \
    '  assert(vim.wait(1000, function()' \
    '    return not vim.api.nvim_win_is_valid(diagnostic_float) and vim.api.nvim_win_get_cursor(0)[1] == 1' \
    '  end))' \
    '  for _, winid in ipairs(vim.api.nvim_list_wins()) do' \
    '    if vim.api.nvim_win_get_config(winid).relative ~= "" then diagnostic_float = winid end' \
    '  end' \
    '  assert(diagnostic_float and vim.api.nvim_win_is_valid(diagnostic_float))' \
    '  float_lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(diagnostic_float), 0, -1, false)' \
    '  assert(table.concat(float_lines, " "):match("Starting diagnostic"))' \
    '  local escape = find_normal_map("<Esc>")' \
    '  assert(escape.expr == 1 and type(escape.callback) == "function")' \
    '  vim.v.errmsg = ""' \
    '  local escape_key = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)' \
    '  vim.api.nvim_feedkeys(escape_key, "mx", false)' \
    '  assert(vim.wait(1000, function() return not vim.api.nvim_win_is_valid(diagnostic_float) end))' \
    '  assert(not vim.v.errmsg:match("E565"), vim.v.errmsg)' \
    '  assert(escape.callback() == "<Esc>")' \
    '  vim.diagnostic.reset(diagnostic_namespace, 0)' \
    '  local formatting = require("config.formatting")' \
    '  assert(vim.deep_equal(formatting.formatters, { go = "gopls", json = "jsonls", lua = "lua_ls", yaml = "yamlls" }))' \
    '  assert(formatting.sql_formatter == "pg_format", "SQL formatter executable is incorrect")' \
    '  local dbml_input = { "Table users as U {", "// keep this comment {", "id int [pk]", "note varchar [note: `keep }`]", "indexes {", "(id) [pk]", "}", "}", "Ref: U.id > U.id" }' \
    '  local dbml_output = formatting.format_dbml(dbml_input)' \
    '  assert(dbml_output[2] == "  // keep this comment {")' \
    '  assert(dbml_output[3] == "  id int [pk]")' \
    '  assert(dbml_output[5] == "  indexes {")' \
    '  assert(dbml_output[6] == "    (id) [pk]")' \
    '  assert(dbml_output[9] == "Ref: U.id > U.id")' \
    '  local invalid_output, invalid_error = formatting.format_dbml({ "Table users {", "id int" })' \
    '  assert(invalid_output == nil and invalid_error == "unclosed DBML structure")' \
    '  local format_autocmds = vim.api.nvim_get_autocmds({ group = "nvim-format-on-save", event = "BufWritePre" })' \
    '  assert(#format_autocmds == 1)' \
    '  local original_get_clients = vim.lsp.get_clients' \
    '  local original_format = vim.lsp.buf.format' \
    '  local original_notify = vim.notify' \
    '  vim.bo.filetype = "typescript"' \
    '  vim.lsp.get_clients = function() error("unsupported filetype requested clients") end' \
    '  formatting.format_buffer(0)' \
    '  vim.bo.filetype = "go"' \
    '  vim.lsp.get_clients = function(filter)' \
    '    assert(filter.bufnr == 0 and filter.method == "textDocument/formatting")' \
    '    return { { name = "gopls" }, { name = "other" } }' \
    '  end' \
    '  vim.lsp.buf.format = function(opts)' \
    '    assert(opts.bufnr == 0 and opts.async == false and opts.timeout_ms == 2000)' \
    '    assert(opts.filter({ name = "gopls" }) == true)' \
    '    assert(opts.filter({ name = "other" }) == false)' \
    '    vim.g.format_called = true' \
    '  end' \
    '  formatting.format_buffer(0)' \
    '  assert(vim.g.format_called == true)' \
    '  vim.bo.filetype = "json"' \
    '  vim.lsp.get_clients = function() return {} end' \
    '  vim.notify = function(message, level)' \
    '    assert(message == "No jsonls formatter is attached" and level == vim.log.levels.WARN)' \
    '    vim.g.format_warning_shown = true' \
    '  end' \
    '  formatting.format_buffer(0)' \
    '  assert(vim.g.format_warning_shown == true)' \
    '  local original_system = vim.system' \
    '  local original_executable = vim.fn.executable' \
    '  vim.bo.filetype = "sql"' \
    '  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1;", "-- keep this comment" })' \
    '  vim.g.formatter_result = { code = 0, stdout = "SELECT 1;\n-- keep this comment\n", stderr = "" }' \
    '  vim.system = function(command, opts)' \
    '    assert(vim.deep_equal(command, { "pg_format", "-" }))' \
    '    assert(opts.stdin:match("select 1;") and opts.stdin:match("%-%- keep this comment"))' \
    '    return { wait = function() return vim.g.formatter_result end }' \
    '  end' \
    '  vim.fn.executable = function(name) assert(name == "pg_format"); return 1 end' \
    '  formatting.format_buffer(0)' \
    '  assert(vim.deep_equal(vim.api.nvim_buf_get_lines(0, 0, -1, false), { "SELECT 1;", "-- keep this comment" }), "SQL formatting did not retain comment text")' \
    '  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "select 1;", "-- keep this comment" })' \
    '  vim.g.formatter_result = { code = 1, stdout = "", stderr = "formatter failed" }' \
    '  vim.notify = function(message, level) assert(message:match("formatter failed") and level == vim.log.levels.WARN); vim.g.format_warning_shown = true end' \
    '  formatting.format_buffer(0)' \
    '  assert(vim.api.nvim_buf_get_lines(0, 0, -1, false)[1] == "select 1;", "failed SQL formatter changed the buffer")' \
    '  vim.fn.executable = function() return 0 end' \
    '  vim.notify = function(message, level) assert(message:match("brew install pgformatter") and level == vim.log.levels.WARN); vim.g.missing_formatter_warning_shown = true end' \
    '  formatting.format_buffer(0)' \
    '  assert(vim.api.nvim_buf_get_lines(0, 0, -1, false)[2] == "-- keep this comment", "missing SQL formatter changed the buffer")' \
    '  assert(vim.g.missing_formatter_warning_shown == true)' \
    '  vim.system = original_system' \
    '  vim.fn.executable = original_executable' \
    '  vim.bo.modified = false' \
    '  vim.lsp.get_clients = original_get_clients' \
    '  vim.lsp.buf.format = original_format' \
    '  vim.notify = original_notify' \
    '  vim.bo.filetype = ""' \
    '  local completion = require("plugins.completion")' \
    '  assert(completion[1][1] == "hrsh7th/nvim-cmp")' \
    '  assert(completion[1].event == "InsertEnter")' \
    '  assert(vim.tbl_contains(completion[1].dependencies, "hrsh7th/cmp-nvim-lsp"))' \
    '  assert(vim.tbl_contains(completion[1].dependencies, "L3MON4D3/LuaSnip"))' \
    '  assert(vim.tbl_contains(completion[1].dependencies, "saadparwaiz1/cmp_luasnip"))' \
    '  assert(type(completion[1].config) == "function")' \
    '  local statusline = require("plugins.statusline")' \
    '  assert(statusline[1][1] == "nvim-lualine/lualine.nvim")' \
    '  assert(statusline[1].lazy == false)' \
    '  assert(statusline[1].priority == 900)' \
    '  assert(vim.tbl_contains(statusline[1].dependencies, "nvim-tree/nvim-web-devicons"))' \
    '  assert(statusline[1].opts.options.theme == "auto")' \
    '  assert(statusline[1].opts.options.globalstatus == true)' \
    '  assert(vim.deep_equal(statusline[1].opts.sections.lualine_a, { "mode" }))' \
    '  assert(vim.deep_equal(statusline[1].opts.sections.lualine_b, { "branch" }))' \
    '  local statusline_config = require("config.statusline")' \
    '  assert(vim.tbl_contains(statusline[1].opts.sections.lualine_c, "filename"))' \
    '  assert(not vim.tbl_contains(statusline[1].opts.sections.lualine_c, statusline_config.project_path))' \
    '  local original_buf_name = vim.api.nvim_buf_get_name' \
    '  local original_root = vim.fs.root' \
    '  vim.api.nvim_buf_get_name = function() return "/tmp/project/lua/plugins/statusline.lua" end' \
    '  vim.fs.root = function() return "/tmp/project" end' \
    '  assert(statusline_config.project_path() == "lua/plugins/statusline.lua")' \
    '  vim.api.nvim_buf_get_name = function() return "" end' \
    '  assert(statusline_config.project_path() == "")' \
    '  vim.api.nvim_buf_get_name = function() return "/tmp/outside.lua" end' \
    '  assert(statusline_config.project_path() == "/tmp/outside.lua")' \
    '  vim.api.nvim_buf_get_name = original_buf_name' \
    '  vim.fs.root = original_root' \
    '  assert(vim.tbl_contains(statusline[1].opts.sections.lualine_c, "diagnostics"))' \
    '  assert(type(statusline[1].opts.sections.lualine_x[1]) == "function")' \
    '  assert(statusline[1].opts.sections.lualine_x[1]() == "")' \
    '  assert(statusline[1].opts.sections.lualine_x[2] == "filetype")' \
    '  assert(vim.deep_equal(statusline[1].opts.sections.lualine_y, { "%S" }))' \
    '  assert(type(statusline[1].opts.sections.lualine_z[1]) == "function")' \
    '  assert(statusline[1].opts.sections.lualine_z[1]():match("^%d+/%d+:%d+$"))' \
    '  local session = require("plugins.session")' \
    '  assert(session[1][1] == "rmagatti/auto-session")' \
    '  assert(session[1].lazy == false)' \
    '  assert(session[1].opts.auto_save == false)' \
    '  assert(session[1].opts.auto_restore == true)' \
    '  assert(session[1].opts.auto_create == false)' \
    '  assert(session[1].opts.auto_restore_last_session == false)' \
    '  assert(session[1].opts.git_use_branch_name == true)' \
    '  assert(session[1].opts.git_auto_restore_on_branch_change == true)' \
    '  assert(session[1].opts.root_dir == vim.fn.expand("~/.nvim-sessions"))' \
    '  assert(session[1].keys[1][1] == "<leader>ss")' \
    '  assert(session[1].keys[1][2] == "<cmd>AutoSession save<cr>")' \
    '  assert(session[1].keys[2][1] == "<leader>sd")' \
    '  assert(session[1].keys[2][2] == "<cmd>AutoSession delete<cr>")' \
    '  local noice = require("plugins.noice")' \
    '  assert(noice[1][1] == "folke/noice.nvim")' \
    '  assert(noice[1].event == "VeryLazy")' \
    '  assert(vim.tbl_contains(noice[1].dependencies, "MunifTanjim/nui.nvim"))' \
    '  assert(noice[1].opts.messages.view_search == false)' \
    '  assert(noice[1].opts.presets.bottom_search == false)' \
    '  assert(noice[1].opts.presets.command_palette == true)' \
    '  local code_action_plugin = require("plugins.code_action")' \
    '  assert(code_action_plugin[1][1] == "rachartier/tiny-code-action.nvim")' \
    '  assert(code_action_plugin[1].event == "LspAttach")' \
    '  assert(code_action_plugin[1].opts.backend == "vim")' \
    '  assert(code_action_plugin[1].opts.picker[1] == "buffer")' \
    '  assert(code_action_plugin[1].opts.picker.opts.keymaps.select == "<CR>")' \
    '  local code_action_config = require("config.code_action")' \
    '  code_action_config.setup()' \
    '  local code_action_autocmds = vim.api.nvim_get_autocmds({ group = "nvim-code-action-picker", event = "User" })' \
    '  assert(#code_action_autocmds == 1 and code_action_autocmds[1].pattern == "TinyCodeActionWindowEnterMain")' \
    '  local picker_buffer = vim.api.nvim_create_buf(false, true)' \
    '  vim.api.nvim_buf_set_lines(picker_buffer, 0, -1, false, { "## ✂  Refactor", "  • Extract function" })' \
    '  vim.api.nvim_exec_autocmds("User", { pattern = "TinyCodeActionWindowEnterMain", data = { buf = picker_buffer } })' \
    '  local picker_lines = vim.api.nvim_buf_get_lines(picker_buffer, 0, -1, false)' \
    '  assert(picker_lines[1] == "Refactor" and picker_lines[2] == "  • Extract function")' \
    '  local picker_maps = vim.api.nvim_buf_get_keymap(picker_buffer, "n")' \
    '  local picker_map_rhs = {}' \
    '  for _, mapping in ipairs(picker_maps) do picker_map_rhs[mapping.lhs] = mapping.rhs end' \
    '  assert(picker_map_rhs["<Tab>"] == "j" and picker_map_rhs["<S-Tab>"] == "k")' \
    '  vim.api.nvim_buf_delete(picker_buffer, { force = true })' \
    '  local telescope_config = require("config.telescope")' \
    '  local original_root = vim.fs.root' \
    '  vim.fs.root = function(buffer, marker)' \
    '    assert(buffer == 0 and marker == ".git")' \
    '    return "/tmp/project"' \
    '  end' \
    '  package.loaded["telescope.builtin"] = {' \
    '    find_files = function(opts)' \
    '      assert(opts.cwd == "/tmp/project" and opts.hidden == true and opts.no_ignore == nil)' \
    '    end,' \
    '    buffers = function(opts)' \
    '      assert(opts.sort_mru == true and opts.ignore_current_buffer == false)' \
    '      vim.g.buffer_picker_opened = true' \
    '    end,' \
    '    lsp_dynamic_workspace_symbols = function() vim.g.symbol_picker_opened = true end,' \
    '  }' \
    '  telescope_config.find_files()' \
    '  telescope_config.buffers()' \
    '  assert(vim.g.buffer_picker_opened == true)' \
    '  vim.fs.root = original_root' \
    '  local original_get_clients = vim.lsp.get_clients' \
    '  local original_notify = vim.notify' \
    '  vim.lsp.get_clients = function(filter)' \
    '    assert(filter.bufnr == 0 and filter.method == "workspace/symbol")' \
    '    return {}' \
    '  end' \
    '  vim.notify = function(message, level)' \
    '    assert(message:match("workspace symbols") and level == vim.log.levels.WARN)' \
    '    vim.g.symbol_warning_shown = true' \
    '  end' \
    '  telescope_config.workspace_symbols()' \
    '  assert(vim.g.symbol_warning_shown == true)' \
    '  vim.lsp.get_clients = function() return { {} } end' \
    '  telescope_config.workspace_symbols()' \
    '  assert(vim.g.symbol_picker_opened == true)' \
    '  local picker_spec, picker_results, selected_entry, select_action, closed_picker' \
    '  package.loaded["telescope.pickers"] = { new = function(_, spec)' \
    '    assert(spec.prompt_title == "Select colorscheme" and spec.sorter == "theme-sorter")' \
    '    picker_spec = spec' \
    '    assert(spec.attach_mappings(42, function() end) == true)' \
    '    return { find = function() vim.g.theme_picker_opened = true end }' \
    '  end }' \
    '  package.loaded["telescope.finders"] = { new_table = function(opts)' \
    '    picker_results = opts.results' \
    '    for index, label in ipairs({ "Gruvbox", "Kanagawa Dragon", "Rosé Pine Main", "Catppuccin Mocha", "Cursor Dark", "Vercel Dark", "Terminal Theme" }) do' \
    '      local entry = opts.entry_maker(opts.results[index])' \
    '      assert(entry.display == label and entry.ordinal == label and entry.value == opts.results[index].name)' \
    '    end' \
    '    return { results = opts.results }' \
    '  end }' \
    '  package.loaded["telescope.config"] = { values = { generic_sorter = function(opts) assert(next(opts) == nil); return "theme-sorter" end } }' \
    '  package.loaded["telescope.actions"] = { select_default = { replace = function(_, action) select_action = action end }, close = function(prompt_bufnr) closed_picker = prompt_bufnr end }' \
    '  package.loaded["telescope.actions.state"] = { get_selected_entry = function() return selected_entry end }' \
    '  telescope_config.themes()' \
    '  assert(vim.g.theme_picker_opened == true and #picker_results == 7)' \
    '  selected_entry = { value = "rose-pine" }; select_action(); assert(vim.g.test_colorscheme == "rose-pine-main" and closed_picker == 42)' \
    '  local selected_colorscheme = vim.g.test_colorscheme; selected_entry = nil; select_action(); assert(vim.g.test_colorscheme == selected_colorscheme)' \
    '  vim.cmd.colorscheme = original_colorscheme' \
    '  package.loaded["telescope.pickers"] = nil' \
    '  package.loaded["telescope.finders"] = nil' \
    '  package.loaded["telescope.config"] = nil' \
    '  package.loaded["telescope.actions"] = nil' \
    '  package.loaded["telescope.actions.state"] = nil' \
    '  local next_action = function() end' \
    '  local previous_action = function() end' \
    '  package.loaded["telescope.actions"] = {' \
    '    move_selection_next = next_action,' \
    '    move_selection_previous = previous_action,' \
    '  }' \
    '  package.loaded["telescope.builtin"].lsp_references = function(opts)' \
    '    assert(opts.include_declaration == false and opts.include_current_line == true)' \
    '    assert(opts.jump_type == "never")' \
    '    local mappings = {}' \
    '    assert(opts.attach_mappings(0, function(mode, lhs, action)' \
    '      mappings[mode .. lhs] = action' \
    '    end) == true)' \
    '    assert(mappings["i<Tab>"] == next_action and mappings["n<Tab>"] == next_action)' \
    '    assert(mappings["i<S-Tab>"] == previous_action and mappings["n<S-Tab>"] == previous_action)' \
    '    vim.g.reference_picker_opened = true' \
    '  end' \
    '  telescope_config.references()' \
    '  assert(vim.g.reference_picker_opened == true)' \
    '  vim.lsp.get_clients = original_get_clients' \
    '  vim.notify = original_notify' \
    '  package.loaded["telescope.actions"] = nil' \
    '  package.loaded["telescope.builtin"] = nil' \
    '  local telescope = require("plugins.telescope")' \
    '  assert(telescope[1][1] == "nvim-telescope/telescope.nvim")' \
    '  assert(telescope[1].cmd == "Telescope")' \
    '  assert(vim.tbl_contains(telescope[1].dependencies, "nvim-lua/plenary.nvim"))' \
    '  assert(vim.tbl_contains(telescope[1].dependencies, "nvim-tree/nvim-web-devicons"))' \
    '  assert(telescope[1].keys[1][1] == "ff")' \
    '  assert(telescope[1].keys[1][2] == telescope_config.find_files)' \
    '  assert(telescope[1].keys[2][1] == "fr")' \
    '  assert(telescope[1].keys[2][2] == telescope_config.buffers)' \
    '  assert(telescope[1].keys[3][1] == "fs")' \
    '  assert(telescope[1].keys[3][2] == telescope_config.workspace_symbols)' \
    '  assert(telescope[1].keys[4][1] == "<leader>t")' \
    '  assert(telescope[1].keys[4][2] == telescope_config.themes)' \
    '  assert(telescope[1].keys[4].desc == "Select colorscheme")' \
    '  local lsp_config = require("config.lsp")' \
    '  lsp_config.setup_keymaps()' \
    '  local lsp_attach_autocmds = vim.api.nvim_get_autocmds({ group = "nvim-lsp-keymaps", event = "LspAttach" })' \
    '  assert(#lsp_attach_autocmds == 1 and type(lsp_attach_autocmds[1].callback) == "function")' \
    '  local function find_buffer_map(lhs)' \
    '    for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(0, "n")) do' \
    '      if mapping.lhs == lhs then return mapping end' \
    '    end' \
    '  end' \
    '  local original_get_client_by_id = vim.lsp.get_client_by_id' \
    '  local original_rename = vim.lsp.buf.rename' \
    '  local navigation = require("config.lsp_navigation")' \
    '  local original_goto = navigation.goto_definition_or_references' \
    '  local original_preview = navigation.preview_definition' \
    '  vim.lsp.get_client_by_id = function(client_id)' \
    '    assert(client_id == 41)' \
    '    return { supports_method = function() return false end }' \
    '  end' \
    '  lsp_config.attach_keymaps({ buf = 0, data = { client_id = 41 } })' \
    '  assert(find_buffer_map("<F2>") == nil and find_buffer_map("gd") == nil and find_buffer_map("gh") == nil and find_buffer_map(" .") == nil)' \
    '  vim.lsp.buf.rename = function() vim.g.lsp_rename_called = true end' \
    '  navigation.goto_definition_or_references = function() vim.g.lsp_goto_called = true end' \
    '  navigation.preview_definition = function() vim.g.lsp_preview_called = true end' \
    '  vim.lsp.get_client_by_id = function()' \
    '    return { supports_method = function(_, method)' \
    '      return method == "textDocument/rename" or method == "textDocument/definition" or method == "textDocument/codeAction"' \
    '    end }' \
    '  end' \
    '  package.loaded["tiny-code-action"] = { code_action = function() vim.g.lsp_code_action_called = true end }' \
    '  lsp_config.attach_keymaps({ buf = 0, data = { client_id = 42 } })' \
    '  local rename_map = find_buffer_map("<F2>")' \
    '  assert(rename_map and type(rename_map.callback) == "function" and rename_map.desc == "Rename symbol")' \
    '  local goto_map = find_buffer_map("gd")' \
    '  assert(goto_map and type(goto_map.callback) == "function" and goto_map.desc:match("definition"))' \
    '  local preview_map = find_buffer_map("gh")' \
    '  assert(preview_map and type(preview_map.callback) == "function" and preview_map.desc == "Preview definition")' \
    '  local code_action_map = find_buffer_map(" .")' \
    '  assert(code_action_map and type(code_action_map.callback) == "function" and code_action_map.desc == "LSP code actions")' \
    '  rename_map.callback()' \
    '  goto_map.callback()' \
    '  preview_map.callback()' \
    '  code_action_map.callback()' \
    '  assert(vim.g.lsp_rename_called and vim.g.lsp_goto_called and vim.g.lsp_preview_called and vim.g.lsp_code_action_called)' \
    '  vim.keymap.del("n", "<F2>", { buffer = 0 })' \
    '  vim.keymap.del("n", "gd", { buffer = 0 })' \
    '  vim.keymap.del("n", "gh", { buffer = 0 })' \
    '  vim.keymap.del("n", " .", { buffer = 0 })' \
    '  vim.lsp.get_client_by_id = original_get_client_by_id' \
    '  vim.lsp.buf.rename = original_rename' \
    '  package.loaded["tiny-code-action"] = nil' \
    '  navigation.goto_definition_or_references = original_goto' \
    '  navigation.preview_definition = original_preview' \
    '  local nav_original_get_clients = vim.lsp.get_clients' \
    '  local nav_original_get_client_by_id = vim.lsp.get_client_by_id' \
    '  local nav_original_request_all = vim.lsp.buf_request_all' \
    '  local nav_original_definition = vim.lsp.buf.definition' \
    '  local nav_original_hover = vim.lsp.buf.hover' \
    '  local nav_original_notify = vim.notify' \
    '  local nav_original_references = telescope_config.references' \
    '  local fake_client = { offset_encoding = "utf-16" }' \
    '  local nav_bufnr = vim.api.nvim_get_current_buf()' \
    '  local definition_result' \
    '  local delay_definition_response = false' \
    '  local pending_definition_response' \
    '  vim.lsp.get_clients = function(filter)' \
    '    assert(filter.bufnr == nav_bufnr and filter.method == "textDocument/definition")' \
    '    return { fake_client }' \
    '  end' \
    '  vim.lsp.get_client_by_id = function(client_id)' \
    '    assert(client_id == 7)' \
    '    return fake_client' \
    '  end' \
    '  vim.lsp.buf_request_all = function(bufnr, method, params, callback)' \
    '    assert(bufnr == nav_bufnr and method == "textDocument/definition")' \
    '    assert(type(params(fake_client).position) == "table")' \
    '    if delay_definition_response then pending_definition_response = callback else callback({ [7] = { result = definition_result } }) end' \
    '  end' \
    '  vim.lsp.buf.definition = function() vim.g.definition_jump_count = (vim.g.definition_jump_count or 0) + 1 end' \
    '  telescope_config.references = function() vim.g.references_count = (vim.g.references_count or 0) + 1 end' \
    '  local source_cursor = vim.api.nvim_win_get_cursor(0)' \
    '  local current_uri = vim.uri_from_bufnr(0)' \
    '  definition_result = {' \
    '    uri = vim.uri_from_fname("/tmp/definition.go"),' \
    '    range = { start = { line = 3, character = 0 }, ["end"] = { line = 3, character = 4 } },' \
    '  }' \
    '  navigation.goto_definition_or_references()' \
    '  assert(vim.g.definition_jump_count == 1 and vim.g.references_count == nil)' \
    '  definition_result = {' \
    '    uri = current_uri,' \
    '    range = {' \
    '      start = { line = source_cursor[1] - 1, character = 0 },' \
    '      ["end"] = { line = source_cursor[1] - 1, character = 5 },' \
    '    },' \
    '  }' \
    '  navigation.goto_definition_or_references()' \
    '  assert(vim.g.references_count == 1)' \
    '  local location_link = {' \
    '    targetUri = current_uri,' \
    '    targetSelectionRange = {' \
    '      start = { line = source_cursor[1] - 1, character = 0 },' \
    '      ["end"] = { line = source_cursor[1] - 1, character = 5 },' \
    '    },' \
    '    targetRange = {' \
    '      start = { line = source_cursor[1] - 1, character = 0 },' \
    '      ["end"] = { line = source_cursor[1], character = 0 },' \
    '    },' \
    '  }' \
    '  definition_result = location_link' \
    '  navigation.goto_definition_or_references()' \
    '  assert(vim.g.references_count == 2)' \
    '  vim.lsp.buf.hover = function(opts)' \
    '    assert(opts.border == "rounded" and opts.focusable == true)' \
    '    vim.g.definition_previewed = (vim.g.definition_previewed or 0) + 1' \
    '  end' \
    '  navigation.preview_definition()' \
    '  assert(vim.g.definition_previewed == 1)' \
    '  navigation.preview_definition()' \
    '  assert(vim.g.definition_previewed == 2)' \
    '  definition_result = location_link' \
    '  delay_definition_response = true' \
    '  navigation.goto_definition_or_references()' \
    '  vim.api.nvim_win_set_cursor(0, { source_cursor[1] + 1, 0 })' \
    '  pending_definition_response({ [7] = { result = definition_result } })' \
    '  assert(vim.g.references_count == 2 and vim.g.definition_jump_count == 1)' \
    '  vim.api.nvim_win_set_cursor(0, source_cursor)' \
    '  vim.lsp.get_clients = nav_original_get_clients' \
    '  vim.lsp.get_client_by_id = nav_original_get_client_by_id' \
    '  vim.lsp.buf_request_all = nav_original_request_all' \
    '  vim.lsp.buf.definition = nav_original_definition' \
    '  vim.lsp.buf.hover = nav_original_hover' \
    '  vim.notify = nav_original_notify' \
    '  telescope_config.references = nav_original_references' \
    '  local expected_servers = { "gopls", "lua_ls", "ts_ls", "cssls", "html", "somesass_ls", "jsonls", "yamlls", "postgres_lsp" }' \
    '  assert(vim.deep_equal(lsp_config.servers, expected_servers))' \
    '  local lsp_plugins = require("plugins.lsp")' \
    '  assert(lsp_plugins[1][1] == "mason-org/mason.nvim")' \
    '  assert(lsp_plugins[1].cmd == "Mason")' \
    '  assert(next(lsp_plugins[1].opts) == nil)' \
    '  assert(lsp_plugins[2][1] == "mason-org/mason-lspconfig.nvim")' \
    '  assert(lsp_plugins[2].event == "VeryLazy")' \
    '  local expected_installs = vim.tbl_filter(function(server)' \
    '    return server ~= "gopls" or vim.fn.executable("go") == 1' \
    '  end, expected_servers)' \
    '  assert(vim.deep_equal(lsp_plugins[2].opts.ensure_installed, expected_installs))' \
    '  assert(vim.deep_equal(lsp_plugins[2].opts.automatic_enable, expected_servers))' \
    '  assert(vim.tbl_contains(lsp_plugins[2].dependencies, "neovim/nvim-lspconfig"))' \
    '  assert(vim.tbl_contains(lsp_plugins[2].dependencies, "b0o/SchemaStore.nvim"))' \
    '  assert(vim.tbl_contains(lsp_plugins[2].dependencies, "hrsh7th/cmp-nvim-lsp"))' \
    '  local navigator = require("plugins.vim_tmux_navigator")' \
    '  assert(navigator[1] == "christoomey/vim-tmux-navigator")' \
    '  assert(vim.tbl_contains(navigator.cmd, "TmuxNavigateLeft"))' \
    '  assert(vim.tbl_contains(navigator.cmd, "TmuxNavigateRight"))' \
    '  assert(navigator.keys[1][1] == "<c-h>")' \
    '  assert(navigator.keys[2][1] == "<c-j>")' \
    '  assert(navigator.keys[3][1] == "<c-k>")' \
    '  assert(navigator.keys[4][1] == "<c-l>")' \
    '  vim.g.lazy_test_loaded = true' \
    'end' \
    'return M' > "$test_root/data/nvim/lazy/lazy.nvim/lua/lazy/init.lua"

XDG_CONFIG_HOME=$test_root/config \
XDG_DATA_HOME=$test_root/data \
XDG_STATE_HOME=$test_root/state \
XDG_CACHE_HOME=$test_root/cache \
NVIM_LOG_FILE=$test_root/nvim.log \
    nvim --headless \
        '+lua if vim.g.lazy_test_loaded ~= true then vim.cmd("cquit") end' \
        '+qa'

grep -Fq 'https://github.com/folke/lazy.nvim.git' "$lazy_config" || fail 'lazy.nvim repository URL is missing'
grep -Fq '"--branch=stable"' "$lazy_config" || fail 'lazy.nvim stable branch is not pinned'
grep -Fq '{ import = "plugins" }' "$lazy_config" || fail 'plugin import is missing'
[ "$(grep -Fc 'require("nvim-treesitter").install(textobjects.treesitter_parsers)' "$config_directory/lua/plugins/textobjects.lua")" = 1 ] || fail 'automatic Treesitter parser installation is missing'
[ "$(sed -n '1p' "$config_directory/lua/plugins/init.lua")" = 'return {}' ] || fail 'initial plugin specification is not empty'
grep -Fq 'vim.o.background = "dark"' "$config_directory/lua/plugins/gruvbox.lua" || fail 'Gruvbox dark background is missing'
grep -Fq 'require("config.theme").apply()' "$config_directory/lua/plugins/gruvbox.lua" || fail 'configured colorscheme selection is not applied'
grep -Fq 'active = "' "$config_directory/lua/config/theme.lua" || fail 'active theme selection is missing'
grep -Fq '"gruvbox.nvim"' "$lazy_lock" || fail 'Gruvbox lockfile entry is missing'
grep -Fq '"oil.nvim"' "$lazy_lock" || fail 'Oil lockfile entry is missing'
grep -Fq '"neogit"' "$lazy_lock" || fail 'Neogit lockfile entry is missing'
grep -Fq '"diffview.nvim"' "$lazy_lock" || fail 'Diffview lockfile entry is missing'
grep -Fq '"baleia.nvim"' "$lazy_lock" || fail 'Baleia lockfile entry is missing'
grep -Fq '"SchemaStore.nvim"' "$lazy_lock" || fail 'SchemaStore lockfile entry is missing'
grep -Fq '"mason.nvim"' "$lazy_lock" || fail 'Mason lockfile entry is missing'
grep -Fq '"mason-lspconfig.nvim"' "$lazy_lock" || fail 'Mason LSP bridge lockfile entry is missing'
grep -Fq '"nvim-lspconfig"' "$lazy_lock" || fail 'nvim-lspconfig lockfile entry is missing'
grep -Fq '"nvim-cmp"' "$lazy_lock" || fail 'nvim-cmp lockfile entry is missing'
grep -Fq '"cmp-nvim-lsp"' "$lazy_lock" || fail 'cmp-nvim-lsp lockfile entry is missing'
grep -Fq '"LuaSnip"' "$lazy_lock" || fail 'LuaSnip lockfile entry is missing'
grep -Fq '"cmp_luasnip"' "$lazy_lock" || fail 'cmp_luasnip lockfile entry is missing'
grep -Fq '"lualine.nvim"' "$lazy_lock" || fail 'lualine lockfile entry is missing'
grep -Fq '"telescope.nvim"' "$lazy_lock" || fail 'Telescope lockfile entry is missing'
grep -Fq '"plenary.nvim"' "$lazy_lock" || fail 'Plenary lockfile entry is missing'
grep -Fq '"nvim-web-devicons"' "$lazy_lock" || fail 'file icons lockfile entry is missing'
grep -Fq '"noice.nvim"' "$lazy_lock" || fail 'Noice lockfile entry is missing'
grep -Fq '"nui.nvim"' "$lazy_lock" || fail 'Nui lockfile entry is missing'
grep -Fq '"auto-session"' "$lazy_lock" || fail 'Auto Session lockfile entry is missing'
grep -Fq 'jidn/vim-dbml' "$config_directory/lua/plugins/dbml.lua" || fail 'DBML syntax plugin is missing'
if grep -Fq 'image.nvim' "$lazy_lock"; then fail 'removed DBML image plugin remains in the lockfile'; fi
if grep -R -Fq 'DBMLPreview' "$config_directory/lua"; then fail 'DBML preview command remains configured'; fi
if grep -Fq 'softwaretechnik/dbml-renderer' "$config_directory/README.md"; then fail 'DBML preview dependency remains documented'; fi
grep -Fq 'tree-sitter-cli' "$config_directory/README.md" || fail 'tree-sitter CLI dependency is missing'
grep -Fq 'brew install tree-sitter-cli' "$config_directory/README.md" || fail 'tree-sitter CLI installation command is missing'
grep -Fq 'tree-sitter-cli-macos-x64.zip' "$config_directory/README.md" || fail 'Intel macOS Tree-sitter binary guidance is missing'
grep -Fq 'official Tree-sitter releases' "$config_directory/README.md" || fail 'Tree-sitter release link is missing'
grep -Fq 'xattr -d com.apple.quarantine' "$config_directory/README.md" || fail 'macOS quarantine guidance is missing'
grep -Fq 'tree-sitter --version' "$config_directory/README.md" || fail 'Tree-sitter verification command is missing'
grep -Fq 'brew install pgformatter' "$config_directory/README.md" || fail 'pgFormatter installation command is missing'
grep -Fq 'postgres_lsp' "$config_directory/README.md" || fail 'Postgres language server documentation is missing'
grep -Fq ':TSUpdate' "$config_directory/README.md" || fail 'Treesitter update step is missing'
grep -Fq 'default_capabilities()' "$config_directory/lua/config/lsp.lua" || fail 'enhanced LSP completion capabilities are missing'
grep -Fq 'vim.lsp.config("postgres_lsp"' "$config_directory/lua/config/lsp.lua" || fail 'Postgres language server configuration is missing'
grep -Fq 'workspace_required = false' "$config_directory/lua/config/lsp.lua" || fail 'Postgres language server should attach without a project configuration file'
grep -Fq '"<C-Space>"' "$config_directory/lua/plugins/completion.lua" || fail 'manual completion mapping is missing'
grep -Fq '"<Tab>"' "$config_directory/lua/plugins/completion.lua" || fail 'next completion mapping is missing'
grep -Fq '"<S-Tab>"' "$config_directory/lua/plugins/completion.lua" || fail 'previous completion mapping is missing'
grep -Fq 'name = "nvim_lsp"' "$config_directory/lua/plugins/completion.lua" || fail 'LSP completion source is missing'
grep -Fq 'name = "luasnip"' "$config_directory/lua/plugins/completion.lua" || fail 'snippet completion source is missing'
grep -Fq 'checkThirdParty = false' "$config_directory/lua/config/lsp.lua" || fail 'Lua workspace configuration is missing'
grep -Fq 'schemastore.json.schemas()' "$config_directory/lua/config/lsp.lua" || fail 'JSON schemas are missing'
grep -Fq 'schemastore.yaml.schemas()' "$config_directory/lua/config/lsp.lua" || fail 'YAML schemas are missing'
grep -Fq 'format = { enable = true }' "$config_directory/lua/config/lsp.lua" || fail 'LSP formatting is not enabled'

XDG_CONFIG_HOME=$test_root/config \
XDG_DATA_HOME=$test_root/data \
XDG_STATE_HOME=$test_root/state \
XDG_CACHE_HOME=$test_root/cache \
NVIM_LOG_FILE=$test_root/nvim.log \
    nvim --clean --headless \
        '+lua assert(vim.filetype.match({ filename = "/tmp/main.go" }) == "go")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/go.mod" }) == "gomod")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/app.tsx" }) == "typescriptreact")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/app.jsx" }) == "javascriptreact")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/style.scss" }) == "scss")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/.gitignore" }) == "gitignore")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/.npmignore" }) == "gitignore")' \
        '+lua assert(vim.filetype.match({ filename = "/tmp/.config/nvim/init.lua" }) == "lua")' \
        '+qa'

printf '%s\n' 'Neovim configuration test passed.'

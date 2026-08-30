vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

vim.opt.cmdheight = 0
vim.opt.showcmd = true
vim.opt.showcmdloc = "statusline"
vim.opt.showmode = false

-- Keep search feedback transient: show the active match while searching, then
-- clear it instead of leaving every match highlighted for the rest of the session.
vim.opt.incsearch = true
vim.opt.hlsearch = false

local feedback_group = vim.api.nvim_create_augroup("nvim-editor-feedback", { clear = true })

local function clear_search_highlight()
  vim.opt.hlsearch = false
  vim.cmd.nohlsearch()
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = feedback_group,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
  desc = "Briefly highlight yanked text",
})

vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = feedback_group,
  pattern = { "/", "?" },
  callback = function()
    vim.opt.hlsearch = true
  end,
  desc = "Enable highlighting during an active search",
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = feedback_group,
  pattern = { "/", "?", ":" },
  callback = clear_search_highlight,
  desc = "Clear search highlighting after searching or commands",
})

vim.api.nvim_create_autocmd("BufLeave", {
  group = feedback_group,
  callback = clear_search_highlight,
  desc = "Clear search highlighting when leaving a buffer",
})

vim.api.nvim_create_autocmd("ModeChanged", {
  group = feedback_group,
  pattern = "n:*",
  callback = clear_search_highlight,
  desc = "Clear search highlighting after leaving Normal mode",
})

local M = {}

local diagnostic_float

local function close_details()
  if not diagnostic_float or not vim.api.nvim_win_is_valid(diagnostic_float) then
    diagnostic_float = nil
    return false
  end

  vim.api.nvim_win_close(diagnostic_float, true)
  diagnostic_float = nil
  return true
end

local function schedule_close_details()
  if not diagnostic_float or not vim.api.nvim_win_is_valid(diagnostic_float) then
    diagnostic_float = nil
    return false
  end

  local winid = diagnostic_float
  vim.schedule(function()
    if vim.api.nvim_win_is_valid(winid) then
      vim.api.nvim_win_close(winid, true)
    end

    if diagnostic_float == winid then
      diagnostic_float = nil
    end
  end)
  return true
end

local function open_details(diagnostic, bufnr)
  if not diagnostic then
    return
  end

  close_details()

  local _, winid = vim.diagnostic.open_float({
    bufnr = bufnr,
    pos = { diagnostic.lnum, diagnostic.col },
    scope = "cursor",
    focus = false,
    border = "rounded",
    source = true,
    header = "",
    close_events = { "BufHidden", "BufLeave", "InsertCharPre", "InsertEnter", "WinLeave" },
  })
  diagnostic_float = winid
end

function M.jump(count)
  vim.diagnostic.jump({
    count = count,
    on_jump = open_details,
  })
end

vim.diagnostic.config({
  signs = true,
  underline = true,
  virtual_text = false,
  virtual_lines = false,
  jump = { wrap = true },
})

vim.keymap.set("n", "[d", function()
  M.jump(-1)
end, { desc = "Previous diagnostic" })

vim.keymap.set("n", "]d", function()
  M.jump(1)
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "<Esc>", function()
  if schedule_close_details() then
    return "<Ignore>"
  end

  return "<Esc>"
end, { expr = true, desc = "Close diagnostic details" })

return M

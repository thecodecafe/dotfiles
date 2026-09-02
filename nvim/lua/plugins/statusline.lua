local statusline = require("config.statusline")

local function selection_count()
  local mode = vim.fn.mode()
  if not mode:match("^[vV\22]") then
    return ""
  end

  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  local line_count = math.abs(end_line - start_line) + 1
  local character_count = vim.fn.wordcount().visual_chars or 0

  return string.format("%dL %dC", line_count, character_count)
end

local function location()
  local cursor = vim.api.nvim_win_get_cursor(0)
  return string.format("%d/%d:%d", cursor[1], vim.api.nvim_buf_line_count(0), cursor[2] + 1)
end

return {
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    priority = 900,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "gruvbox",
        globalstatus = true,
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch" },
        lualine_c = { "filename", statusline.project_path, "diagnostics" },
        lualine_x = { selection_count, "filetype" },
        lualine_y = { "%S" },
        lualine_z = { location },
      },
    },
  },
}

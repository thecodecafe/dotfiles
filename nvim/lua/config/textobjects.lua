local M = {}

M.treesitter_parsers = {
  "bash",
  "css",
  "go",
  "html",
  "javascript",
  "json",
  "lua",
  "markdown",
  "scss",
  "tsx",
  "typescript",
  "vim",
  "vimdoc",
  "yaml",
}

function M.whole_buffer()
  local last_line = vim.api.nvim_buf_line_count(0)
  return {
    from = { line = 1, col = 1 },
    to = { line = last_line, col = 1 },
    vis_mode = "V",
  }
end

function M.mini_ai_opts()
  return {
    custom_textobjects = {
      e = M.whole_buffer,
    },
  }
end

return M

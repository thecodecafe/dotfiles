local M = {}

function M.project_path()
  local filename = vim.api.nvim_buf_get_name(0)
  if filename == "" then
    return ""
  end

  local root = vim.fs.root(0, ".git") or vim.uv.cwd()
  return vim.fs.relpath(root, filename) or filename
end

return M

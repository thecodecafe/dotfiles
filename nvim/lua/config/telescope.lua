local M = {}

function M.project_root()
  return vim.fs.root(0, ".git") or vim.uv.cwd()
end

function M.find_files()
  require("telescope.builtin").find_files({
    cwd = M.project_root(),
    hidden = true,
  })
end

function M.buffers()
  require("telescope.builtin").buffers({
    sort_mru = true,
    ignore_current_buffer = false,
  })
end

function M.workspace_symbols()
  local clients = vim.lsp.get_clients({
    bufnr = 0,
    method = "workspace/symbol",
  })

  if vim.tbl_isempty(clients) then
    vim.notify("No attached language server supports workspace symbols", vim.log.levels.WARN)
    return
  end

  require("telescope.builtin").lsp_dynamic_workspace_symbols()
end

function M.references()
  require("telescope.builtin").lsp_references({
    include_declaration = false,
    include_current_line = true,
    jump_type = "never",
    attach_mappings = function(_, map)
      local actions = require("telescope.actions")
      map("i", "<Tab>", actions.move_selection_next)
      map("i", "<S-Tab>", actions.move_selection_previous)
      map("n", "<Tab>", actions.move_selection_next)
      map("n", "<S-Tab>", actions.move_selection_previous)
      return true
    end,
  })
end

return M

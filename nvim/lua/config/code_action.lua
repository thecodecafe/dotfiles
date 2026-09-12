local M = {}

function M.setup()
  local group = vim.api.nvim_create_augroup("nvim-code-action-picker", { clear = true })
  vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "TinyCodeActionWindowEnterMain",
    callback = function(event)
      local buffer = event.data and event.data.buf
      if not buffer then
        return
      end

      local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, false)
      for index, line in ipairs(lines) do
        local title = line:match("^##%s+%S+%s%s+(.+)$")
        if title then
          lines[index] = title
        elseif line:match("^##%s+") then
          lines[index] = line:gsub("^##%s+", "")
        end
      end

      vim.api.nvim_buf_set_option(buffer, "modifiable", true)
      vim.api.nvim_buf_set_lines(buffer, 0, -1, false, lines)
      vim.api.nvim_buf_set_option(buffer, "modifiable", false)

      vim.keymap.set("n", "<Tab>", "j", {
        buffer = buffer,
        silent = true,
        nowait = true,
      })
      vim.keymap.set("n", "<S-Tab>", "k", {
        buffer = buffer,
        silent = true,
        nowait = true,
      })
    end,
    desc = "Navigate Tiny Code Action picker",
  })
end

function M.open()
  require("tiny-code-action").code_action()
end

return M

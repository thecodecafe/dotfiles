local oil = {
  "stevearc/oil.nvim",
  lazy = false,
  dependencies = {
    {
      "JezerM/oil-lsp-diagnostics.nvim",
      branch = "master",
      opts = { parent_dirs = true },
    },
  },
  opts = {
    default_file_explorer = true,
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<Esc>"] = "actions.close",
      ["gR"] = function()
        local bufnr = vim.api.nvim_get_current_buf()
        require("config.oil_diagnostics").refresh(bufnr, function()
          require("oil.actions").refresh.callback()
        end)
      end,
      ["<leader>r"] = function()
        local bufnr = vim.api.nvim_get_current_buf()
        require("config.oil_diagnostics").refresh(bufnr, function()
          require("oil.actions").refresh.callback()
        end)
      end,
    },
  },
  config = function(_, opts)
    require("oil").setup(opts)
    require("config.oil_diagnostics").setup()
  end,
  keys = {
    { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
  },
}

return oil

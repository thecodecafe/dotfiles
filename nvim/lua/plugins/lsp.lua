local lsp = require("config.lsp")

return {
  {
    "mason-org/mason.nvim",
    cmd = "Mason",
    opts = {},
  },
  {
    "mason-org/mason-lspconfig.nvim",
    dependencies = {
      "mason-org/mason.nvim",
      "neovim/nvim-lspconfig",
      "b0o/SchemaStore.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    opts = {
      ensure_installed = lsp.ensure_installed(),
      automatic_enable = lsp.servers,
    },
    config = function(_, opts)
      lsp.setup(opts)
    end,
  },
}

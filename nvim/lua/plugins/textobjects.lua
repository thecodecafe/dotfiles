local textobjects = require("config.textobjects")

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter").setup()
      require("nvim-treesitter").install(textobjects.treesitter_parsers)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(event)
          pcall(vim.treesitter.start, event.buf)
        end,
        desc = "Start Treesitter for syntax text objects",
      })
    end,
  },
  {
    "nvim-mini/mini.ai",
    lazy = false,
    opts = textobjects.mini_ai_opts(),
    config = function(_, opts)
      require("mini.ai").setup(opts)
    end,
  },
  {
    "nvim-mini/mini.indentscope",
    lazy = false,
    opts = {
      mappings = {
        object_scope = "ii",
        object_scope_with_border = "ai",
      },
      draw = {
        predicate = function()
          return false
        end,
      },
    },
    config = function(_, opts)
      require("mini.indentscope").setup(opts)
    end,
  },
}

local code_action = require("config.code_action")

return {
  {
    "rachartier/tiny-code-action.nvim",
    event = "LspAttach",
    opts = {
      backend = "vim",
      picker = {
        "buffer",
        opts = {
          keymaps = {
            close = { "q", "<Esc>" },
            select = "<CR>",
          },
        },
      },
    },
    config = function(_, opts)
      require("tiny-code-action").setup(opts)
      code_action.setup()
    end,
  },
}

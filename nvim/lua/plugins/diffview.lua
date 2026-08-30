local close_diffview = {
  "n",
  "<leader>dq",
  "<cmd>DiffviewClose<cr>",
  { desc = "Close Diffview" },
}

return {
  {
    "sindrets/diffview.nvim",
    opts = {
      keymaps = {
        view = { close_diffview },
        file_panel = { close_diffview },
        file_history_panel = { close_diffview },
        option_panel = { close_diffview },
        help_panel = { close_diffview },
      },
    },
  },
}

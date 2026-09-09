return {
  {
    "rmagatti/auto-session",
    lazy = false,
    keys = {
      { "<leader>ss", "<cmd>AutoSession save<cr>", desc = "Save session" },
      { "<leader>sd", "<cmd>AutoSession delete<cr>", desc = "Delete session" },
    },
    opts = {
      auto_save = false,
      auto_restore = true,
      auto_create = false,
      auto_restore_last_session = false,
      git_use_branch_name = true,
      git_auto_restore_on_branch_change = true,
      root_dir = vim.fn.expand("~/.nvim-sessions"),
    },
  },
}

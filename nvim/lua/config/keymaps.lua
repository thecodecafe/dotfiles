vim.opt.timeoutlen = 300

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", {
  desc = "Save current file",
  silent = true,
})

vim.keymap.set("i", "jj", "<esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "kk", "<esc>", { desc = "Exit insert mode" })

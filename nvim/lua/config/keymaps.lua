vim.opt.timeoutlen = 300

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", {
  desc = "Save current file",
  silent = true,
})

vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", {
  desc = "Delete current buffer",
})

vim.keymap.set("n", "<leader>bn", "<cmd>bnext<cr>", {
  desc = "Next buffer",
})

vim.keymap.set("n", "<leader>bp", "<cmd>bprevious<cr>", {
  desc = "Previous buffer",
})

vim.keymap.set("n", "<leader>bl", "<cmd>buffer #<cr>", {
  desc = "Toggle last buffer",
})

vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", {
  desc = "Quit Neovim",
})

vim.keymap.set("i", "jj", "<esc>", { desc = "Exit insert mode" })
vim.keymap.set("i", "kk", "<esc>", { desc = "Exit insert mode" })

return {
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
		dependencies = {
			"nvim-telescope/telescope.nvim",
			"sindrets/diffview.nvim",
			"m00qek/baleia.nvim",
		},
		keys = {
			{ "<leader>gg", "<cmd>Neogit kind=vsplit<cr>", desc = "Open Neogit" },
		},
		opts = {
			integrations = {
				telescope = true,
			},
		},
	},
}

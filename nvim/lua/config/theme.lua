local M = {
	active = "cursor-dark",
	colorschemes = {
		gruvbox = "gruvbox",
		kanagawa = "kanagawa-dragon",
		["rose-pine"] = "rose-pine-main",
		catppuccin = "catppuccin-mocha",
		["cursor-dark"] = "cursor-dark",
		vercel = "vercel",
	},
}

M.choices = {
	{ name = "gruvbox", label = "Gruvbox" },
	{ name = "kanagawa", label = "Kanagawa Dragon" },
	{ name = "rose-pine", label = "Rosé Pine Main" },
	{ name = "catppuccin", label = "Catppuccin Mocha" },
	{ name = "cursor-dark", label = "Cursor Dark" },
	{ name = "vercel", label = "Vercel Dark" },
}

function M.apply(name)
	local selected = name or M.active
	local colorscheme = M.colorschemes[selected]
	if not colorscheme then
		local available = table.concat(vim.tbl_keys(M.colorschemes), ", ")
		error(("Unknown theme '%s'. Choose one of: %s"):format(selected, available))
	end

	vim.o.background = "dark"
	if selected == "catppuccin" then
		require("catppuccin").setup({
			flavour = "mocha",
			background = { dark = "mocha", light = "latte" },
		})
	elseif selected == "cursor-dark" then
		require("cursor-dark").setup({ style = "dark" })
	elseif selected == "vercel" then
		require("vercel").setup({ theme = "dark" })
	end

	vim.cmd.colorscheme(colorscheme)
	if selected == "cursor-dark" then
		vim.cmd.highlight("Normal guibg=#000000")
		vim.cmd.highlight("NormalNC guibg=#000000")

		local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
		for _, group in ipairs({ "WinBar", "WinBarNC" }) do
			local highlights = vim.api.nvim_get_hl(0, { name = group, link = false })
			highlights.fg = normal.fg
			highlights.bg = "#000000"
			vim.api.nvim_set_hl(0, group, highlights)
		end
	end
end

return M

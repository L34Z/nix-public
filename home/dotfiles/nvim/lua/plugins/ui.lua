-- UI niceties: statusline, keybind hints, autopairs, comments, indent guides,
-- TODO highlighting, and a start dashboard.
return {
	{ "nvim-tree/nvim-web-devicons", lazy = true },

	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			-- Prefer the matugen-generated "dms" lualine theme (matches the
			-- colorscheme); fall back to "auto" before it's been generated.
			local theme = "auto"
			if pcall(require, "lualine.themes.dms") then
				theme = "dms"
			end
			require("lualine").setup({
				options = {
					theme = theme,
					globalstatus = true,
					section_separators = "",
					component_separators = "",
				},
			})
		end,
	},

	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {},
	},

	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {},
	},

	{
		"numToStr/Comment.nvim",
		keys = {
			{ "gc", mode = { "n", "v" }, desc = "Comment toggle (linewise)" },
			{ "gb", mode = { "n", "v" }, desc = "Comment toggle (blockwise)" },
		},
		opts = {},
	},

	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPost", "BufNewFile" },
		opts = {},
	},

	{
		"folke/todo-comments.nvim",
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		opts = {},
	},

	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("alpha").setup(require("alpha.themes.startify").config)
		end,
	},
}

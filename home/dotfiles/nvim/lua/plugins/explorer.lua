-- File explorer — oil.nvim: edit the filesystem like a normal buffer.
-- `-` opens the parent dir; edit lines and :w to create/rename/delete.
return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = false, -- so oil can take over `nvim <dir>`
		keys = {
			{ "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
			{ "<leader>ee", "<cmd>Oil<CR>", desc = "File explorer" },
		},
		opts = {
			view_options = { show_hidden = true },
		},
	},
}

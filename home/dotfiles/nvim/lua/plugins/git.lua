-- Git — inline signs, hunk staging/navigation, blame.
return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(keys, fn, desc)
					vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = "Git: " .. desc })
				end
				map("]c", function() gs.nav_hunk("next") end, "Next hunk")
				map("[c", function() gs.nav_hunk("prev") end, "Previous hunk")
				map("<leader>gs", gs.stage_hunk, "Stage hunk")
				map("<leader>gr", gs.reset_hunk, "Reset hunk")
				map("<leader>gp", gs.preview_hunk, "Preview hunk")
				map("<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
			end,
		},
	},
}

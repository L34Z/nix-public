-- Treesitter — syntax-aware highlighting/indent. Grammars compile at runtime
-- via gcc + tree-sitter CLI (provided by home/devtools.nix).
--
-- Pinned to the `master` branch: nvim-treesitter's new default `main` branch
-- is a full rewrite that removed the classic API this config uses
-- (get_parser_configs, configs.setup, ensure_installed).
--
-- Odin has no grammar in the default registry, so it's added explicitly.
return {
	{
		"nvim-treesitter/nvim-treesitter",
		branch = "master",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local parsers = require("nvim-treesitter.parsers").get_parser_configs()
			if not parsers.odin then
				parsers.odin = {
					install_info = {
						url = "https://github.com/tree-sitter-grammars/tree-sitter-odin",
						files = { "src/parser.c", "src/scanner.c" },
						branch = "main",
					},
					filetype = "odin",
				}
			end

			require("nvim-treesitter.configs").setup({
				ensure_installed = { "c", "rust", "nim", "python", "lua", "vim", "vimdoc", "bash", "markdown" },
				auto_install = true, -- pull a grammar the first time a filetype opens
				highlight = { enable = true },
				indent = { enable = true },
			})
		end,
	},
}

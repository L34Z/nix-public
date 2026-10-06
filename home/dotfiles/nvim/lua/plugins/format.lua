-- Formatting — conform.nvim, format-on-save. Formatters come from Nix
-- (home/devtools.nix), except rustfmt which rides in the rust dev shell.
return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		opts = {
			-- Odin is intentionally absent: it has no CLI formatter here, so the
			-- lsp_format fallback below routes it to ols.
			formatters_by_ft = {
				c = { "clang_format" },
				rust = { "rustfmt" },
				nim = { "nph" },
				typescript = { "prettier" },
				typescriptreact = { "prettier" }, -- .tsx
				python = { "ruff_format" },
				lua = { "stylua" }, -- best-effort; only runs if stylua is on PATH
			},
			format_on_save = {
				timeout_ms = 1000,
				lsp_format = "fallback", -- fall back to LSP formatting (e.g. ols) if no CLI formatter
			},
		},
	},
}

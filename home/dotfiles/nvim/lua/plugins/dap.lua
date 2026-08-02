-- Debugging — nvim-dap + UI. Adapters are best-effort (see home/devtools.nix):
-- lldb-dap covers native binaries (C/Rust/Odin/Nim); debugpy covers Python.
-- Everything is pcall-guarded so a missing adapter never breaks startup.
return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			{ "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "DAP: toggle breakpoint" },
			{ "<leader>dc", function() require("dap").continue() end, desc = "DAP: continue/start" },
			{ "<leader>di", function() require("dap").step_into() end, desc = "DAP: step into" },
			{ "<leader>do", function() require("dap").step_over() end, desc = "DAP: step over" },
			{ "<leader>du", function() require("dapui").toggle() end, desc = "DAP: toggle UI" },
		},
		config = function()
			local dap = require("dap")
			local dapui = require("dapui")
			dapui.setup()
			require("nvim-dap-virtual-text").setup()

			-- Auto-open/close the UI around a debug session.
			dap.listeners.after.event_initialized["dapui"] = function() dapui.open() end
			dap.listeners.before.event_terminated["dapui"] = function() dapui.close() end
			dap.listeners.before.event_exited["dapui"] = function() dapui.close() end

			-- lldb-dap adapter (ships with the `lldb` Nix package).
			if vim.fn.executable("lldb-dap") == 1 then
				dap.adapters.lldb = { type = "executable", command = "lldb-dap", name = "lldb" }
				local native = {
					{
						name = "Launch (build/<bin>)",
						type = "lldb",
						request = "launch",
						program = function()
							return vim.fn.input("Executable: ", vim.fn.getcwd() .. "/build/", "file")
						end,
						cwd = "${workspaceFolder}",
						stopOnEntry = false,
					},
				}
				for _, ft in ipairs({ "c", "rust", "odin", "nim" }) do
					dap.configurations[ft] = native
				end
			end

			-- Python via debugpy — only if nvim-dap-python and debugpy resolve.
			pcall(function()
				require("dap-python").setup("python3")
			end)
		end,
	},
	{ "mfussenegger/nvim-dap-python", ft = "python" },
}

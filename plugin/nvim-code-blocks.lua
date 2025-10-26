-- Prevent loading plugin twice
if vim.g.loaded_nvim_code_blocks == 1 then
	return
end
vim.g.loaded_nvim_code_blocks = 1

-- Create user commands
vim.api.nvim_create_user_command("CodeBlockYank", function(opts)
	local register = opts.args ~= "" and opts.args or nil
	require("nvim-code-blocks").yank_block(register)
end, { nargs = "?", desc = "Yank code block to register" })

vim.api.nvim_create_user_command("CodeBlockDelete", function(opts)
	local register = opts.args ~= "" and opts.args or nil
	require("nvim-code-blocks").delete_block(register)
end, { nargs = "?", desc = "Delete code block to register" })

vim.api.nvim_create_user_command("CodeBlockHighlight", function()
	require("nvim-code-blocks").highlight_block()
end, { desc = "Highlight code block" })

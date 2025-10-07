-- Prevent loading plugin twice
if vim.g.loaded_nvim_code_blocks == 1 then
	return
end
vim.g.loaded_nvim_code_blocks = 1

-- Create user commands
vim.api.nvim_create_user_command("CodeBlockYank", function()
	require("nvim-code-blocks").yank_block()
end, { desc = "Yank code block" })

vim.api.nvim_create_user_command("CodeBlockDelete", function()
	require("nvim-code-blocks").delete_block()
end, { desc = "Delete code block" })

vim.api.nvim_create_user_command("CodeBlockPaste", function()
	require("nvim-code-blocks").paste_block()
end, { desc = "Paste code block" })

vim.api.nvim_create_user_command("CodeBlockHighlight", function()
	require("nvim-code-blocks").highlight_block()
end, { desc = "Highlight code block" })

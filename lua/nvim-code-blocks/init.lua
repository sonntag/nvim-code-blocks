local M = {}

-- State
M.namespace = vim.api.nvim_create_namespace("nvim-code-blocks")
M.current_block = nil
M.extmarks = {}
M.yanked_block = nil

-- Default configuration
M.config = {
	-- Highlight configuration
	highlight = {
		enabled = true,
		hl_group = "CodeBlock",
		auto_update = true,
	},
	-- Treesitter node types to consider as blocks (per filetype)
	block_nodes = {
		default = {
			"function_definition",
			"function_declaration",
			"method_definition",
			"class_definition",
			"block",
			"do_block",
			"if_statement",
			"for_statement",
			"while_statement",
		},
		clojure = { "list_lit", "vec_lit", "map_lit", "set_lit" },
		lua = { "function_definition", "do_statement", "if_statement", "for_statement", "while_statement" },
	},
}

-- Setup function to initialize the plugin
function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts or {})

	-- Setup highlight groups
	if M.config.highlight.enabled then
		vim.api.nvim_set_hl(0, M.config.highlight.hl_group, {
			bg = "#2d3139",
			default = true,
		})
	end

	-- Setup autocmd for automatic highlighting
	if M.config.highlight.auto_update then
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
			callback = function()
				M.update_highlight()
			end,
			group = vim.api.nvim_create_augroup("nvim-code-blocks", { clear = true }),
		})
	end
end

-- Get the smallest Treesitter node containing the cursor
function M.get_containing_block()
	local bufnr = vim.api.nvim_get_current_buf()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local row, col = cursor[1] - 1, cursor[2]

	-- Check if Treesitter is available
	local ok, ts_utils = pcall(require, "nvim-treesitter.ts_utils")
	if not ok then
		return nil
	end

	local parser = vim.treesitter.get_parser(bufnr)
	if not parser then
		return nil
	end

	local tree = parser:parse()[1]
	if not tree then
		return nil
	end

	local root = tree:root()
	local node = root:named_descendant_for_range(row, col, row, col)

	if not node then
		return nil
	end

	-- Get the filetype-specific block nodes
	local ft = vim.bo.filetype
	local block_types = M.config.block_nodes[ft] or M.config.block_nodes.default

	-- Walk up the tree to find a block node
	while node do
		local node_type = node:type()
		for _, block_type in ipairs(block_types) do
			if node_type == block_type then
				local start_row, start_col, end_row, end_col = node:range()
				return {
					node = node,
					start_row = start_row,
					start_col = start_col,
					end_row = end_row,
					end_col = end_col,
				}
			end
		end
		node = node:parent()
	end

	return nil
end

-- Get the rectangular bounds of a block (min col, max col)
function M.get_block_bounds(block)
	if not block then
		return nil
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, block.start_row, block.end_row + 1, false)

	local min_col = math.huge
	local max_col = 0

	for _, line in ipairs(lines) do
		-- Find first non-whitespace character
		local first_char = line:match("^%s*()%S")
		if first_char then
			min_col = math.min(min_col, first_char - 1)
		end
		max_col = math.max(max_col, #line)
	end

	-- If all lines are empty, use start_col
	if min_col == math.huge then
		min_col = block.start_col
	end

	return {
		start_row = block.start_row,
		end_row = block.end_row,
		min_col = min_col,
		max_col = max_col,
	}
end

-- Clear all extmarks
function M.clear_highlight()
	local bufnr = vim.api.nvim_get_current_buf()
	vim.api.nvim_buf_clear_namespace(bufnr, M.namespace, 0, -1)
	M.extmarks = {}
end

-- Update highlight for current block
function M.update_highlight()
	if not M.config.highlight.enabled then
		return
	end

	M.clear_highlight()

	local block = M.get_containing_block()
	if not block then
		M.current_block = nil
		return
	end

	local bounds = M.get_block_bounds(block)
	if not bounds then
		return
	end

	M.current_block = bounds

	local bufnr = vim.api.nvim_get_current_buf()

	-- Create extmarks for each line in the block
	for row = bounds.start_row, bounds.end_row do
		local extmark = vim.api.nvim_buf_set_extmark(bufnr, M.namespace, row, bounds.min_col, {
			end_row = row,
			end_col = math.max(bounds.max_col, bounds.min_col + 1),
			hl_group = M.config.highlight.hl_group,
			hl_eol = true,
			priority = 100,
		})
		table.insert(M.extmarks, extmark)
	end
end

-- Normalize leading whitespace in text
function M.normalize_whitespace(lines)
	if #lines == 0 then
		return lines
	end

	-- Find minimum leading whitespace
	local min_indent = math.huge
	for _, line in ipairs(lines) do
		if line:match("%S") then -- Skip empty lines
			local indent = line:match("^%s*"):len()
			min_indent = math.min(min_indent, indent)
		end
	end

	if min_indent == math.huge then
		return lines
	end

	-- Remove common leading whitespace
	local normalized = {}
	for _, line in ipairs(lines) do
		if line:match("%S") then
			table.insert(normalized, line:sub(min_indent + 1))
		else
			table.insert(normalized, "")
		end
	end

	return normalized
end

-- Yank code block
function M.yank_block()
	local block = M.get_containing_block()
	if not block then
		vim.notify("No code block found at cursor", vim.log.levels.WARN)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, block.start_row, block.end_row + 1, false)

	-- Normalize leading whitespace
	local normalized = M.normalize_whitespace(lines)

	-- Store for paste operation
	M.yanked_block = {
		lines = normalized,
		block = block,
	}

	-- Yank to default register
	vim.fn.setreg('"', table.concat(normalized, "\n"))

	vim.notify(string.format("Yanked %d lines", #normalized), vim.log.levels.INFO)
end

-- Delete code block
function M.delete_block()
	local block = M.get_containing_block()
	if not block then
		vim.notify("No code block found at cursor", vim.log.levels.WARN)
		return
	end

	local bufnr = vim.api.nvim_get_current_buf()

	-- Delete the lines
	vim.api.nvim_buf_set_lines(bufnr, block.start_row, block.end_row + 1, false, {})

	vim.notify(string.format("Deleted block (%d lines)", block.end_row - block.start_row + 1), vim.log.levels.INFO)
end

-- Paste code block
function M.paste_block()
	if not M.yanked_block then
		vim.notify("No yanked block to paste", vim.log.levels.WARN)
		return
	end

	local cursor = vim.api.nvim_win_get_cursor(0)
	local row = cursor[1] - 1
	local bufnr = vim.api.nvim_get_current_buf()

	-- Get current line's indentation
	local current_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local current_indent = current_line:match("^%s*"):len()

	-- Apply current indentation to yanked lines
	local indented = {}
	local indent_str = string.rep(" ", current_indent)
	for _, line in ipairs(M.yanked_block.lines) do
		if line:match("%S") then
			table.insert(indented, indent_str .. line)
		else
			table.insert(indented, "")
		end
	end

	-- Insert at cursor position
	vim.api.nvim_buf_set_lines(bufnr, row + 1, row + 1, false, indented)

	vim.notify(string.format("Pasted %d lines", #indented), vim.log.levels.INFO)
end

-- Highlight code block (manual trigger)
function M.highlight_block()
	M.update_highlight()
end

return M

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
		lua = { "function_declaration", "block", "if_statement", "for_statement", "while_statement", "do_statement" },
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

	-- Try to get parser, but catch errors for missing parsers
	local ok_parser, parser = pcall(vim.treesitter.get_parser, bufnr)
	if not ok_parser or not parser then
		return nil
	end

	-- Try to parse, catching errors
	local ok_parse, trees = pcall(function()
		return parser:parse()
	end)
	if not ok_parse or not trees or #trees == 0 then
		return nil
	end

	local tree = trees[1]
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
	local candidate_block = nil
	while node do
		local node_type = node:type()
		for _, block_type in ipairs(block_types) do
			if node_type == block_type then
				local start_row, start_col, end_row, end_col = node:range()
				local block = {
					node = node,
					start_row = start_row,
					start_col = start_col,
					end_row = end_row,
					end_col = end_col,
				}

				-- Check if cursor is within the block's column range
				-- Get the bounds to check min_col
				local bounds = M.get_block_bounds(block)
				if bounds then
					-- Get cursor's display column
					local current_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
					local cursor_display_col

					if #current_line == 0 or col >= #current_line then
						-- Empty line or cursor in virtual space: use virtcol() for accurate position
						cursor_display_col = vim.fn.virtcol(".")
					else
						-- Normal line: calculate from line content
						cursor_display_col = vim.fn.strdisplaywidth(current_line:sub(1, col))
					end

					-- If cursor is at or after the block's left edge, this is our block
					if cursor_display_col >= bounds.min_col_display then
						return block
					end

					-- Otherwise, keep this as a candidate and continue searching parents
					candidate_block = block
				else
					-- If we can't get bounds, just use this block
					return block
				end
			end
		end
		node = node:parent()
	end

	-- If we found a candidate but cursor was left of it, return the candidate
	-- (this means we're in the indentation area of the innermost block)
	return candidate_block
end

-- Get the rectangular bounds of a block (min col, max col)
function M.get_block_bounds(block)
	if not block then
		return nil
	end

	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, block.start_row, block.end_row + 1, false)

	local min_col_byte = math.huge
	local min_col_display = math.huge
	local max_col = 0

	for _, line in ipairs(lines) do
		-- Find first non-whitespace character (byte position)
		local first_char = line:match("^%s*()%S")
		if first_char then
			local byte_pos = first_char - 1
			min_col_byte = math.min(min_col_byte, byte_pos)
			-- Calculate display width of leading whitespace
			local leading_ws = line:sub(1, byte_pos)
			local display_pos = vim.fn.strdisplaywidth(leading_ws)
			min_col_display = math.min(min_col_display, display_pos)
		end
		-- Use vim.fn.strdisplaywidth for accurate display width with tabs
		max_col = math.max(max_col, vim.fn.strdisplaywidth(line))
	end

	-- If all lines are empty, use start_col
	if min_col_byte == math.huge then
		min_col_byte = block.start_col
		min_col_display = block.start_col
	end

	return {
		start_row = block.start_row,
		end_row = block.end_row,
		min_col = min_col_byte, -- byte position for extmark placement
		min_col_display = min_col_display, -- display width for virtual text
		max_col = max_col, -- display width
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

	-- Extend max_col to include cursor if it's to the right
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cursor_virtcol = vim.fn.virtcol(".")
	if cursor_virtcol > bounds.max_col then
		bounds.max_col = cursor_virtcol
	end

	M.current_block = bounds

	local bufnr = vim.api.nvim_get_current_buf()

	-- Create extmarks for each line in the block
	for row = bounds.start_row, bounds.end_row do
		-- Get the actual line to check its length
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
		local line_len = #line
		local line_display_width = vim.fn.strdisplaywidth(line)

		-- For empty lines, add virtual text at column 0
		if line_len == 0 then
			-- Create virtual text with leading spaces + highlighted section
			-- Use display widths for proper tab handling
			local leading = string.rep(" ", bounds.min_col_display)
			local highlighted = string.rep(" ", bounds.max_col - bounds.min_col_display)

			local ok, extmark = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, row, 0, {
				virt_text = {
					{ leading },
					{ highlighted, M.config.highlight.hl_group }
				},
				virt_text_pos = "inline",
				priority = 100,
			})
			if ok then
				table.insert(M.extmarks, extmark)
			end
		else
			-- Ensure start_col is valid
			local start_col = math.min(bounds.min_col, line_len)

			-- For the main highlight, go to end of actual line content
			-- Use end_line instead of end_col to highlight entire line
			local ok1, extmark1 = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, row, start_col, {
				end_line = row + 1,
				hl_group = M.config.highlight.hl_group,
				priority = 100,
			})

			if ok1 then
				table.insert(M.extmarks, extmark1)
			end

			-- Add virtual text to extend to max_col (display width)
			local virt_text_len = math.max(0, bounds.max_col - line_display_width)
			if virt_text_len > 0 then
				local ok2, extmark2 = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, row, line_len, {
					virt_text = { { string.rep(" ", virt_text_len), M.config.highlight.hl_group } },
					virt_text_pos = "overlay",
					priority = 100,
				})
				if ok2 then
					table.insert(M.extmarks, extmark2)
				end
			end
		end
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

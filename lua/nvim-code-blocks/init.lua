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
		lua = { "function_declaration", "function_definition", "function_call", "variable_declaration", "arguments", "table_constructor", "block", "if_statement", "for_statement", "while_statement", "do_statement" },
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

	-- Get cursor's display column once
	local current_line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
	local cursor_display_col

	if #current_line == 0 or col >= #current_line then
		-- Empty line or cursor in virtual space: use virtcol() for accurate position
		cursor_display_col = vim.fn.virtcol(".")
	else
		-- Normal line: calculate from line content
		cursor_display_col = vim.fn.strdisplaywidth(current_line:sub(1, col))
	end

	-- Walk up the tree and collect all matching blocks with depth info
	local matching_blocks = {}
	local depth = 0
	local temp_node = node
	while temp_node do
		local node_type = temp_node:type()
		for _, block_type in ipairs(block_types) do
			if node_type == block_type then
				local start_row, start_col, end_row, end_col = temp_node:range()
				local block = {
					node = temp_node,
					start_row = start_row,
					start_col = start_col,
					end_row = end_row,
					end_col = end_col,
				}

				-- Get the bounds
				local bounds = M.get_block_bounds(block)
				if bounds then
					table.insert(matching_blocks, {
						block = block,
						bounds = bounds,
						depth = depth, -- Track depth in tree (smaller = deeper/more specific)
					})
				end
			end
		end
		temp_node = temp_node:parent()
		depth = depth + 1
	end

	-- Find the best matching block
	-- Strategy:
	-- 1. If any blocks start on cursor line, pick the one closest to (but before/at) cursor
	-- 2. Otherwise, pick by depth then size
	local best_block = nil
	local best_depth = math.huge
	local smallest_size = math.huge
	local closest_start_col = -1
	local has_block_on_cursor_line = false

	-- First pass: check if any blocks start on cursor line
	for _, match in ipairs(matching_blocks) do
		local block = match.block
		local bounds = match.bounds

		if cursor_display_col >= bounds.min_col_display and block.start_row == row then
			has_block_on_cursor_line = true
			break
		end
	end

	-- Second pass: find best block
	for _, match in ipairs(matching_blocks) do
		local block = match.block
		local bounds = match.bounds
		local depth = match.depth

		-- Check if cursor is at or after the block's left edge
		if cursor_display_col >= bounds.min_col_display then
			-- Calculate block size (number of lines)
			local size = bounds.end_row - bounds.start_row + 1

			local is_better = false

			if has_block_on_cursor_line then
				-- Only consider blocks that start on cursor line
				if block.start_row == row then
					local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
					local start_col = vim.fn.strdisplaywidth(line:sub(1, block.start_col))

					-- Pick block with start closest to cursor (but at or before cursor)
					if start_col <= cursor_display_col and start_col > closest_start_col then
						is_better = true
						closest_start_col = start_col
					elseif start_col == closest_start_col then
						-- Tie: use depth and size
						is_better = depth < best_depth or (depth == best_depth and size < smallest_size)
					end
				end
			else
				-- No blocks on cursor line, use depth and size
				is_better = depth < best_depth or (depth == best_depth and size < smallest_size)
			end

			if is_better then
				best_block = block
				best_depth = depth
				smallest_size = size
			end
		end
	end

	-- If we found a block where cursor is inside, return it
	if best_block then
		return best_block
	end

	-- Otherwise, cursor is left of all blocks, return the innermost one (lowest depth)
	if #matching_blocks > 0 then
		return matching_blocks[1].block
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

	local min_col_byte = math.huge
	local min_col_display = math.huge
	local max_col = 0

	for i, line in ipairs(lines) do
		local is_first_line = (i == 1)

		-- For the first line, only consider content starting from block.start_col
		local effective_line = line
		local col_offset = 0
		if is_first_line and block.start_col > 0 then
			effective_line = line:sub(block.start_col + 1)
			col_offset = block.start_col
			-- Calculate display width up to start_col for offset
			local prefix = line:sub(1, block.start_col)
			col_offset = vim.fn.strdisplaywidth(prefix)
		end

		-- Find first non-whitespace character (byte position) in effective line
		local first_char = effective_line:match("^%s*()%S")
		if first_char then
			local byte_pos = first_char - 1 + (is_first_line and block.start_col or 0)
			min_col_byte = math.min(min_col_byte, byte_pos)
			-- Calculate display width of leading whitespace
			local leading_ws = effective_line:sub(1, first_char - 1)
			local display_pos = vim.fn.strdisplaywidth(leading_ws) + col_offset
			min_col_display = math.min(min_col_display, display_pos)
		end

		-- For max_col, use the full line width (not offset by start_col)
		max_col = math.max(max_col, vim.fn.strdisplaywidth(line))
	end

	-- If all lines are empty, use start_col
	if min_col_byte == math.huge then
		min_col_byte = block.start_col
		local first_line = lines[1] or ""
		local prefix = first_line:sub(1, block.start_col)
		min_col_display = vim.fn.strdisplaywidth(prefix)
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

	-- Store both bounds and original block for later use
	M.current_block = bounds
	M.current_block_node = block

	local bufnr = vim.api.nvim_get_current_buf()

	-- Create extmarks for each line in the block
	for row = bounds.start_row, bounds.end_row do
		-- Get the actual line to check its length
		local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ""
		local line_len = #line
		local line_display_width = vim.fn.strdisplaywidth(line)

		-- Check if this is the first line and block starts mid-line
		local is_first_line = (row == bounds.start_row)
		local start_col_override = nil
		if is_first_line and M.current_block_node and M.current_block_node.start_col > 0 then
			-- Block starts after beginning of line, only highlight from block.start_col
			start_col_override = M.current_block_node.start_col
		end

		-- Check if this is the last line and block ends mid-line
		local is_last_line = (row == bounds.end_row)
		local end_col_limit = nil
		if is_last_line and M.current_block_node and M.current_block_node.end_col < line_len then
			-- Block ends before the line ends, only highlight up to block.end_col
			end_col_limit = M.current_block_node.end_col
		end

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
			-- Determine start column
			local start_col
			if start_col_override then
				-- First line with mid-line start: use block's actual start
				start_col = start_col_override
			else
				-- Normal line: use bounds min_col
				start_col = math.min(bounds.min_col, line_len)
			end

			-- For the main highlight
			local ok1, extmark1
			if end_col_limit then
				-- Last line with mid-line end: highlight from start_col to end_col
				ok1, extmark1 = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, row, start_col, {
					end_row = row,
					end_col = end_col_limit,
					hl_group = M.config.highlight.hl_group,
					priority = 100,
				})
			else
				-- Normal line: highlight to end of line
				ok1, extmark1 = pcall(vim.api.nvim_buf_set_extmark, bufnr, M.namespace, row, start_col, {
					end_line = row + 1,
					hl_group = M.config.highlight.hl_group,
					priority = 100,
				})
			end

			if ok1 then
				table.insert(M.extmarks, extmark1)
			end

			-- Add virtual text to extend to max_col (display width)
			-- But not on last line if block ends mid-line
			if not end_col_limit then
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

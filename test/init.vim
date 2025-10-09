" Minimal init.vim for testing nvim-code-blocks

" Set leader key to space
let mapleader = " "

" Use system clipboard
set clipboard=unnamedplus

" Allow cursor to move freely in all areas, including past end of line
" This keeps cursor at indentation level on blank lines
set virtualedit=all

" Add plugin to runtimepath
set rtp+=.

" Setup the plugin
lua << EOF
-- Setup the plugin
require('nvim-code-blocks').setup({
  highlight = {
    enabled = true,
    hl_group = "CodeBlock",
    auto_update = true,
  },
})

-- Create keybindings for testing
vim.keymap.set('n', '<leader>cy', function()
  require('nvim-code-blocks').yank_block()
end, { desc = 'Yank code block' })

vim.keymap.set('n', '<leader>cd', function()
  require('nvim-code-blocks').delete_block()
end, { desc = 'Delete code block' })

vim.keymap.set('n', '<leader>cp', function()
  require('nvim-code-blocks').paste_block()
end, { desc = 'Paste code block' })

vim.keymap.set('n', '<leader>ch', function()
  require('nvim-code-blocks').highlight_block()
end, { desc = 'Highlight code block' })

-- Debug command to check treesitter
vim.keymap.set('n', '<leader>ct', function()
  local ok, ts = pcall(require, 'nvim-treesitter.ts_utils')
  if not ok then
    print("nvim-treesitter NOT available")
    return
  end

  local parser = vim.treesitter.get_parser(0)
  if not parser then
    print("No Treesitter parser for this buffer")
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    print("Could not parse buffer")
    return
  end

  print("Treesitter is working!")

  -- Show all parent nodes from cursor
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local root = tree:root()
  local node = root:named_descendant_for_range(row, col, row, col)

  print("Node types from cursor up:")
  while node do
    print("  - " .. node:type())
    node = node:parent()
  end

  -- Try to get block
  local block = require('nvim-code-blocks').get_containing_block()
  if block then
    print(string.format("Found block: %s (lines %d-%d)",
      block.node:type(), block.start_row + 1, block.end_row + 1))
  else
    print("No block found at cursor")
  end
end, { desc = 'Test treesitter' })

-- Debug command
vim.keymap.set('n', '<leader>cc', function()
  local plugin = require('nvim-code-blocks')

  print("=== Debug Info ===")

  -- Get cursor position
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1] - 1, cursor[2]
  local cursor_display_col = vim.fn.virtcol(".")

  print(string.format("Cursor: row=%d, col=%d, display_col=%d", row, col, cursor_display_col))

  -- Get treesitter node info
  local ok_parser, parser = pcall(vim.treesitter.get_parser, 0)
  if ok_parser and parser then
    local trees = parser:parse()
    if trees and #trees > 0 then
      local root = trees[1]:root()
      local node = root:named_descendant_for_range(row, col, row, col)

      print("\nAll parent blocks:")
      local temp_node = node
      local depth = 0
      while temp_node do
        local node_type = temp_node:type()
        local sr, sc, er, ec = temp_node:range()
        print(string.format("  depth=%d, type=%s, lines=%d-%d", depth, node_type, sr + 1, er + 1))
        temp_node = temp_node:parent()
        depth = depth + 1
      end
    end
  end

  -- Show which blocks are candidates
  print("\nCandidate blocks on cursor line:")
  if ok_parser and parser then
    local trees = parser:parse()
    if trees and #trees > 0 then
      local root = trees[1]:root()
      local node = root:named_descendant_for_range(row, col, row, col)
      local temp_node = node
      while temp_node do
        local node_type = temp_node:type()
        local sr, sc, er, ec = temp_node:range()
        if sr == row then
          local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
          local start_display_col = vim.fn.strdisplaywidth(line:sub(1, sc))
          print(string.format("  type=%s, start_byte_col=%d, start_display_col=%d", node_type, sc, start_display_col))
        end
        temp_node = temp_node:parent()
      end
    end
  end

  -- Get block info
  local block = plugin.get_containing_block()
  if not block then
    print("\nNo block found")
    return
  end

  print(string.format("\nSelected block: %s (lines %d-%d), start_col=%d",
    block.node:type(), block.start_row + 1, block.end_row + 1, block.start_col))

  -- Get bounds
  local bounds = plugin.get_block_bounds(block)
  if bounds then
    print(string.format("Bounds: min_col_display=%d, max_col=%d", bounds.min_col_display, bounds.max_col))

    -- Show what lines were used for bounds calculation
    print("\nLines in block for bounds calc:")
    local lines = vim.api.nvim_buf_get_lines(0, block.start_row, block.end_row + 1, false)
    for i, line in ipairs(lines) do
      print(string.format("  [%d]: %s", block.start_row + i, line))
    end
  end
end, { desc = 'Debug code blocks' })

print("nvim-code-blocks loaded! Use <leader>cy/cd/cp/ch to test")
print("Use <leader>ct to check if treesitter is working")
EOF

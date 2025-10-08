" Minimal init.vim for testing nvim-code-blocks

" Set leader key to space
let mapleader = " "

" Use system clipboard
set clipboard=unnamedplus

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

print("nvim-code-blocks loaded! Use <leader>cy/cd/cp/ch to test")
print("Use <leader>ct to check if treesitter is working")
EOF

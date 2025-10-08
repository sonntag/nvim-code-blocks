# Testing nvim-code-blocks

## Quick Start

### Option 1: Test with minimal config (recommended)

1. From the project root, run:
   ```bash
   nvim -u test/init.vim test/test.lua
   ```

2. This loads the plugin with a minimal config and opens a test file.

### Option 2: Test in your regular Neovim

If you use a plugin manager like lazy.nvim, add to your config:

```lua
{
  dir = "/Users/justin/Development/sonntag/nvim-code-blocks",
  config = function()
    require("nvim-code-blocks").setup()
  end,
}
```

## Testing the Features

### 1. Test Automatic Highlighting

- Open `test/test.lua` in Neovim
- Move your cursor around with `j` and `k`
- You should see a rectangular background highlight around the code block containing your cursor
- Try moving into different functions and if statements

### 2. Test Block Yanking

- Move cursor inside `inner_function`
- Press `<leader>cy` (or `:CodeBlockYank`)
- You should see "Yanked X lines" notification
- The entire function should be in your yank register

### 3. Test Block Pasting

- After yanking a block, move to a different location
- Press `<leader>cp` (or `:CodeBlockPaste`)
- The block should paste with proper indentation for the new location

### 4. Test Block Deletion

- Move cursor inside a block you want to delete
- Press `<leader>cd` (or `:CodeBlockDelete`)
- The entire block should be deleted

## Keybindings (when using test/init.vim)

- `<leader>cy` - Yank current code block
- `<leader>cd` - Delete current code block
- `<leader>cp` - Paste yanked code block
- `<leader>ch` - Manually trigger highlight

## Requirements

**Important**: This plugin requires:
- Neovim 0.9+
- nvim-treesitter plugin installed
- Treesitter parser for the language you're testing (e.g., `:TSInstall lua`)

If Treesitter isn't available, the plugin will silently do nothing.

## Installing nvim-treesitter for testing

If you don't have nvim-treesitter, install it temporarily:

```bash
# Create a test config directory
mkdir -p ~/.config/nvim-test

# Add this to ~/.config/nvim-test/init.lua
cat > ~/.config/nvim-test/init.lua << 'EOF'
vim.opt.rtp:append("/Users/justin/Development/sonntag/nvim-code-blocks")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { "nvim-treesitter/nvim-treesitter", build = ":TSUpdate" },
})

require("nvim-treesitter.configs").setup({
  ensure_installed = { "lua", "python", "javascript" },
  highlight = { enable = true },
})

require("nvim-code-blocks").setup()

-- Keybindings
vim.keymap.set('n', '<leader>cy', function() require('nvim-code-blocks').yank_block() end)
vim.keymap.set('n', '<leader>cd', function() require('nvim-code-blocks').delete_block() end)
vim.keymap.set('n', '<leader>cp', function() require('nvim-code-blocks').paste_block() end)
EOF

# Run nvim with test config
NVIM_APPNAME=nvim-test nvim test/test.lua
```

## Troubleshooting

### "No code block found at cursor"
- Make sure nvim-treesitter is installed
- Install the parser: `:TSInstall lua`
- Check if Treesitter is working: `:InspectTree`

### No highlighting visible
- Check highlight group: `:hi CodeBlock`
- Try setting a more visible color in setup:
  ```lua
  require("nvim-code-blocks").setup({
    highlight = {
      hl_group = "Visual",  -- Use Visual highlight for testing
    }
  })
  ```

### Plugin not loading
- Verify plugin is in runtimepath: `:set rtp?`
- Check for errors: `:messages`

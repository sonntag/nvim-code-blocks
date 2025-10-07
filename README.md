# nvim-code-blocks

A Neovim plugin for code block operations including highlighting, yanking, deleting, and pasting.

## Features

- **Highlight**: Visually highlight code blocks in your files
- **Yank**: Copy entire code blocks with a single command
- **Delete**: Remove code blocks efficiently
- **Paste**: Insert previously yanked code blocks

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  "yourusername/nvim-code-blocks",
  config = function()
    require("nvim-code-blocks").setup({
      -- Configuration options
      highlight = {
        enabled = true,
        hl_group = "CodeBlock",
      },
    })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  "yourusername/nvim-code-blocks",
  config = function()
    require("nvim-code-blocks").setup()
  end,
}
```

## Usage

### Commands

- `:CodeBlockYank` - Yank the current code block
- `:CodeBlockDelete` - Delete the current code block
- `:CodeBlockPaste` - Paste a previously yanked code block
- `:CodeBlockHighlight` - Highlight the current code block

### Configuration

```lua
require("nvim-code-blocks").setup({
  highlight = {
    enabled = true,
    hl_group = "CodeBlock",
  },
})
```

## Development

This project uses [devenv](https://devenv.sh/) for development environment management.

### Setup

1. Install [Nix](https://nixos.org/download) and [devenv](https://devenv.sh/getting-started/)
2. Clone this repository
3. Enter the development environment:
   ```bash
   devenv shell
   ```

### Development Tools

- **Lua LSP**: lua-language-server for code intelligence
- **Formatting**: stylua for code formatting
- **Git Hooks**: Pre-commit hooks for code quality

## Contributing

Contributions are welcome! See [spec/ideas.md](spec/ideas.md) for planned features and ideas.

## License

MIT

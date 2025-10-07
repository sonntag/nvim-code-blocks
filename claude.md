# Claude Code Context

This document provides context for Claude Code when working on the nvim-code-blocks project.

## Project Overview

**nvim-code-blocks** is a Neovim plugin written in Lua that provides operations for code blocks:
- Highlighting code blocks
- Yanking (copying) code blocks
- Deleting code blocks
- Pasting code blocks

## Project Structure

```
nvim-code-blocks/
├── lua/
│   └── nvim-code-blocks/
│       └── init.lua          # Main plugin module
├── plugin/
│   └── nvim-code-blocks.lua  # Plugin entry point and commands
├── spec/
│   └── ideas.md              # Feature ideas and specifications
├── devenv.nix                # Development environment config
├── devenv.yaml               # Devenv inputs configuration
└── README.md                 # Project documentation
```

## Key Files

### lua/nvim-code-blocks/init.lua
Main plugin module containing:
- Configuration defaults
- Setup function
- Core functions: `yank_block()`, `delete_block()`, `paste_block()`, `highlight_block()`
- Currently contains TODOs for implementation

### plugin/nvim-code-blocks.lua
Plugin initialization file that:
- Prevents duplicate loading
- Creates user commands (`:CodeBlockYank`, `:CodeBlockDelete`, etc.)
- Maps commands to main module functions

## Development Environment

Uses devenv with:
- Lua language support enabled
- lua-language-server for LSP
- stylua for formatting
- Git hooks for code quality

Enter development environment with:
```bash
devenv shell
```

## Current Status

The plugin has a basic template structure with:
- ✅ Project structure in place
- ✅ User commands defined
- ✅ Configuration system set up
- ⏳ Core functionality not yet implemented (TODOs in init.lua)

## Implementation Notes

### Code Block Detection
Need to define what constitutes a "code block":
- Language-specific blocks (functions, classes, etc.)
- Markdown fenced code blocks
- Custom delimiters
- Treesitter integration for AST-based detection?

### Highlight Implementation
Consider using:
- `vim.api.nvim_buf_add_highlight()` for basic highlighting
- Extmarks for more sophisticated highlighting with virtual text
- Custom highlight groups for user customization

### Yank/Delete/Paste Operations
Need to:
- Detect block boundaries
- Use Neovim registers for yanking
- Handle indentation and formatting
- Support system clipboard integration

## Testing

No test framework currently set up. Consider:
- plenary.nvim for testing framework
- busted for unit tests
- Manual testing in Neovim

## Next Steps

See `spec/ideas.md` for detailed feature ideas and design decisions to be made.

Priority items:
1. Define code block detection strategy
2. Implement basic highlighting
3. Implement yank/delete/paste operations
4. Add keybindings
5. Write tests

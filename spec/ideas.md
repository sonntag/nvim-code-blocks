# nvim-code-blocks: Ideas and Specifications

## Overview

nvim-code-blocks solves a visual context problem when working in highly structured languages like Clojure and other Lisps. Traditional single-line cursor highlighting is insufficient for understanding which scope or code block you're currently editing.

**Implementation**: Uses Treesitter for language-aware block detection, enabling support across any language with a Treesitter grammar.

### The Problem
When working with nested code structures, it's difficult to quickly identify which function, form, or scope contains the cursor position. Standard cursorline highlighting only shows one line, making it hard to see the boundaries of the current code block.

### The Solution
nvim-code-blocks provides a **rectangular background highlight** for the entire code block containing the cursor. This highlight:

- **Respects indentation**: Starts at the leftmost column where code begins in the block (not column 0 if indented)
- **Shows full width**: Extends to the rightmost character across all lines in the block (even past shorter lines)
- **Fills empty lines**: Background highlight appears on blank lines within the block
- **Updates dynamically**: Follows cursor movement to always highlight the current block

#### Visual Example
```
                    ┌─ Highlight starts at indentation level
                    ↓
    function foo()
    ·················let x = 1············  ← Highlight extends to max width
    ·················if (condition) {·····
    ·················                      ← Empty line still highlighted
    ·················  return x···········
    ·················}·····················
    end··········································  ← Highlight ends here
```

### Second Problem: Smart Block Yanking

Traditional block yanking (like `yab`) has an indentation problem. When you yank a block, Vim includes all leading whitespace on every line except the first. This causes issues when pasting at a different indentation level—the internal structure gets misaligned.

#### The Problem
```clojure
;; Original code at 4-space indent
    (defn foo []
      (let [x 1]
        (if condition
          x)
        ))
```

When yanked with `yab`, the text includes:
```
(defn foo []
      (let [x 1]      ← 6 spaces of leading whitespace included
        (if condition  ← 8 spaces of leading whitespace included
          x)           ← 10 spaces of leading whitespace included
        ))
```

When pasted at 2-space indent:
```clojure
;; Broken indentation due to absolute leading whitespace
  (defn foo []
      (let [x 1]      ← Wrong! Should be 4 spaces from defn (2 base + 2 relative)
        (if condition  ← Wrong! Should be 6 spaces (2 base + 4 relative)
          x)           ← Wrong! Should be 8 spaces (2 base + 6 relative)
        ))
```

#### The Solution
nvim-code-blocks normalizes leading whitespace to be relative to the block's leftmost column. When you yank a block, it captures exactly what's highlighted—trimming the common leading whitespace. Pasting then applies the new base indentation while preserving the internal relative structure.

What you see highlighted is exactly what gets yanked and pasted.

## Core Features

### Code Block Detection
- **Treesitter-based**: Uses Treesitter AST nodes to detect code blocks
- Language-agnostic: Works with any language that has a Treesitter grammar
- Configurable node types: Define which syntax nodes count as "blocks" per language
- Fallback support: For languages without Treesitter, support text objects or custom patterns

### Highlighting
- Visual feedback for detected code blocks
- Customizable highlight groups
- Real-time vs on-demand highlighting

### Yanking (Copying)
- Yank entire code block with single command
- Automatically normalize leading whitespace
- Register selection
- Integration with system clipboard

### Deleting
- Delete code block and adjust surrounding content
- Preserve formatting and indentation
- Undo/redo support

### Pasting
- Paste previously yanked code blocks
- Smart indentation matching at paste location
- Multiple paste targets

## Technical Implementation

### Treesitter Integration
- Query Treesitter AST to find containing node for cursor position
- Support configurable node types per filetype (e.g., `function_definition`, `list_lit`, `block`)
- Cache node queries for performance
- Handle languages without Treesitter gracefully

### Dependencies
- Neovim 0.9+ (for Treesitter API)
- nvim-treesitter (optional but recommended)
- Language-specific Treesitter parsers

## Future Ideas
- [ ] Support for nested code blocks (show multiple levels)
- [ ] Multi-block operations
- [ ] Integration with LSP for semantic blocks
- [ ] Custom block definitions beyond Treesitter nodes

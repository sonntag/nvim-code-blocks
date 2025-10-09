{
  config,
  pkgs,
  ...
}: {
  packages = with pkgs; [
    git
    claude-code
    lua-language-server
    stylua
  ];

  languages.lua.enable = true;

  claude.code = {
    enable = true;
    mcpServers = {
      # Local devenv MCP server
      devenv = {
        type = "stdio";
        command = "devenv";
        args = ["mcp"];
        env = {
          DEVENV_ROOT = config.devenv.root;
        };
      };
    };
  };

  scripts.test-plugin.exec = ''
    # If no argument provided, show menu
    if [ $# -eq 0 ]; then
      echo "Select a test file:"
      echo "  1) test.lua (tabs)"
      echo "  2) test-spaces.lua (spaces)"
      echo "  3) test-anonymous.lua (anonymous functions)"
      echo "  4) test.clj (Clojure)"
      echo "  5) test.js (JavaScript)"
      echo "  6) test.py (Python)"
      echo "  7) test.hs (Haskell)"
      read -p "Enter choice [1-7]: " choice

      case $choice in
        1) FILE="test/test.lua" ;;
        2) FILE="test/test-spaces.lua" ;;
        3) FILE="test/test-anonymous.lua" ;;
        4) FILE="test/test.clj" ;;
        5) FILE="test/test.js" ;;
        6) FILE="test/test.py" ;;
        7) FILE="test/test.hs" ;;
        *) echo "Invalid choice"; exit 1 ;;
      esac
    else
      FILE="$1"

      # If argument doesn't start with test/, prepend it
      if [[ "$FILE" != test/* ]]; then
        FILE="test/$FILE"
      fi

      # If no extension, assume .lua
      if [[ "$FILE" != *.* ]]; then
        FILE="$FILE.lua"
      fi
    fi

    nvim -u test/init.vim "$FILE"
  '';

  enterShell = ''
    echo ""
    echo "🚀 nvim-code-blocks development environment"
    echo "📋 Neovim plugin for code block operations"
    echo "   • Lua language support enabled"
    echo "   • lua-language-server for LSP"
    echo "   • stylua for formatting"
    echo ""
    echo "💡 Quick start:"
    echo "   • test-plugin           # Test with test.lua (tabs)"
    echo "   • test-plugin test.clj  # Test with Clojure"
    echo "   • test-plugin test.js   # Test with JavaScript"
    echo "   • test-plugin test.py   # Test with Python"
    echo "   • claude                # AI assistance"
    echo ""
  '';

  git-hooks.hooks = {
    trim-trailing-whitespace.enable = true;
    end-of-file-fixer.enable = true;
  };
}

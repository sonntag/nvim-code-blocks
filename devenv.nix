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

  enterShell = ''
    echo ""
    echo "🚀 nvim-code-blocks development environment"
    echo "📋 Neovim plugin for code block operations"
    echo "   • Lua language support enabled"
    echo "   • lua-language-server for LSP"
    echo "   • stylua for formatting"
    echo ""
    echo "💡 Quick start: Run 'claude' to begin development"
    echo ""
  '';

  git-hooks.hooks = {
    trim-trailing-whitespace.enable = true;
    end-of-file-fixer.enable = true;
  };
}

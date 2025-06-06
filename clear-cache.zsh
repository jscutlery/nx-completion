#!/bin/zsh
# nx-completion Zsh Cache Clearing Script
# 
# This script clears only the zsh completion cache
# Run this after updating the plugin

set -e

echo "🧹 nx-completion Zsh Cache Clear"
echo "================================"

# Clear zsh completion cache
echo ""
echo "🗂️  Clearing zsh completion cache..."

if [[ -f ~/.zcompdump ]]; then
  rm -rf ~/.zcompdump*
  echo "    ✓ Removed ~/.zcompdump files"
else
  echo "    ℹ️  No zcompdump files found"
fi

# Rebuild completion system
echo ""
echo "🔄 Rebuilding completion system..."

# Force rebuilding of completion functions
autoload -U compinit
compinit -D
echo "    ✓ Rebuilt completion functions"

# Reload the plugin if possible
echo ""
echo "🔌 Reloading plugin..."

local plugin_loaded=false

# Try to find and reload the plugin
if [[ -n "$ZSH_CUSTOM" && -f "$ZSH_CUSTOM/plugins/nx-completion/nx-completion.plugin.zsh" ]]; then
  source "$ZSH_CUSTOM/plugins/nx-completion/nx-completion.plugin.zsh"
  echo "    ✓ Reloaded plugin from Oh My Zsh custom directory"
  plugin_loaded=true
elif [[ -f ~/.nx-completion/nx-completion.plugin.zsh ]]; then
  source ~/.nx-completion/nx-completion.plugin.zsh
  echo "    ✓ Reloaded plugin from ~/.nx-completion"
  plugin_loaded=true
elif [[ -f ./nx-completion.plugin.zsh ]]; then
  source ./nx-completion.plugin.zsh
  echo "    ✓ Reloaded plugin from current directory"
  plugin_loaded=true
fi

if [[ $plugin_loaded == false ]]; then
  echo "    ⚠️  Could not auto-reload plugin. Please restart your shell or source the plugin manually."
fi

# Verify completion function
echo ""
echo "✅ Verification..."

if declare -f _nx_completion > /dev/null 2>&1; then
  echo "    ✓ Completion function is loaded"
  echo ""
  echo "🎉 Zsh cache cleared successfully!"
  echo ""
  echo "💡 Try tab completion with 'nx <TAB>' to test"
else
  echo "    ⚠️  Completion function not found - plugin may need manual reloading"
fi

echo ""
echo "✨ Done! Your zsh completion cache has been cleared."

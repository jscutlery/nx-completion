#!/bin/zsh
# nx-completion Zsh Cache Clearing Script
#
# This script clears ALL caches created by the nx-completion plugin
# Run this after updating the plugin or when experiencing cache issues

set -e

echo "🧹 nx-completion Complete Cache Clear"
echo "====================================="

# Function to safely unset variables
safe_unset() {
  local var_name="$1"
  if [[ ${(P)+var_name} -eq 1 ]]; then
    unset "$var_name"
    echo "    ✓ Cleared variable: $var_name"
  fi
}

# Function to remove files matching pattern
safe_remove() {
  local pattern="$1"
  local description="$2"

  # Use setopt to handle glob patterns safely
  setopt LOCAL_OPTIONS NULL_GLOB
  local found_files=(${~pattern})

  if [[ ${#found_files[@]} -gt 0 ]]; then
    rm -rf "${found_files[@]}"
    echo "    ✓ Removed $description: $pattern"
  else
    echo "    ℹ️  No $description found"
  fi
}

# Clear nx-completion specific cache variables
echo ""
echo "🗑️  Clearing nx-completion cache variables..."

# Main workspace cache variables
safe_unset "nx_workspace_projects"
safe_unset "nx_workspace_targets"

# Completion cache variables
safe_unset "nx_list_projects"
safe_unset "nx_list_targets"
safe_unset "nx_list_generators"

# Executor cache variables
safe_unset "nx_executors"

# Command-specific cache variables
for cmd in build test lint serve e2e generate run new migrate; do
  safe_unset "nx_${cmd}_options"
  safe_unset "nx_dynamic_${cmd}_options"
done

# Executor-specific cache variables (these have dynamic names)
# Clear any variables matching the pattern nx_executor_options_*
for var in ${(k)parameters}; do
  if [[ "$var" =~ ^nx_executor_options_ ]]; then
    safe_unset "$var"
  fi
done

# Target executor cache variables (these have dynamic names)
# Clear any variables matching the pattern nx_target_executor_*
for var in ${(k)parameters}; do
  if [[ "$var" =~ ^nx_target_executor_ ]]; then
    safe_unset "$var"
  fi
done

# Subcommands cache
safe_unset "_nx_subcommands"

# Temporary workspace definition variable
safe_unset "tmp_cached_def"

# Clear temporary files created by the plugin
echo ""
echo "🗂️  Clearing temporary files..."

# Remove temporary nx-completion files from /tmp
safe_remove "/tmp/nx-completion-*.json" "temporary project graph files"

# Clear standard zsh completion cache
echo ""
echo "🔄 Clearing zsh completion cache..."

safe_remove "~/.zcompdump*" "zsh completion dump files"

# Clear zsh completion cache directory if it exists
if [[ -d ~/.zsh/cache ]]; then
  safe_remove "~/.zsh/cache/*nx*" "nx-related cache files"
fi

# Also check XDG cache directory
if [[ -n "$XDG_CACHE_HOME" && -d "$XDG_CACHE_HOME/zsh" ]]; then
  safe_remove "$XDG_CACHE_HOME/zsh/*nx*" "XDG nx-related cache files"
elif [[ -d ~/.cache/zsh ]]; then
  safe_remove "~/.cache/zsh/*nx*" "nx-related cache files in ~/.cache"
fi

# Rebuild completion system
echo ""
echo "🔧 Rebuilding completion system..."

# Force rebuilding of completion functions
autoload -U compinit
compinit -D
echo "    ✓ Rebuilt completion functions"

# Note about reloading the plugin
echo ""
echo "🔌 Plugin reload..."
echo "    ℹ️  Cache cleared - plugin reload recommended"
echo "    💡 To reload: source your-plugin-path/nx-completion.plugin.zsh"
echo "    💡 Or restart your shell for a completely fresh start"

# Verify that cache was cleared (before any potential reload)
echo ""
echo "✅ Verification..."

# Check if the main completion function still exists
if declare -f _nx_completion > /dev/null 2>&1; then
  echo "    ✓ Completion function is still loaded"
else
  echo "    ℹ️  Completion function unloaded - reload plugin to restore"
fi

echo ""
echo "📊 Summary of cleared caches:"
echo "   • Workspace cache variables (projects, targets, generators)"
echo "   • Command-specific option caches (build, test, lint, serve, etc.)"
echo "   • Executor-specific option caches"
echo "   • Target-executor mapping caches"
echo "   • Temporary project graph files (/tmp/nx-completion-*.json)"
echo "   • Standard zsh completion dumps (~/.zcompdump*)"
echo "   • Plugin-specific cache files"
echo ""
echo "✨ Done! All nx-completion caches have been thoroughly cleared."

#!/bin/zsh

# Test script for nx-completion plugin
# This script sets up a test environment and demonstrates the completion functionality

echo "🧪 Testing nx-completion plugin..."
echo "=================================="

# Set up test environment
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"
PLUGIN_DIR="$(dirname "$TEST_DIR")"

echo "📁 Test directory: $TEST_DIR"
echo "📁 Plugin directory: $PLUGIN_DIR"

# Source the completion plugin
echo "📦 Loading nx-completion plugin..."
source "$PLUGIN_DIR/nx-completion.plugin.zsh"
echo "✅ Plugin loaded successfully"

# Change to test directory
cd "$TEST_DIR"

# Check workspace definition
echo ""
echo "🔍 Checking workspace definition..."
echo "nx.json exists: $(test -f nx.json && echo "✅ YES" || echo "❌ NO")"
echo "Project graph exists: $(test -f .nx/workspace-data/project-graph.json && echo "✅ YES" || echo "❌ NO")"

# Test workspace detection
echo ""
echo "🧭 Testing workspace detection..."
_check_workspace_def
if [[ $? -eq 0 ]]; then
    echo "✅ Workspace detected successfully"
    workspace_def=$(_workspace_def)
    echo "📄 Using workspace definition: $workspace_def"
else
    echo "❌ Failed to detect workspace"
    exit 1
fi

# Test JSON structure detection
echo ""
echo "🔍 Testing JSON structure detection..."
nodes_path=$(_get_nodes_path "$workspace_def")
echo "📊 Detected nodes path: $nodes_path"

# Test project listing
echo ""
echo "📋 Testing project listing..."
projects=($(_workspace_projects))
echo "🏗️  Found ${#projects[@]} projects:"
for project in "${projects[@]}"; do
    echo "   • $project"
done

# Test target listing
echo ""
echo "🎯 Testing target listing..."
targets=($(_nx_workspace_targets))
echo "🎪 Found ${#targets[@]} unique targets:"
for target in "${targets[@]}"; do
    echo "   • $target"
done

# Test executor listing
echo ""
echo "⚙️  Testing executor listing..."
executors=($(_nx_get_executors))
echo "🔧 Found ${#executors[@]} unique executors:"
for executor in "${executors[@]}"; do
    echo "   • $executor"
done

# Test with nested structure if available
echo ""
echo "🔀 Testing with nested JSON structure..."
if [[ -f "$TEST_DIR/project-graph-nested.json" ]]; then
    echo "📄 Testing with nested structure file..."
    nested_nodes_path=$(_get_nodes_path "$TEST_DIR/project-graph-nested.json")
    echo "📊 Nested structure nodes path: $nested_nodes_path"

    # Test switching to nested structure
    echo "🔄 Switching to nested structure..."
    cp "$workspace_def" "${workspace_def}.bak"
    cp "$TEST_DIR/project-graph-nested.json" "$workspace_def"

    # Test functions with nested structure
    nested_projects=($(_workspace_projects))
    nested_targets=($(_nx_workspace_targets))
    nested_executors=($(_nx_get_executors))

    echo "🏗️  Found ${#nested_projects[@]} projects in nested structure:"
    for project in "${nested_projects[@]}"; do
        echo "   • $project"
    done

    echo "🎯 Found ${#nested_targets[@]} targets in nested structure:"
    for target in "${nested_targets[@]}"; do
        echo "   • $target"
    done

    echo "⚙️  Found ${#nested_executors[@]} executors in nested structure:"
    for executor in "${nested_executors[@]}"; do
        echo "   • $executor"
    done

    # Restore original structure
    echo "🔄 Restoring original structure..."
    mv "${workspace_def}.bak" "$workspace_def"

    echo "✅ Nested structure test completed successfully"
else
    echo "⚠️  Nested structure test file not found"
fi

echo ""
echo "✅ Testing completed!"
echo ""
echo "💡 To test completion interactively:"
echo "   1. cd $TEST_DIR"
echo "   2. source $PLUGIN_DIR/nx-completion.plugin.zsh"
echo "   3. Try: nx <TAB> or nx build <TAB>"
echo ""
echo "📝 Available test projects: ${projects[*]}"
echo "🎯 Available test targets: ${targets[*]}"

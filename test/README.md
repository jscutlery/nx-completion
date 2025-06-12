# Test Environment for nx-completion

This directory contains a simplified test environment for testing the nx-completion Zsh plugin functionality.

## Structure

```
test/
├── .nx/
│   └── workspace-data/
│       └── project-graph.json      # Main test project graph (uses .nodes structure)
├── nx.json                         # Nx workspace configuration
├── project-graph-nested.json       # Alternative test file (uses .graph.nodes structure)
├── test-completion.zsh             # Functional test script
├── test-cache.zsh                  # Cache performance test script
└── README.md                       # This file
```

## Test Projects

The simplified project graph includes:

### Applications
- **frontend-app**: Web application with build, serve, test, lint, e2e targets
- **backend-api**: Node.js API with build, serve, test, lint targets

### Libraries
- **shared-utils**: Utility library with build, test, lint targets
- **ui-components**: UI component library with build, test, lint, storybook targets
- **data-access**: Data access library with build, test, lint targets

### Executors Used
- `@nx/webpack:webpack` - For frontend builds
- `@nx/webpack:dev-server` - For frontend development server
- `@nx/node:build` - For backend builds
- `@nx/node:node` - For backend development server
- `@nx/jest:jest` - For testing
- `@nx/eslint:lint` - For linting
- `@nx/cypress:cypress` - For e2e testing
- `@nx/js:tsc` - For TypeScript library builds
- `@nx/rollup:rollup` - For library bundling
- `@storybook/angular:start-storybook` - For Storybook development
- `@storybook/angular:build-storybook` - For Storybook builds

## How to Test

### Functional Testing
Run the automated functional test script:
```bash
cd test
./test-completion.zsh
```

This will test:
- Workspace detection
- JSON structure detection
- Project listing
- Target listing
- Executor listing
- Both `.nodes` and `.graph.nodes` JSON structures

### Cache Performance Testing
Run the cache performance test script:
```bash
cd test
./test-cache.zsh
```

This comprehensive test will verify:
- Cache variable creation and validation
- Performance improvements from caching
- Cache invalidation functionality
- All caching functions in the plugin
- Code verification (confirms caching code is present)

### Interactive Testing
For manual completion testing:

1. **Navigate to test directory:**
   ```bash
   cd test
   ```

2. **Source the completion plugin:**
   ```bash
   source ../nx-completion.plugin.zsh
   ```

3. **Test completions:**
   ```bash
   # Test command completion
   nx <TAB>

   # Test project completion
   nx build <TAB>

   # Test target completion
   nx run <TAB>

   # Test specific commands
   nx serve <TAB>
   nx test <TAB>
   nx lint <TAB>
   ```

### Testing Different JSON Structures

The test environment includes two project graph files:

1. **`.nx/workspace-data/project-graph.json`** - Uses current `.nodes` structure
2. **`project-graph-nested.json`** - Uses alternative `.graph.nodes` structure

To test the nested structure manually:
```bash
# Backup current graph
mv .nx/workspace-data/project-graph.json .nx/workspace-data/project-graph.json.bak

# Use nested structure
cp project-graph-nested.json .nx/workspace-data/project-graph.json

# Test completion (should work the same)
nx <TAB>

# Restore original
mv .nx/workspace-data/project-graph.json.bak .nx/workspace-data/project-graph.json
```

## Expected Behavior

The completion should work identically regardless of which JSON structure is used:

- **Projects**: `frontend-app`, `backend-api`, `shared-utils`, `ui-components`, `data-access`
- **Targets**: `build`, `serve`, `test`, `lint`, `e2e`, `storybook`, `build-storybook`
- **Target combinations**: `frontend-app:build`, `backend-api:serve`, etc.

## Benefits of This Test Environment

1. **Lightweight**: Only 5 projects vs 922+ in the real workspace
2. **Fast**: Quick loading and testing
3. **Comprehensive**: Covers all major Nx patterns and executors
4. **Dual Format**: Tests both JSON structure formats
5. **Isolated**: Doesn't interfere with your main workspace
6. **Realistic**: Uses real-world Nx patterns and configurations
